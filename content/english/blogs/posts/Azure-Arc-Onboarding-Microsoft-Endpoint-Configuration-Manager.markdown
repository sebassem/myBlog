---
title: "Azure Arc Onboarding using Endpoint Configuration Manager"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/banner.png"
date: 2021-11-27 17:08:42 +0200
tags: ["Azure","Azure Arc","Microsoft Endpoint Manager"]
categories: ["posts"]
draft: false
---

<!--more-->

Azure Arc-enabled servers allows you to project your hybrid servers (on-premises or any cloud provider) to the Azure control plane where you can start managing them as any other Azure server. You can start using native Azure capabilities like Microsoft Defender for Cloud, tagging, automation, policy, monitoring and more. For a quick recap on what Azure Arc provides, you can explore my [previous article](https://www.seifbassem.com/blogs/unboxing/introducing-azure-arc/).

## Azure Arc Onboarding using Microsoft Endpoint Configuration Manager
Most organizations rely on Microsoft Endpoint Configuration Manager to manage their Windows servers; to deploy applications, updates and do various tasks. In this post, I will go through a couple of methods you can use Configuration Manager to onboard your servers to Azure Arc.

The onboarding process to Azure Arc mainly consists of two steps:

1. Installing the Azure Connected Machine agent
2. Connecting to Azure Arc to onboard the server

![Onboarding steps](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/21.jpg)

We can automate those steps using Configuration Manager by either using the **Run Script** feature or simply installing the agent as a normal application deployment and then running the connect command using PowerShell.

### Onboarding to Azure Arc using "Run Script"
This would be the easiest method to onboard as the script takes care of downloading the installing the agent. This of course requires that all servers have internet connectivity to download the agent.

First thing we need to do, is make sure in "Client settings" that the PowerShell execution policy is going to allow the script execution.

![PowerShell execution policy](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/1.jpg)

Also, since we will be creating the script, we need to make sure to uncheck the checkbox "Script author requires another approver"

![Script approver checkbox](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/8.jpg)

Go through the onboarding wizard in the Azure portal to specify the needed parameters; resource group, location, service principal, tags,....etc

![Azure Arc wizard1](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/2.jpg)

![Azure Arc wizard2](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/3.jpg)

![Azure Arc wizard3](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/4.jpg)

![Azure Arc wizard4](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/5.jpg)

![Azure Arc wizard5](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/6.jpg)

Then, we create the script using the onboarding information generated from the Azure portal and approve it.

![Create script in MEMC](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/7.jpg)

![Create script in MEMC](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/9.jpg)

Select the collection containing the servers to onboard and select "Run script"

![Run script in MEMC](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/10.jpg)

After a couple of seconds, we can see that the script has finished executing and we have a return code of 0 🥳

![Script execution result](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/11.jpg)

Navigating to the Azure Arc center, we can see that our new server has been onboarded successfully and already connected.

![Server onboarded using Script](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/12.jpg)

### Onboarding to Azure Arc using a custom Task sequence
The second method is using a normal application deployment in Configuration Manager to install the agent. We would still need to run the connect command to onboard the servers to Azure Arc, so we can create a custom task sequence to help us create this flow.

First, let's create an msi application to install the Azure Connected Machine agent.

![Installing Azure Arc agent](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/13.jpg)

Then, we go ahead and create a custom task sequence with the first step to be installing the application we created.

![Custom task sequence application install](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/14.jpg)

We need to add another step to run a PowerShell script which will execute the connect command to onboard our servers to Azure Arc (We can get this command from the Azure portal onboarding wizard).

![Run connect command in task sequence](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/15.jpg)

![Run connect command script](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/22.jpg)

After deploying the Task sequence to the required Collection, we can see the the servers picked up the Task sequence deployment in Software Center.

![Task sequence in software center1](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/16.jpg)

![Task sequence in software center2](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/17.jpg)

![Task sequence in software center3](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/18.jpg)

![Task sequence in software center4](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/19.jpg)

Navigating back to the Azure portal, we can see the second server has been onboarded successfully.

![Second server connected](https://images.seifbassem.com/images/Posts/Azure-Arc-MECM/20.jpg)

> You can add more logic to handle more complex situations like: detect if the server is an Azure VM, the Windows version is one of the [supported ones](https://docs.microsoft.com/azure/azure-arc/servers/agent-overview#supported-operating-systems), or NET Framework 4.6 or later is installed (and install it as needed using [dependencies](https://docs.microsoft.com/mem/configmgr/apps/deploy-use/create-applications#bkmk_dt-depend))



