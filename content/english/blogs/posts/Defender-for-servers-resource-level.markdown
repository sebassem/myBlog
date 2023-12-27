---
title: "Manage Defender for servers plans on a machine level!!"
images:
  - "https://images.seifbassem.com/images/Posts/Defender-for-servers-resource-level/banner.png"
date: 2023-12-27 17:08:42 +0200
tags: ["Azure","Defender for cloud","Security"]
categories: ["posts"]
draft: true
---

<!--more-->

You can now manage Defender for servers plans on the resource level (on Azure VMs or Arc-enabled machines) which gives the flexibility of either enabling the plan on a couple of servers or excluding some servers from the subscription level plan.

<figure class="video_container">
 <iframe width="560" height="315" src="https://www.youtube.com/embed/Az4-KjogI10" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>

## Overview

Enabling any Defender for Cloud plan is always recommended to be enabled at the subscription level, this allows for more coverage across new and existing resources. You can do this using the defender portal experience, policy, IaaC and more. Having said that, there has been a need in some scenarios to just enable some servers and not the whole subscription. And also on the contrary, you might have defender enabled on the whole subscription but you need to exclude some machines for some reason.

This is now possible using the Defender for Cloud API for Azure machines and on-premises machines with Azure Arc as part of Defender for Servers plans:

- Defender for Servers Plan 1: you can enable / disable the plan at the resource level.
- Defender for Servers Plan 2: you can only disable the plan at the resource level. For example, it’s possible to enable the plan at the subscription level and disable specific resources, however it’s not possible to enable the plan only for specific resources.

## Turning on the Defender for servers plan

In this demo, I will use the API to enable and disable the plan on an Azure virtual machine. Checking the Defender for servers plan on the subscription and vm level, I can see that its turned off.

![Screenshot showing defender for servers disabled on the azure portal](https://images.seifbassem.com/images/Posts/Defender-for-servers-resource-level/01.png)

![Screenshot showing defender for servers disabled on the virtual machine](https://images.seifbassem.com/images/Posts/Defender-for-servers-resource-level/02.png)

To enable the plan on just the virtual machine, we have to call the *[Update](https://learn.microsoft.com/rest/api/defenderforcloud/pricings/update?view=rest-defenderforcloud-2024-01-01&tabs=HTTP)* api endpoint.

First we define some variables, like the resource group, the virtual machine and the api endpoint.

```powershell
# Define variables
$subscriptionId = "00000000-0000-0000-0000-000000000000"
$resourceGroup = "rg-servers-001"
$vmName= "vm001"
$url = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"
```

We also need to authenticate to the api endpoint.

```powershell
## Set access token for the API request
$accessToken = (Get-AzAccessToken).Token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}
```

Then we prepare the body of our request, including the plan type we will enable. In this case, I will enable *Plan 1*.

```powershell
## Prepare API request body
$body = @{
    location   = $location
    properties = @{
        pricingTier = "Standard"
        subPlan = "P1"
    }
} | ConvertTo-Json
```

Finally, we call the api endpoint using the *PUT* method to enable the plan.

```powershell
## Invoke API request to enable the P1 plan on the VM
Invoke-RestMethod -Method Put -Uri $url -Body $body -Headers $headers
```

Now, navigating the virtual machine to validate.

![Screenshot showing defender for servers enabled on the virtual machine](https://images.seifbassem.com/images/Posts/Defender-for-servers-resource-level/03.png)

And we can see also that the plan is still turned off at the subscription level.

![Screenshot showing defender for servers disabled on the azure portal](https://images.seifbassem.com/images/Posts/Defender-for-servers-resource-level/01.png)

## Turning off the Defender for servers plan

To turn off or exclude a server, you need to call the same endpoint but using the *DELETE* method instead of *PUT* without passing anything to the body of the request.ss

```powershell
## Invoke API request to enable the P1 plan on the VM
Invoke-RestMethod -Method Delete -Uri $url -Headers $headers
```

Final code, should like like this:

```powershell
## Define variables
$subscriptionId = "<subscription Id>"
$resourceGroup = "<resource group name>"
$vmName= "<virtual machine name>"
$url = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"

## Set access token for the API request
$accessToken = (Get-AzAccessToken).Token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

## Prepare API request body
$body = @{
    location   = $location
    properties = @{
        pricingTier = "Standard"
        subPlan = "P1"
    }
} | ConvertTo-Json

## Invoke API request to enable the P1 plan on the VM
Invoke-RestMethod -Method Put -Uri $url -Body $body -Headers $headers

## Invoke API request to disable the P1 plan on the VM
Invoke-RestMethod -Method Delete -Uri $url -Headers $headers
```

