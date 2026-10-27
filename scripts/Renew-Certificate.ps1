<#
.SYNOPSIS
    Azure Automation Runbook to automatically renew the Let's Encrypt certificate
    for images.seifbassem.com via Cloudflare DNS-01, import it to Azure Key Vault,
    and update Azure Front Door.

.DESCRIPTION
    Automates all steps from "Certificate renewal.md":
      1. Authenticates to Azure using the Automation Account's Managed Identity.
      2. Checks the current certificate expiration in Azure Key Vault.
      3. Requests a new RSA 2048 certificate from Let's Encrypt using Posh-ACME
         and the Cloudflare DNS plugin (zero manual DNS intervention).
      4. Imports the generated PFX into Azure Key Vault.
      5. Triggers Azure Front Door (enableHttps) to deploy the updated certificate.

.PARAMETER ForceRenewal
    If true, forces a certificate renewal even if the existing certificate in Key Vault
    is not yet within the renewal window.

.PARAMETER AcmeServerOverride
    Optional override for the ACME directory server (e.g. "LE_STAGE" or "LE_PROD").
#>
param(
    [Parameter(Mandatory = $false)]
    [bool]$ForceRenewal = $false,

    [Parameter(Mandatory = $false)]
    [string]$AcmeServerOverride = ""
)

$ErrorActionPreference = "Stop"

Write-Output "=================================================================="
Write-Output "Starting Automated Certificate Renewal Runbook"
Write-Output "Timestamp (UTC): $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')) UTC"
Write-Output "=================================================================="

# ------------------------------------------------------------------------------
# 1. Load Configuration from Azure Automation Variables
# ------------------------------------------------------------------------------
$SubscriptionId         = Get-AutomationVariable -Name "SubscriptionId"
$ResourceGroup          = Get-AutomationVariable -Name "ResourceGroup"
$KeyVaultName           = Get-AutomationVariable -Name "KeyVaultName"
$KeyVaultResourceGroup  = Get-AutomationVariable -Name "KeyVaultResourceGroup"
$KeyVaultCertName       = Get-AutomationVariable -Name "KeyVaultCertName"
$FrontDoorName          = Get-AutomationVariable -Name "FrontDoorName"
$FrontDoorEndpointName  = Get-AutomationVariable -Name "FrontDoorEndpointName"
$CertDomain             = Get-AutomationVariable -Name "CertDomain"
$AcmeContactEmail       = Get-AutomationVariable -Name "AcmeContactEmail"
$AcmeServer             = Get-AutomationVariable -Name "AcmeServer"
$RenewWithinDays        = [int](Get-AutomationVariable -Name "RenewWithinDays")
$CloudflareApiToken     = Get-AutomationVariable -Name "CloudflareApiToken"

if (-not [string]::IsNullOrWhiteSpace($AcmeServerOverride)) {
    $AcmeServer = $AcmeServerOverride
}

Write-Output "Configuration loaded:"
Write-Output "  Domain                 : $CertDomain"
Write-Output "  ACME Server            : $AcmeServer"
Write-Output "  Resource Group         : $ResourceGroup"
Write-Output "  Key Vault              : $KeyVaultName (RG: $KeyVaultResourceGroup)"
Write-Output "  Key Vault Cert Name    : $KeyVaultCertName"
Write-Output "  Front Door             : $FrontDoorName"
Write-Output "  Front Door Endpoint    : $FrontDoorEndpointName"
Write-Output "  Renew Within Days      : $RenewWithinDays"
Write-Output "  Force Renewal          : $ForceRenewal"

# ------------------------------------------------------------------------------
# 2. Authenticate to Azure with System-Assigned Managed Identity
# ------------------------------------------------------------------------------
Write-Output "`n[Step 1/5] Authenticating to Azure using Managed Identity..."
Connect-AzAccount -Identity | Out-Null
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
Write-Output "Successfully authenticated to subscription $SubscriptionId."

# ------------------------------------------------------------------------------
# 3. Check Existing Certificate Expiration in Key Vault
# ------------------------------------------------------------------------------
Write-Output "`n[Step 2/5] Checking existing certificate '$KeyVaultCertName' in Key Vault '$KeyVaultName'..."
$existingCert = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $KeyVaultCertName -ErrorAction SilentlyContinue

if ($null -ne $existingCert -and $null -ne $existingCert.Expires) {
    $daysRemaining = [math]::Round(($existingCert.Expires.ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalDays, 1)
    Write-Output "Existing certificate expires on $($existingCert.Expires.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')) UTC ($daysRemaining days remaining)."

    if (-not $ForceRenewal -and $daysRemaining -gt $RenewWithinDays) {
        Write-Output "Certificate has $daysRemaining days remaining (threshold is <= $RenewWithinDays days). Skipping renewal."
        return
    }
    Write-Output "Certificate is within the renewal window (or ForceRenewal is enabled). Proceeding with renewal..."
} else {
    Write-Output "No existing certificate '$KeyVaultCertName' found in Key Vault '$KeyVaultName'. Proceeding with initial request..."
}

# ------------------------------------------------------------------------------
# 4. Request New Certificate via Posh-ACME + Cloudflare DNS-01
# ------------------------------------------------------------------------------
$tempPoshAcmeDir = Join-Path ([System.IO.Path]::GetTempPath()) "Posh-ACME-$([Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $tempPoshAcmeDir -Force | Out-Null
$env:POSHACME_HOME = $tempPoshAcmeDir

try {
    Write-Output "`n[Step 3/5] Requesting Let's Encrypt certificate for '$CertDomain' via Cloudflare DNS-01..."
    Import-Module Posh-ACME -Force

    Set-PAServer -DirectoryUrl $AcmeServer
    New-PAAccount -Contact $AcmeContactEmail -AcceptTOS -Force | Out-Null

    # Generate a random PFX password in memory
    $pfxPasswordPlain  = [Guid]::NewGuid().ToString("N") + [Guid]::NewGuid().ToString("N")
    $pfxPasswordSecure = ConvertTo-SecureString -String $pfxPasswordPlain -AsPlainText -Force
    $cfTokenSecure     = ConvertTo-SecureString -String $CloudflareApiToken -AsPlainText -Force

    $pluginArgs = @{
        CFToken = $cfTokenSecure
    }

    $paCert = New-PACertificate `
        -Domain $CertDomain `
        -Plugin Cloudflare `
        -PluginArgs $pluginArgs `
        -CertKeyLength '2048' `
        -PfxPassSecure $pfxPasswordSecure `
        -Force `
        -Verbose

    if (-not $paCert -or -not (Test-Path -Path $paCert.PfxFullChain)) {
        throw "Posh-ACME did not produce a valid PFX file."
    }

    Write-Output "Certificate successfully issued!"
    Write-Output "  Thumbprint : $($paCert.Thumbprint)"
    Write-Output "  NotAfter   : $($paCert.NotAfter)"
    Write-Output "  PFX Path   : $($paCert.PfxFullChain)"

    # --------------------------------------------------------------------------
    # 5. Import PFX to Azure Key Vault
    # --------------------------------------------------------------------------
    Write-Output "`n[Step 4/5] Importing PFX certificate into Azure Key Vault '$KeyVaultName'..."
    $importedCert = Import-AzKeyVaultCertificate `
        -VaultName $KeyVaultName `
        -Name $KeyVaultCertName `
        -FilePath $paCert.PfxFullChain `
        -Password $pfxPasswordSecure

    Write-Output "Successfully imported certificate to Key Vault:"
    Write-Output "  Secret ID  : $($importedCert.SecretId)"
    Write-Output "  Thumbprint : $($importedCert.Thumbprint)"
    Write-Output "  Expires    : $($importedCert.Expires)"

    # --------------------------------------------------------------------------
    # 6. Update Azure Front Door Frontend Endpoint HTTPS Configuration
    # --------------------------------------------------------------------------
    Write-Output "`n[Step 5/5] Updating Azure Front Door '$FrontDoorName' endpoint '$FrontDoorEndpointName'..."
    $vaultResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$KeyVaultResourceGroup/providers/Microsoft.KeyVault/vaults/$KeyVaultName"
    $enableHttpsPath = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Network/frontDoors/$FrontDoorName/frontendEndpoints/$FrontDoorEndpointName/enableHttps?api-version=2020-05-01"

    $enableHttpsBody = @{
        certificateSource = "AzureKeyVault"
        protocolType      = "ServerNameIndication"
        minimumTlsVersion = "1.2"
        keyVaultCertificateSourceParameters = @{
            vault = @{
                id = $vaultResourceId
            }
            secretName = $KeyVaultCertName
        }
    } | ConvertTo-Json -Depth 5

    $response = Invoke-AzRestMethod -Path $enableHttpsPath -Method POST -Payload $enableHttpsBody

    if ($response.StatusCode -notin @(200, 202)) {
        throw "Failed to update Front Door HTTPS configuration. HTTP $($response.StatusCode): $($response.Content)"
    }

    Write-Output "Front Door HTTPS update accepted (HTTP $($response.StatusCode))."
    Write-Output "`n=================================================================="
    Write-Output "Certificate renewal completed successfully!"
    Write-Output "=================================================================="
}
finally {
    if (Test-Path -Path $tempPoshAcmeDir) {
        Remove-Item -Path $tempPoshAcmeDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
