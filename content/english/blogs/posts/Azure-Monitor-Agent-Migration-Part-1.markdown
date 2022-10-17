---
title: "Migrating to the Azure Monitor agent - Part 1"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/banner.png"
date: 2022-08-28 09:08:42 +0200
tags: ["Azure","Azure Monitor"]
categories: ["posts"]
draft: false
---

<!--more-->

The Azure Monitor agent (AMA) is the agent replacing all of Azure Monitor's monitoring agents (Log Analytics, Telegraph and Diagnostics extension). The Log Analytics agent will be retired on 31 August, 2024 so customers should start assessing, planning and migrating whenever possible to this new agent.

>TIP
> If you need a quick crash course on what the Azure Monitor agent is all about, check out this [blog post](./Azure-Monitor-Agent.markdown).

The Azure Monitor agent has multiple benefits over the legacy agents:

- Leverages Managed Identities for better security
- Granular control on the data being collected using Data Collection Rules, this is specially very useful for cost savings and flexibility.
- Easy multihoming on Windows and Linux.
- A higher events per second (EPS) upload rate.

In this post, I will go through the migration planning and execution activities in a test environment to demonstrate the different tools and steps to consider when starting to migrate in your own environment.

## Current setup

I have two resource groups, one for test workloads and one for production workloads. Each of them has a mix of Windows and Linux VMs and a Windows Azure Arc-enabled servers.

  ![Screenshot showing two resource groups for test and production](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/01.jpg)

Looking into the workspace's configuration, I have configured it to collect different logs and counters from the different operating systems I have.

  ![Screenshot showing two resource groups for test and production](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/02.jpg)

  ![Screenshot showing the Windows event log settings](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/02.jpg)

  ![Screenshot showing the Windows performance counters settings](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/03.jpg)

  ![Screenshot showing the Linux performance counters settings](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/04.jpg)

  ![Screenshot showing the Linux Syslog settings](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/05.jpg)

  ![Screenshot showing the IIS settings](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/06.jpg)

I have already connected all my servers to this test workspace.

  ![Screenshot showing the Windows VMs connected to the log analytics workspace](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/07.jpg)

  ![Screenshot showing the Linux VMs connected to the log analytics workspace](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/08.jpg)

I can see that data is already flowing into my workspace by looking at VM insights.

  ![Screenshot showing VM insights](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/09.jpg)

  And also Defender for Cloud is reporting that the Log Analytics agent is installed and showing recommendations for my test VMs.

  ![Screenshot showing Defender for Cloud agents installed](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/10.jpg)

  ![Screenshot showing Defender for Cloud recommendation](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/11.jpg)

## Testing the migration in a test environment

1. The first step to plan the migration is to understand and optimize what we are currently collecting, we need to review the workspace collection settings and decide if all the information collected there is useful **to us** or not.
2. Next we need to look at the current supported operating systems and features in the Azure Monitor agent as till the time of this post it's not at 100% parity with the legacy agents, for example VM insights and Defender for Cloud are in public preview.
3. After deciding on the data we need to collect and making sure all the features we need are there, we will install the Azure Monitor agent side-by-side with the Log Analytics agent on some test machines to validate that data is being collected. In some cases you would have a proxy, or using Private Endpoints for Azure Monitor so validating that the networking part is working as expected is crucial for successful migration.
4. After validating that the data is being collected by the new agent, we can uninstall the legacy Log Analytics agent and remove the data collection configuration from the workspace.

One of the useful tools available to give you oversight over the migration is the **AMA migration helper workbook** which shows you an up-to-date status of your migration in terms of agents installation, servers reporting, solutions installed on the workspace,...etc

  ![Screenshot showing the AMA Migration helper workbook](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/12.jpg)

Since I haven't started to do anything, I can see that the migration status is not started in all tabs of the workbook.

  ![Screenshot showing the agent migration status in the AMA Migration helper workbook](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/13.jpg)

  ![Screenshot showing the solutions status in the AMA Migration helper workbook](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/14.jpg)

  ![Screenshot showing the agent installation status in the AMA Migration helper workbook](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/15.jpg)

### Deploying the agents

In a production environment, you would normally use a method that supports scale deployment like Azure Policy, but since this is a test environment I will deploy the agents manually by creating the Data Collection Rules (DCR) and assign it to my servers and it will take care of enabling the managed identity and installing the agents.

We need first to replicate the data collection settings we have in the workspace to the DCR, we can do this manually or use another useful PowerShell script call the **DCR Config Generator** which scans your workspace and generate ARM templates and/or DCR json configurations.

I will use the manual method but this how the DCR Config Generator works. Although I got an error, the ARM templates were generated successfully.

  ![Screenshot showing the DCR Config generator](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/16.jpg)

  ![Screenshot showing the DCR Config generator output](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/17.jpg)

Now, let's create a new DCR for each operating system. First creating the Windows DCR, adding all of the existing logs and metrics.

  ![Screenshot showing the DCR creation](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/18.jpg)

  ![Screenshot showing the DCR creation](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/19.jpg)

  ![Screenshot showing the DCR creation](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/20.jpg)

  ![Screenshot showing the DCR creation](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/21.jpg)

  ![Screenshot showing the DCR creation](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/22.jpg)

To auto-install the agent, we need to assign this DCR to our servers, in that case our Azure Windows VM and the Arc-enabled Windows server.

  ![Screenshot showing assigning DCR to VMs](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/23.jpg)

After a couple of minutes, we can see the AMA extension gets installed on the Azure and Arc servers.

  ![Screenshot showing the AMA extension on the azure VM ](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/24.jpg)

  ![Screenshot showing the AMA extension on the arc server](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/25.jpg)

To validate that the new agent and the DCR and configured correctly and collecting data, we can query the **Heartbeat** table and look at the category column. We can see that data is being collected using both agents, which is expected at this testing phase since we haven't uninstalled the Log Analaytics agent.

  ![Screenshot showing the AMA sending data using the heartbeat table](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/26.jpg)

Validating also performance counters still flowing and VM insight solution is not affected.

  ![Screenshot showing the AMA sending performance counters](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/27.jpg)

  ![Screenshot showing VM insights](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/28.jpg)

### Uninstalling the Log Analytics agent

After we can see that the new agent is sending heartbeat and collecting data, we will start uninstalling the legacy agent and remove the data collection settings from the workspace to complete the migration. Let's start by uninstalling the Log Analytics agent extension.

  ![Screenshot showing uninstalling the log analytics extension](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/29.jpg)

Then we need to remove all the data collection settings in the test workspace to avoid having duplicate data and unnecessary costs.

  ![Screenshot showing the test log analytics workspace](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/30.jpg)

Revisiting the AMA migration helper workbook, we can see that we are making progress. Our two test Azure VMs have only the new agent and our test Arc-enabled server still has both.

  ![Screenshot showing the AMA migration helper workbook](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/31.jpg)

  ![Screenshot showing the AMA migration helper workbook](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/32.jpg)

  ![Screenshot showing the AMA migration helper workbook](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/33.jpg)

### Validating the migration

After some time, if we query the **Heartbeat** table we can now see that only the Azure Monitor Agent is sending data to the workspace.

  ![Screenshot showing the heartbeat query with only AMA](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/34.jpg)

Looking at VM insights, we can see that its broken, nothing is reporting back. This is due to VM insights needing a special DCR to be configured manually (while its in preview). Going into the VM insights configuration page, we can see that our servers need onboarding.

  ![Screenshot showing the VM insights onboarding page](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/35.jpg)

  ![Screenshot showing the VM insights onboarding page](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/36.jpg)

A new special DCR will be created and assigned to our servers to start onboarding them to VM insights without the Log Analytics agent.

  ![Screenshot showing the VM insights DCR creation](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/37.jpg)

  ![Screenshot showing the VM insights](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/38.jpg)

After about 15 minutes, we can see that VM insights is now operational and performance metrics are being reported back.

  ![Screenshot showing the VM insights](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/39.jpg)

  ![Screenshot showing the perf table in log analytics workspace](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/40.jpg)

  ![Screenshot showing the syslog table in log analytics workspace](https://images.seifbassem.com/images/Posts/Azure-Monitor-Agent-Migration/41.jpg)

## Recap

In this post, we have planned and migrated to the new Azure Monitor agent on some test machines. In the next part, we will continue this journey to do at scale migration in our production environment.

## References

- [Azure Monitor agent landing page](https://docs.microsoft.com/azure/azure-monitor/agents/agents-overview)
- [Azure Monitor agent and DCR overview video](https://www.youtube.com/watch?v=Z1zDlXCwI9k&t=1s)
- [Azure Monitor agent discussion with the product group](https://www.youtube.com/watch?v=f8bIrFU8tCs)
- [Azure Monitor agent migration guidance](https://docs.microsoft.com/azure/azure-monitor/agents/azure-monitor-agent-migration)
- [Azure Monitor agent migration tools](https://docs.microsoft.com/azure/azure-monitor/agents/azure-monitor-agent-migration-tools)
