---
title: "Automate non-Azure servers with Azure Arc-enabled servers"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/banner.png"
date: 2021-10-04 17:08:42 +0200
tags: ["Azure","Azure Arc","Automation"]
categories: ["posts"]
draft: false
---

<!--more-->

Azure Arc-enabled servers allows you to project your hybrid servers (on-premises or any cloud provider) to the Azure control plane where you can start managing them as any other Azure server. You can start using native Azure capabilities like Security Center, tagging, automation, policy, monitoring and more. For a quick recap on what Azure Arc provides, you can explore my [previous article](https://www.seifbassem.com/blogs/unboxing/introducing-azure-arc/).

## Hybrid Worker Extension for Arc-enabled servers
It was recently [announced](https://azure.microsoft.com/en-us/updates/automation-user-hybrid-extension-support/) that native integration of user hybrid workers which is based on VM extensions is in public preview for Azure Arc-enabled servers which opens up more automation capabilities for hybrid servers.

This capability allows you to run automation runbooks on your servers wherever they are, and plug into the power of Azure Automation to further automate manual procedures you need to perform on your servers. 

In this post, i will explore this new capability and use it to automate the Azure Arc connected machine agent upgrade process on my on-premises servers.

💡 For Windows Arc-enabled servers, you can also use Azure Update Management to automation the agent upgrade via Windows update

## Setup
I have already on-boarded a virtual machine that resides on my laptop to Azure Arc with an old agent.
![Hyper-v servers](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/23.jpg)

![Arc-enabled server](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/2.jpg)

Azure advisor provides recommendations for Arc-enbaled servers with old agent versions so after some while it triggered a recommendation for my servers.

![Advisor recommendation](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/3.jpg)

Now we need to leverage this recommendation to trigger an automation on our Arc-enabled servers to download and install the new agent. Let's start creating this process 🚀🚀

First, we need to create a new user hybrid worker.

![New hybrid worker](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/5.jpg)

![New hybrid worker](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/6.jpg)
Adding our Arc-enabled server to this new hybrid worker group

![Add all hybrid workers](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/18.jpg)

Next, we need to create the actual runbook that will download and install the new updated agent.

![Runbook creation](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/9.jpg)

The missing part now is how to trigger this runbook when a new agent update is available. Luckily, we can create an alert based on Azure Advisor recommendations. Clicking on the recommendation we want, we can create a new alert ⚠️

![Azure Advisor alert](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/10.jpg)

We need to create a new Action group and select Azure Automation as the action.

![Action group creation](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/11.jpg)

Click on "Configure Parameters" to make sure this runbook will run on out hybrid worker group (Arc-enabled servers)

![parameters](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/17.jpg)

![Action group action](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/12.jpg)

![Alert creation form](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/13.jpg)

Now, we can see our alert created and ready to be triggered when a new agent version is available

![azure advisor alert](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/14.jpg)

Checking the current version of the connected machine agent.

![Agent version](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/1.jpg)

After waiting for some while, we can see the Azure Advisor started triggering recommendations for our Arc-enabled servers.

![Agent azure advisor](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/19.jpg)

Looking at alerts, we can see that our alert has been triggered and as a result the agent upgrade runbook started running on our servers.

![alert fired](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/22.jpg)

![runbook jobs](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/21.jpg)

Going back to our Arc-enabled servers, we can see that the agent version has changed and it was upgraded to the latest version.

![agent new version](https://images.seifbassem.com/images/Posts/Azure-Arc-Automation/20.jpg)

## Recap
Hybrid Worker Extension for Arc-enabled servers is a great way to automate your Arc-enabled servers whether they live on-premises or in another cloud. It opens up a great deal of possibilities to empower you to automate your infrastructure centrally and consistently without caring where the servers live.

