---
title: "Project servers to Azure from virtually anywhere!!"
images:
  - "https://images.seifbassem.com/images/Unboxing/Azure-Arc/banner.jpg"
date: 2021-05-18 17:08:42 +0200
tags: ["Azure", "Azure Arc"]
categories: ["Azure Unboxing"]
draft: false
---


# Going multi-cloud or hybrid 🚀, missing anything?!

The rapid increase in cloud computing adoption, various cloud providers, new services and features being introduced almost every day, the need to deliver value faster to customers and the recent trend in bringing cloud power to the edge has caused a sprawl of applications and services being deployed all over the place whether on-premises or in different cloud providers or even at the edge. This diversity in the location where applications sit can help organizations be more agile when deploying their services to their customers but on the other hand can introduce an imbalance in the security/governance arm of the scale.

Every cloud provider (if you are deploying in the cloud) or IT administrators (if you are deploying on-premises) have their own set of management and security tools, capabilities and processes which can impose a new challenge for your IT to stretch their skillset across clouds and technologies , learn how to apply your organizational controls and regulations to different platforms and reduce the velocity needed to level the scale of security/governance and velocity.

# Azure arc, leveling the scale⚖️
Organizations might be deploying some of their workloads to AWS or GCP or even on-premises and loving it, they are not looking to bring those workloads to Azure at the moment, but they would like to extend Azure's management capabilities to those workloads to have a single-pane of glass and control-plane to manage and secure all of their estate using the same tools and same expertise.

Azure Arc is a service which projects your workloads into Azure resource manager whether they are sitting on-premises or any other cloud, allowing you to manage virtual machines, Kubernetes clusters, and databases as if they are running in Azure. Regardless of where they live, you can use familiar Azure services and management capabilities.

**Azure Arc capabilities** 

- Implement consistent inventory, management, governance, and security for your servers across your environment leveraging Azure policy, tags, Azure security center and much more.
- Deploy Azure VM extensions to monitor, secure, and update your servers even if they sit outside of Azure
- Manage and govern Kubernetes clusters at scale.
- Use GitOps to deploy configuration across one or more clusters from Git repositories.
- Zero-touch compliance and configuration for your Kubernetes clusters using Azure Policy.
- Run Azure data services on any Kubernetes environment as if it runs in Azure (specifically Azure SQL Managed Instance and Azure Database for PostgreSQL Hyperscale, with benefits such as upgrades, updates, security, and monitoring). Use elastic scale and apply updates without any application downtime, even without continuous connection to Azure
- A unified experience viewing your Azure Arc enabled resources whether you are using the Azure portal, the Azure CLI, Azure PowerShell, or Azure REST API.


![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/architecture.png)

*In this article, i will focus on Azure Arc enabled servers to demonstrate how to use this cool service to manage 3 servers sitting in AWS, GCP and on-premises using the native Azure capabilities.*

# Environment setup
I have created three virtual machines in AWS, GCP and on local Hyper-V server where we will use Azure Arc to bring them over to Azure. To deliver this experience with your hybrid machines hosted outside of Azure, the Azure Connected Machine agent needs to be installed on each machine that you plan to connect to Azure, so let's start by deploying the agent.

1. We need to create a service principal with the "Azure Connected Machine Onboarding" role to automate the whole on-boarding process. We will use PowerShell to create it for simplicity.
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-3.png)
2. Next, we add a new Azure Arc configuration
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-4.gif)
After downloading the script, we will need to supply the service principal password to be able to run it on our servers
3. First, we will on-board our server sitting in the google cloud platform
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-5.png)

![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-6.png)

![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-7.png)
Our GCP server is now on-boarded to Azure using Azure Arc, one down, three to-go!!
4. Now i will run the on-boarding script on my two other windows machines hosted in AWS and Hyper-V.
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-8.png)

![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-9.png)

![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-10.png)
Now we have 3 servers on-boarded to Azure Arc, none of them is hosted on Azure - Cool stuff 👍

# Managing Azure Arc enabled servers using native Azure tools
## Azure Policy
Let's first, explore Azure policy where we can enforce controls and configurations across all our workloads and now with Azure Arc, we will be able to extend this capability to outside of Azure.

Let's deploy an Azure Policy initiative to deploy the log analytics monitoring and dependency agents to the resource group having our three virtual machines to be able to monitor them.
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-11.png)
Before applying the policy initiative, we can see that our Azure Arc enabled servers do not have the log analytics or the dependency agents installed.
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-12.png)
Once the policy is applied, we can see that our three servers reporting as not compliant.
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-13.png)
We initiate a remediation task to force policy compliance and the installation of the agents and in a couple of minutes we can see that the log analytics and the dependency agents are getting installed on our arc-enabled servers.
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-14.png)

## Azure Security Center
In addition to enforcing controls using Azure policy to your Azure arc-enabled servers, we can leverage the power of Azure Security Center to protect servers residing outside of Azure.

Once we on-boarded our servers to Azure Arc, we can see below that Azure Security Center has recommendations to increase the security posture of those servers as if they are hosted on Azure.
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-15.png)

![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-16.png)

## Update Management
We also get update management to our Azure Arc-enabled servers where we can monitor and deploy updates to those servers and have a single-pane of glass to manage our windows and Linux servers update compliance.
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-17.png)

## VM insights
Finally, we can leverage the power of VM insights to monitor our servers' performance and see the service map to understand what connections our servers have with other components.
![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-18.png)

![AzureArc](https://images.seifbassem.com/images/Unboxing/Azure-Arc/Unboxing-Azure-Arc-19.png)

# Summary
Azure Arc enabled servers is a very powerful solution to help ease the burden of unifying the management, security and monitoring of multi-cloud and hybrid deployments using the same consistent set of capabilities available in Azure.