---
title: "A better way to enable Azure Defender"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/banner.png"
date: 2021-09-10 17:08:42 +0200
tags: ["Azure","Microsoft Defender for Cloud","Security"]
categories: ["posts"]
draft: false
---

<!--more-->

Azure Defender is Azure's cloud workload protection tool ,it provides a range of advanced protection capabilities for your Azure resources. The way you can use those capabilities is to enable one or all of the following plans for the resources you would like to protect.

- Azure Defender for servers
- Azure Defender for App Service
- Azure Defender for Storage
- Azure Defender for SQL
- Azure Defender for Kubernetes
- Azure Defender for container registries
- Azure Defender for Key Vault
- Azure Defender for Resource Manager
- Azure Defender for DNS
- Azure Defender for open-source relational databases

![Azure defender](https://docs.microsoft.com/en-us/azure/security-center/media/azure-defender/sample-defender-dashboard.png)

To activate those plans ,you would need to go to the Azure Security Center portal ,select the subscrptions you would like to protect it's resources and enable the appropriate plan(s).

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/2.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/3.jpg)

The problem with this approach is that it's not dynamic ,say that you have created a new subscription for a new application or a new department ,you would have to manually go the portal and enable the different plans manually which may cause some subscriptions remain unprotected or go unnoticed.

## What happens under the hood?
When you enable any of the Azure Defender plans using the portal ,one or more Azure policies gets assigned to the subscription(s) to enable the selected plan(s). In this example ,i have a subscription with an Azure SQL database and enabling Azure Defender manually ,i can see that a new policy got assigned to enable the Azure Defender for SQL plan automatically.

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/14.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/5.jpg)

Using Azure Policy will help enable this plan on any new resources added to this subscription ,but what if we add additional subscriptions ?

## Azure Policy to enable Defender plans
Let's explore a more robust way to enable Azure Defender plans using those policies. I have a management group structure ,where there are production and development ones ,the plan is to enable defender plans only on the production and make sure that any new subscriptions get added ,they automatically get the plans enabled.

The **MG-Production** management group now has just one subscription.

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/1.jpg)

If we go to Azure Policy and filter by Security Center ,we can see that we have a policy for each plan.

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/9.jpg)

I will create a custom policy initiative to group all the policies which enable the defender plans.

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/10.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/11.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/12.jpg)

Now ,will assign it to the production management group which at the moment has only one subscription.

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/13.jpg)

Once the initiative gets applied ,we will have to remediate the resources since they already exist.

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/16.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/17.jpg)

We can see now that the Azure SQL plan has been automatically enabled without visiting the portal and we got one Azure SQL server protected.

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/18.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/4.jpg)

Next ,let's add a new subscription to the production management group.

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/15.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/19.jpg)

After waiting for some time to allow the policy to apply ,we can see that defender is enabled on the new subscription automatically

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/21.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/23.jpg)

And ,the new resources are showing to be protected as well in the defender portal with no manual interaction with the Azure portal.

![alt](https://images.seifbassem.com/images/Posts/Azure-Defender-Policy/22.jpg)

## Recap
While you can enable Azure Defender plans using the portal ,it makes more sense to leverage the new Azure Policies to make sure that no subscription/resource gets left behind by mistake when it comes to the security  posture of your environment.

