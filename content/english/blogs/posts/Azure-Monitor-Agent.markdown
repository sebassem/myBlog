---
title: "The ultimate guide to the new Azure Monitor Agent"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/banner.png"
date: 2021-08-30 17:08:42 +0200
tags: ["Azure","Azure Monitor"]
categories: ["posts"]
draft: false
---

<!--more-->

When looking at monitoring virtual machines using Azure Monitor , you have to look at your monitoring needs which vary by operating system , metrics , logs , insights ,  custom logs , solutions on log analytics , and much more . All of those decisions will most probably require you to deploy more than one agent on your machines to be able to have this kind of visibility , which is streamlined to some extent by Azure in-terms of deployment and management but it's still too much agents on the virtual machines and you would face some tradeoffs in-terms of centralized vs. decentralized data collection configuration. If we look on the logs level , you have the log collection configuration centralized on the log analytics level so any virtual machine reporting to this workspace will send this type of logs , there was no granular way to specify different configuration for different machines.

### Current Agents
- Log analytics agent
- Azure diagnostics extension
- Dependency agent
- Telegraph agent (linux only)

For a detailed comparison of all agents , check this [link](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/agents-overview#summary-of-agents)

## The Azure Monitor Agent
It was recently announced that now we have one agent which is planned to replace all the previous ones and a new concept call **"Data Collection Rules(DCR)"** which promises to provide very interesting capabilities like : multi-homing ,abstraction of data collection configuration from the log analytics workspace ,different authentication model ,windows event filtering and more.

⚠️ *This new agent is currently not on 100% parity with the other agents , more capabilities are added every month . Keep an eye on this [article](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-overview?tabs=PowerShellWindows#supported-services-and-features) for frequent updates and [current limitations](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-overview?tabs=PowerShellWindows#current-limitations)*

The new DCR concept is all about ,creating different DCRs based on your requirements and assigning them to different machines which is very useful into defining more granular monitoring requirements based on the operating system and data collection requirements . Once you define your DCRs , you would create an association with the VMs and that's it.

![alt](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/media/data-collection-rule-azure-monitor-agent/associations.png
)

The new agent also has a new authentication model , previously when using log analytics , you would have to provide a workspace key and ID to the agent installation. This is now changed to using a system-assigned managed identity on the virtual machine which further simplifies the installation process and saves us from the operation hassle of managing the keys in scenarios of key rotation for example.

## Azure Monitor Agent installtion
The agent is installed as a VM extension ,and there are multiple ways to install it (Portal,CLI,Powershell,ARM,Policy,..etc) , in this post i will cover the portal and policy deployments:
### 1.Portal deployment
This is the most straightforward method to install and enable the new agent and DCR as it automatically enables the managed identity on the VM ,installs the extension, creates and configures the DCR and the DCR association.

Let's take an already existing VM that has all the other agents deployed and see the full experience.

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/1.JPG)

We don't have managed identity enabled on this VM

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/5.JPG)

First ,we go to Azure Monitor and select the new Data Collection rules pane

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/6.jpg)

Let's create a new one .While we have to select a resource group for the DCR ,the virtual machines can reside in any other resource group . The only thing to note here is if you are going to send data to log analytics , you must have the DCR in the same region where the log analytics workspace is located. You can either choose windows or linux but you can also use custom if you want to have one DCR for both.

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/7.jpg)

Next comes the interesting part , first we need to select the resources that will be associated with this DCR. Note that if you select a subscription or resource group scope ,only resource available at that time will be added ; newer VMs created later under this scope won't get the association automatically (will have to use Azure policy for that)

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/8.jpg)

Then we need to select our data sources ; what do we want to collect from those VMs?. I will select performance counters first and we can see that we can use the basic counters or go more granular

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/9.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/10.jpg)

Then we need to select where we want to send those counters/Metrics ; there is the default metrics destination and i can also select a log analytics workspace (in the same region as the DCR) or multiple ones if it makes sense for me.

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/11.jpg)

Next ,i will add another source . In this case ,i will select some windows event logs and will configure multi-homing to send them to my existing workspace and an empty newly created one.

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/12.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/13.jpg)

We can also filter out event logs to limit data ingestion

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/24.jpg)


![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/14.jpg)

Now ,our DCR creation process is complete .Let's verify if everything is working properly.

I can see my VM in the target resources in the DCR

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/17.jpg)

The extension got installed automatically

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/18.jpg)

System-managed identity is enabled on the VM

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/19.jpg)

⚠️ *Note: If you already have a user-assigned identity to this VM ,unless specified in the request, the machine will default to using System Assigned Identity for all other apps.*

The VM is reporting to the two log analytics workspaces configured in the DCR

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/21.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/22.jpg)

After waiting for some time for the VM to start sending data apart from Heartbeat ,we can see now the log data is being sent to the new workspace

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/23.jpg)

Finally ,i can safely remove all the other monitoring extensions available on the VM using the portal/CLI/Powershell.

⚠️ *While you can use both agents in-parallel, this can duplicate costs ,storage and performance.*


```PowerShell
Get-AzVMExtension -ResourceGroupName "rg-azmon-01" -Name "MicrosoftMonitoringAgent" -VMName "vm-win-01" | Remove-AzVMExtension -Force -Confirm:$false
```

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/20.jpg)

### 2.Mass Deployment using Azure Policy
In this method ,i will use Azure Policy to demonstrate how to do mass deployments for existing and new VMs.

⚠️ *The difference between the portal method and this one is that the system-assigned managed identity will not get created automatically ; so you need to have it enabled first to be abe to authenticate with log analytics.*

This time i will create a new DCR for Linux and will not add any VMs to it.

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/25.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/27.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/36.jpg)


We need to get the DCR resource ID to use it later with the policy

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/31.jpg)

Going to Azure policy and filtering by "Monitoring" ,we get two initiatives for configure the agent and associating the DCR.

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/28.jpg)

Assign the initiative targeting linux to our resource group

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/32.jpg)

Provide the DCR resource ID to associate with our linux VM

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/33.jpg)

Select to create a remediation task as our VM is already deployed

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/35.jpg)

Now ,we wait for 5-10 minutes for the Azure policy to start evaluating and the remediation tasks get started .

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/38.jpg)

We can see now that the agent has been deployed to our VM , the VM gets associated with our linux DCR and it's already reporting to log analytics.

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/37.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/39.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent/40.jpg)

### Recap
The introduction of the Azure Monitor agent to replace other agents is a welcomed addition ,at the moment it's still missing some of the existing capabilities of the other agents but it should get new features along the way. There should be enough time before the other agents get deprecated so my advice is to validate your current monitoring needs and if the new agent provides all what you need ,consider migrating to it ,otherwise it's better to wait with the current setup.


📹ITOpsTalk: Azure Monitor Agent
<figure class="video_container">
<iframe width="560" height="315" src="https://www.youtube.com/embed/f8bIrFU8tCs" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>

📹Microsoft Azure Monitor Agent and Data Collection Rule Overview
<figure class="video_container">
<iframe width="560" height="315" src="https://www.youtube.com/embed/Z1zDlXCwI9k" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>

