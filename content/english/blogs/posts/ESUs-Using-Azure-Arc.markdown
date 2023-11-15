---
title: "Extended Security Updates via Azure Arc - Everything you need to know"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/banner.png"
date: 2023-10-01 17:08:42 +0200
tags: ["Azure","Azure Arc"]
categories: ["posts"]
draft: false
---

<!--more-->

As of October 10th, Windows Server 2012 will no longer be supported by Microsoft. This means that organizations still using this operating system will no longer receive security updates, leaving their systems vulnerable to potential threats. There are multiple paths to overcome this, purchase yearly extended security updates licenses(ESUs), retiring those workloads, upgrading to a newer supported version, migrating those workloads to the cloud, modernize to PaaS services or more recently leveraging Azure Arc to deploy extended security updates and get monthly billing so you can stop paying for those ESUs once the servers are migrated to the cloud, retired or no longer on 2012.

![Screenshot showing 2012 end of life](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/01.png)

Azure Arc offers more than just extended security updates for Windows Server 2012. It brings a range of powerful capabilities to the table. With Azure Arc, organizations can easily manage, secure and monitor their hybrid infrastructure, including on-premises servers, multi-cloud environments, and edge devices, all from a single control plane with capabilities like _Azure Monitor_, _Defender for Cloud_ , _Change Tracking and Inventory_ , _Azure Update Manager_ , and much more.

<figure class="video_container">
 <iframe width="560" height="315" src="https://youtube.com/embed/c2gm907H8SQ?si=F69yBZajYgTNvm7U" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>

In this post, we will explore everything you need to know to start deploying ESUs using Azure Arc to your 2012 machines.

## Requirements

- You must have Software Assurance through Volume Licensing

![Screenshot showing software assurance](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/02.png)

- onboard your 2012 machines to Azure Arc. There are different ways you can onboard Windows servers like group policy, configuration manager, Windows Admin Center, or any 3rd-party configuration management solution. Most methods are documented [here](https://learn.microsoft.com/azure/azure-arc/servers/deployment-options#onboarding-methods).

>**NOTE: With GPO onboarding, you can leverage _WMI filters_ to have the group policy only applicable to Windows Server 2012/2012R2**
>```python
>select * from Win32_OperatingSystem where (Version like "6.2%" or Version like "6.3%") and (ProductType="2" or ProductType="3")**
>```

![Screenshot showing software assurance](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/03.png)

- Apply tags as you are onboarding, it will come handy later. Start with tags that can help you deploy ESUs, like owner, type, environment, department/site, migration date,...etc.

![Screenshot showing applying tags](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/04.png)

- If the machines are already onboarded to Azure Arc, update the Azure connected machine agent to 1.34 or later to support deploying ESUs. Its recommended to [automate the agent upgrade process](https://learn.microsoft.com/azure/azure-arc/servers/manage-agent?tabs=windows#upgrade-the-agent) using Windows Updates for Windows by [configuring the Windows Update client](https://learn.microsoft.com/azure/azure-arc/servers/manage-agent?tabs=windows#microsoft-update-configuration) on the machine to check for other Microsoft products. You can also of course upgrade manually by re-deploying the [latest msi](https://aka.ms/AzureConnectedMachineAgent) for the agent.

![Screenshot showing agent version to support ESU](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/05.png)

Since the machines are onboarded to Azure Arc, you can leverage the _Azure Resource Graph explorer_ to find the machines with older versions of the agent.

```python
resources
| where type == 'microsoft.hybridcompute/machines'
| extend agentVersion = tostring(properties.agentVersion) , operatingSystem = tostring(properties.osSku)
| where agentVersion !startswith  '1.34.'
| project name,resourceGroup,operatingSystem,agentVersion
```

- If you don't have automation in-place to continuously upgrade the agent, you can leverage the same method you used for onboarding to push the new agent version. The below code snippet is using Configuration manager's run script capability to check the agent version and only upgrade if its less than 1.34. The new agent msi is hosted on a shared folder.

```powershell
try {
    # Add the service principal application ID and secret here
    $servicePrincipalClientId = "<App Id HERE>";
    $servicePrincipalSecret = "<App SECRET HERE>";

    $env:SUBSCRIPTION_ID = "<Subscription Id>";
    $env:RESOURCE_GROUP = "<Resource group name>";
    $env:TENANT_ID = "<Tenant Id>";
    $env:LOCATION = "<Azure region>";

    $uncPath = "\\<server hosting the agent>\<shared folder name>\AzureConnectedMachineAgent.msi"
    $localPath = "C:\Temp\AzureConnectedMachineAgent.msi"
    $agentPath = "C:\Program Files\AzureConnectedMachineAgent"
    $targetVersion = "1.34.02440.1261"

    if (test-path -Path $agentPath) {
        Write-host "Agent is already installed....Checking the agent version"
        $agentVersion = (azcmagent show agentVersion -j | ConvertFrom-Json).agentVersion
        # Split the version string into an array of its components
        $versionComponents = $agentVersion -split '\.'
        # Split the target version into an array of its components
        $targetComponents = $targetVersion -split '\.'
        # Compare each component of the versions
        for ($i = 0; $i -lt $versionComponents.Length; $i++) {
            $versionComponent = [int]$versionComponents[$i]
            $targetComponent = [int]$targetComponents[$i]
            if ($versionComponent -lt $targetComponent) {
                Write-Host "The version '$agentVersion' is less than '$targetVersion'."
                Write-Host "Upgrading the agent"
                New-Item -Path c:\temp -ItemType Directory -Force | Out-Null
                Copy-Item -Path $uncPath -Destination $localPath -Force
                Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$localPath`" /qn" -Wait
                Remove-Item -Path $localPath -Force
                break
            }
            elseif ($versionComponent -gt $targetComponent) {
                Write-Host "The version '$agentVersion' is greater than '$targetVersion'."
                break
            }
        }
        # If all components are equal or the loop completes without a break, the versions are equal
        if ($i -eq $versionComponents.Length) {
            Write-Host "The version '$agentVersion' is equal to '$targetVersion'."
        }
    }
    else {
        Write-Host "Installing the agent"
        New-Item -Path c:\temp -ItemType Directory -Force | Out-Null
        Copy-Item -Path $uncPath -Destination $localPath -Force
        Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$localPath`" /qn" -Wait
        Remove-Item -Path $localPath -Force

        # Run connect command
        & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect --service-principal-id "$servicePrincipalClientId" --service-principal-secret "$servicePrincipalSecret" --resource-group "$env:RESOURCE_GROUP" --tenant-id "$env:TENANT_ID" --location "$env:LOCATION" --subscription-id "$env:SUBSCRIPTION_ID";
    }
}
catch {
    $logBody = @{subscriptionId = "$env:SUBSCRIPTION_ID"; resourceGroup = "$env:RESOURCE_GROUP"; tenantId = "$env:TENANT_ID"; location = "$env:LOCATION"; operation = "onboarding"; messageType = $_.FullyQualifiedErrorId; message = "$_"; };
    Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/log" -Method "PUT" -Body ($logBody | ConvertTo-Json) | out-null;
    Write-Host  -ForegroundColor red $_.Exception;
}
```

## Licensing

- Determine the Windows Server 2012 editions available and number of cores. You can use the following Azure resource graph query or your existing configuration management solution.

```python
resources
| where type == 'microsoft.hybridcompute/machines'
| extend agentVersion = tostring(properties.agentVersion) , operatingSystem = tostring(properties.osSku)
| extend status = tostring(properties.status)
| extend lastConnected = todatetime(properties.lastStatusChange)
| extend cores = properties.detectedProperties.coreCount
| where operatingSystem contains "2012"
| project name,operatingSystem,cores,status,lastConnected,agentVersion
```

There are two editions of Windows Server 2012; _Standard_ can be applied to up to two virtual machines (VMs) and _Data center_ which has no limit to the number of VMs it can be applied to.

>**NOTE: If ESU is enabled at a later time than October 10th, it will charge back to the date of 10th of October regardless of when it was enabled (1-time charge back).**

- If you have already purchased traditional Windows Server 2012 ESUs, you can switch to ESUs enabled by Azure Arc between Year one and Year two.

### Physical core licensing

- Requires a minimum of 16 physical cores per license.
- It makes sense to use this type of licensing for physical servers and Windows Server virtualization hosts that host lots of virtual machines specially if the host is _Data center_ edition where there is no limit on the VMs it can be applied to.

### Virtual core licensing

- Requires a minimum of eight virtual cores per VM.
- It is advisable for VMs running on third-party hosts, 3rd-party cloud providers, or if the Windows Server was licensed on a virtualization basis.
- Usually used with Windows Server _standard_ edition.

![Screenshot showing licensing from the official docs](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/13.png)

>**NOTE: You can find different example scenarios in this [article](https://learn.microsoft.com//azure/azure-arc/servers/license-extended-security-updates#scenario-based-examples-compliant-and-cost-effective-licensing) to help determine what is the best mix of licenses to acquire.**

## Deploy the Extended security updates

- Start creating the needed licenses from the Azure Portal.

![Screenshot showing creating the licenses](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/06.png)

- Link the licenses to the eligible machines. Currently its manual from the portal but soon there can be an Azure Policy to do this at scale.

![Screenshot showing assigning the ESU licenses](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/07.png)

- At the time of this post, there is no Azure Policy to link the license at scale. The only way to do this programmatically is use the ARM API.

```powershell
$location = "<Region where the ESU license is deployed>"
$subscriptionId = "<SubscriptionId for Arc-enabled servers>"
$esuSubscriptionId = "<SubscriptionId for Arc-enabled servers>"
$esuLicenceResourceGroup = "<Resource group where the ESU license is deployed>"
$licenseName = "<Name of the ESU license>"
$arcServersResourceGroup = "<Resource group where the Arc-enabled machines are deployed>"

################################################################
# Uncomment the method you will use to provide the servers list
## 1. Import using CSV
## 2. Manually create an array of servers
## 3. Directly query the Arc-enabled machines
################################################################


###############################################################################
##1. Importing servers list using a CSV file (Column name should be ServerName)
###############################################################################
<#
$serversListFile = "<Path to the CSV file containing the list of servers>"
$servers = Import-Csv $serversListFile -Header "ServerName"
#>

################################################################
## 2. Manually create an array of servers
################################################################
<#
$servers = @(
    "server1",
    "server2"
)
#>

################################################################
## 3. Directly query the Arc-enabled machines
################################################################
<#
Install-Module -Name Az.ConnectedMachine -Force
$servers = Get-AzConnectedMachine -ResourceGroupName $arcServersResourceGroup -SubscriptionId $subscriptionId | Select-Object -ExpandProperty Name
#>

Connect-AzAccount
$licenseId = "/subscriptions/$esuSubscriptionId/resourceGroups/$esuLicenceResourceGroup/providers/Microsoft.HybridCompute/licenses/$licenseName"
$accessToken = (Get-AzAccessToken).Token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

foreach($server in $servers){
    $Url = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$arcServersResourceGroup/providers/Microsoft.HybridCompute/machines/$server/licenseProfiles/default?api-version=2023-06-20-preview "
    $body = @{
        location = $location
        properties = @{
            esuProfile = @{
                assignedLicense = $licenseId
            }
        }
    } | ConvertTo-Json

    Invoke-RestMethod -Method Put -Uri $url -Body $body -Headers $headers
}
```

- You can then use any update management solution to push the updates once available. You have to have critical and security updates classification selected in your patch management solution.

![Screenshot showing SCCM console](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/08.png)

![Screenshot showing Azure Update manager](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/09.png)

- You can use Azure Update manager with no additional cost if the machines are associated with an ESU License (you can use tags to dynamically assign them)

![Screenshot showing Azure Update manager with tags dynamic scope](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/10.png)

- Change tracking, machine configuration are offered at no additional cost as well if ESU is enabled and linked to the Arc-enabled machines.

![Screenshot showing change tracking](https://images.seifbassem.com/images/Posts/Azure-Arc-ESUs/12.png)

- If you have SQL 2012 on the same VM , just [Arc-enable the SQL server](https://learn.microsoft.com/sql/sql-server/azure-arc/connect?view=sql-server-ver16&tabs=windows) by installing the _Azure extension for SQL Server_ and [enable ESU](https://learn.microsoft.com/sql/sql-server/azure-arc/extended-security-updates?view=sql-server-ver16) to get extended security updates for this SQL instance.

* You can apply ESUs to  [some dev/test, DR scenarios](https://learn.microsoft.com/azure/azure-arc/servers/deliver-extended-security-updates#additional-scenarios) at no additional cost via Azure Arc by using predefined tags (first you must have provisioned and activated a WS2012 Arc ESU License intended to be linked to regular Azure Arc-enabled servers running in production environments (i.e., normally billed ESU scenarios)).
