---
title: "Tips - Get availability zones for an Azure region"
images:
  - "https://images.seifbassem.com/images/Posts/Get-zones-for-region/banner.png"
date: 2024-03-19 17:08:42 +0200
tags: ["Azure","Reliability","Tips","INFRASTRUCTURE-AS-CODE","Bicep"]
categories: ["posts"]
draft: false
---

<!--more-->

Recently I was working on a Bicep project and I needed to find if a given Azure region supports availability zones or not and if it does, then what are the zones available in that region to ensure that the deployed resources are deployed in a reliable manner. Currently, the only way to find this information is using the ARM API through the `checkZonePeers` endpoint. In this blog post, I will go through how you can call it using PowerShell to get this information and also how to use this endpoint in your Bicep code to get the zones dynamically.

> **NOTE: I recently found a Bicep function that can find the zones supported by a resource in a specific region. Its called [pickZones](https://learn.microsoft.com/azure/azure-resource-manager/bicep/bicep-functions-resource#pickzones)**

![Screenshot showing the availability zones diagram for a specif azure region](https://images.seifbassem.com/images/Posts/Get-zones-for-region/01.png)

## Pre-requisites

The only pre-requisite to call this endpoint is to have the *AvailabilityZonePeering* feature registered on all the subscriptions you will call it against.

```powerShell
$subscriptionId = "<Subscription Id>"
$apiEndpoint = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Resources/checkZonePeers/?api-version=2022-12-01"

# Register AvailabilityZonePeering feature if not registered
$featureStatus = (Get-AzProviderFeature -ProviderNamespace "Microsoft.Resources" -FeatureName "AvailabilityZonePeering").RegistrationState

if ($featureStatus -ne "Registered") {
    Write-Host "Registering AvailabilityZonePeering feature"
    Register-AzProviderFeature -FeatureName "AvailabilityZonePeering" -ProviderNamespace "Microsoft.Resources"
    do {
        $featureStatus = (Get-AzProviderFeature -ProviderNamespace "Microsoft.Resources" -FeatureName "AvailabilityZonePeering").RegistrationState
        Write-Host "Waiting for AvailabilityZonePeering feature to be registered....waiting 35 seconds"
        Start-Sleep -Seconds 35
    } until (
        $featureStatus -eq "Registered"
    )
}
Write-Host "AvailabilityZonePeering feature is Successfully registered."
```

## Getting the availability zones information

To call this endpoint using PowerShell, we need first to select the region we want to get this information for and get a bearer token for authentication.

> **NOTE: To call the endpoint, you need to have the necessary RBAC permissions on the subscriptions to submit a `POST` request**

```powerShell
# Check if the location supports Availability Zones
$location = "<Azure region>"

# Get access token for authentication
$accessToken = (Get-AzAccessToken).Token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

# Generate the API endpoint body containing the Azure region and list of subscription Ids to get the information for
$body = @{
    location        = $Location
    subscriptionIds = @("subscriptions/$subscriptionId")
} | ConvertTo-Json

# Calling the API endpoint and getting the supported availability zones
try {
    $response = Invoke-RestMethod -Method Post -Uri $apiEndpoint -Body $body -Headers $headers
    $zones = $response.AvailabilityZonePeers.AvailabilityZone
    Write-Host "The region '$Location' supports availability zones: $zones"
} catch {
    Write-Host "The region '$Location' doesn't support availability zones!"
}
```

![Screenshot showing the availability zones supported for the eastus region](https://images.seifbassem.com/images/Posts/Get-zones-for-region/02.png)

## Using this endpoint in Bicep

I can use this PowerShell code as well in my Bicep code as a module to dynamically get the zones information depending on the region I'm deploying to. We can use deployment scripts to call this PowerShell script.

- I will use the same PowerShell code from above as a ps1 script but will add the availability zones as an outputs so I can use them in my Bicep code.

```powershell
param(
    [string]$subscriptionId,
    [string]$location
)

$apiEndpoint = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Resources/checkZonePeers/?api-version=2022-12-01"
$availabilityZones = @()
# Check if the location supports Availability Zones
$accessToken = (Get-AzAccessToken).Token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

$body = @{
    location        = $Location
    subscriptionIds = @("subscriptions/$subscriptionId")
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Method Post -Uri $apiEndpoint -Body $body -Headers $headers
    $zones = $response.AvailabilityZonePeers.AvailabilityZone
    Write-Host "The region '$Location' supports availability zones: $zones"
    $availabilityZones+=$zones
}
catch {
    Write-Host "The region '$Location' doesn't support availability zones!"
}

$DeploymentScriptOutputs["availabilityZones"] = $availabilityZones
```

- In Bicep, I will create a deployment script that runs this code and pass the Azure region and subscription Id(s) as arguments.

```python
module getAvailabilityZones 'br/public:avm/res/resources/deployment-script:0.1.3' = {
  scope: resourceGroup()
  name: '${uniqueString(deployment().name, resourceLocation)}-ds'
  params: {
    name: deploymentScriptName
    location: resourceLocation
    azPowerShellVersion: '9.7'
    kind: 'AzurePowerShell'
    retentionInterval: 'P1D'
    arguments: '-location ${resourceLocation} -subscriptionId ${subscription().subscriptionId}'
    scriptContent: loadTextContent('./scripts/get-availabilityZone.ps1')
    managedIdentities: {
      userAssignedResourcesIds: [
        createManagedIdentityForDeploymentScript.outputs.resourceId
      ]
    }
  }
}

output availabilityZones array = getAvailabilityZones.outputs.outputs.availabilityZones
```

- And now in my `main.bicep`, I can pass the region to the deployment script and dynamically get the supported availability zones and dynamically use it to create resources.

```python
param location string = resourceGroup().location
param publicIpName string = uniqueString(resourceGroup().id, '-ip')

module getAvailabilityZones 'modules/availabilityZones/main.bicep' = {
  name: 'getAvailabilityZones'
  params: {
    resourceLocation: location
  }
}

module publicIP 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  name: 'publicIP'
  params: {
    name:publicIpName
    location: location
    zones: getAvailabilityZones.outputs.availabilityZones
  }
}

output zones array = getAvailabilityZones.outputs.availabilityZones

```
