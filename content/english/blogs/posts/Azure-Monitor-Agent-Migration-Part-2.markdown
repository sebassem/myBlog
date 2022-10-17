---
title: "Migrating to the Azure Monitor agent - Part 2"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/banner.png"
date: 2022-10-16 09:08:42 +0200
tags: ["Azure","Azure Monitor"]
categories: ["posts"]
draft: false
---

<!--more-->

The Azure Monitor agent (AMA) is the agent replacing all of Azure Monitor's monitoring agents (Log Analytics, Telegraph and Diagnostics extension). The Log Analytics agent will be retired on 31 August, 2024 so customers should start assessing, planning and migrating whenever possible to this new agent. In the [first part of this series](https://www.seifbassem.com/blogs/posts/azure-monitor-agent-migration/), we went through how to plan, assess and test the migration in a test environment. In this post, we will go through performing the migration at scale in production.

>TIP
> If you need a quick crash course on what the Azure Monitor agent is all about, check out this [blog post](./Azure-Monitor-Agent.markdown).

## Current setup

I have two resource groups, one for test workloads and one for production workloads. Each of them has a mix of Windows and Linux VMs and a Windows Azure Arc-enabled servers.

  ![Screenshot showing two resource groups for test and production](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/01.jpg)

In production, we have a Windows VM, a Linux VM and a Windows Azure Arc-enabled server. All of them are connected to a production Log Analytics workspace using the legacy Log Analytics agent.

  ![Screenshot showing the production resources](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/01.jpg)

Installation of the legacy agent and the connection to the workspace are done using Azure Policy since this is a production environment.

  ![Screenshot showing Azure Policy assigned to enable azure Monitor](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/02.jpg)

I can see that data is already flowing into my workspace by looking at VM insights.

  ![Screenshot showing VM insights](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/03.jpg)

  And also Defender for Cloud is reporting that the Log Analytics agent is installed and showing recommendations for my test VMs.

  ![Screenshot showing Defender for Cloud agents installed](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/04.jpg)

## Migration preparation

1. In part one, we have tested the migration side-by-side on the different resources we have to make sure that all needed logs, metrics and solutions are working properly using the Azure Monitor Agent.
2. We need to export the data collection configuration to create the new Data Collection rules for both Windows and Linux
3. We need to disable the data collection on the workspace to avoid unnecessary costs and duplicate data, since this is a production environment which will have much more resources than our test one.

One of the useful tools available to give you oversight over the migration is the **AMA migration helper workbook** which shows you an up-to-date status of your migration in terms of agents installation, servers reporting, solutions installed on the workspace,...etc

  ![Screenshot showing the AMA Migration helper workbook](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/11.jpg)

### Creating the new Data Collection rules

We will use the Data Collection rule config export script to generate ARM templates that will be used to deploy the new rules.

  ![Screenshot showing the data collection rules config export script](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/05.jpg)

  ![Screenshot showing the data collection rules config export script output](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/06.jpg)

Now, to deploy the generate AMR templates for the Windows and Linux rules.

  ![Screenshot showing deploying the Windows data collection rules ARM templates](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/07.jpg)

  ![Screenshot showing deploying the Linux data collection rules ARM templates](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/08.jpg)

  ![Screenshot showing the deployed data collection rules](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/09.jpg)

We can validate that the created rules have the data sources already configured in our Log Analytics workspace.

  ![Screenshot showing the data sources in the data collection rule](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/10.jpg)

The last preparation step is to disable data collection on the workspace.

  ![Screenshot showing the workspace with disabled data collection](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/12.jpg)

### Deploying the agents

When deploying the Azure Monitor agent, you can use the virtual machine's system-managed identity or use a user-assigned managed identity to grant the necessary permissions. For Azure Arc-enabled VMs it's only possbile to use the system-managed identity, for Azure VMs its recommended to use a user-assigned managed identity for better scale. In our case we will create a user-assigned managed identity and assign it to the VMs.

  ![Screenshot showing the user-assigned managed identity](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/13.jpg)

Now, we are ready to deploy the agents using Azure Policy. You can see that the option _Bring your own user-assigned managed identity_ is set to true since we will use a pre-created and assigned identity.

  ![Screenshot showing deploying the Windows agent using Azure Policy](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/14.jpg)

  ![Screenshot showing deploying the Linux agent using Azure Policy](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/15.jpg)

We will deploy two additional policies for Azure Arc-enabled servers. Now we can see all the policies assigned to our production resource group.

  ![Screenshot showing policies assigned to the production resource group](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/16.jpg)

After about 15 minutes, we can see the remediation tasks have completed to deploy the agents and associate them with the newly created Data Collection rules.

  ![Screenshot showing azure policy remediation tasks succeeded](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/17.jpg)

Looking at the extensions tab in our VMs, we can see that the agent has been successfully deployed.

  ![Screenshot showing the new agent deployed on Windows VM](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/18.jpg)

  ![Screenshot showing the new agent deployed on Linux VM](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/19.jpg)

  ![Screenshot showing the new agent deployed on Arc-enabled Windows VM](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/20.jpg)

We can see also the VMs already associated with the Data Collection rules.

  ![Screenshot showing the Windows VMs associated with the data collection rule](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/21.jpg)

Now, to validate that the new agents are sending Heartbeat to the workspace, we run the following query to confirm that everything is configured correctly.

  ![Screenshot showing heartbeat being sent to workspace via the new agent](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/22.jpg)

We need to also assigne the VM Insights Data Collection rule that we created in Part 1 to make sure our production VMs are sending the needed data for Insights to populate.

  ![Screenshot showing VM Insights data collection rule](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/23.jpg)

Looking back at the migration helper workbook, we can see that we have the agents deployed successfully with Data Collection rules associated. The only remaining step is to uninstall the legacy agent.

  ![Screenshot showing the migration progress using the workbook](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/24.jpg)

### Uninstalling the Log Analytics agent

After we can see that the new agent is sending heartbeat and collecting data, we will start uninstalling the legacy agent and remove the data collection settings from the workspace to complete the migration. Let's start by uninstalling the Log Analytics agent extension.

  ![Screenshot showing uninstalling the log analytics extension](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/25.jpg)

### Validating the migration

After some time, checking back on the migration workbook, we can see that our migration is successfully completed.

  ![Screenshot showing the heartbeat query with only AMA](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration-Part-2/26.jpg)

## Recap

In this post, we have migrated to the new Azure Monitor agent in a production environment using Azure Policy on Azure and Azure Arc servers at scale.

## References

- [Azure Monitor agent landing page](https://docs.microsoft.com/azure/azure-monitor/agents/agents-overview)
- [Azure Monitor agent and DCR overview video](https://www.youtube.com/watch?v=Z1zDlXCwI9k&t=1s)
- [Azure Monitor agent discussion with the product group](https://www.youtube.com/watch?v=f8bIrFU8tCs)
- [Azure Monitor agent migration guidance](https://docs.microsoft.com/azure/azure-monitor/agents/azure-monitor-agent-migration)
- [Azure Monitor agent migration tools](https://docs.microsoft.com/azure/azure-monitor/agents/azure-monitor-agent-migration-tools)
