---
title: "Azure Policy gradual rollout with resource selectors"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/banner.png"
date: 2023-02-04 13:00:42 +0200
tags: ["Azure","Azure Policy","Governance"]
categories: ["posts"]
draft: false
---

<!--more-->

Remember in the old days when using group policy on-premises, you had the flexibility to apply a group policy object to an organizational unit and add additional filtering using WMI or security filtering to further scope down the resources that this group policy object will apply to. Fast forwarding to Azure, Azure policy never really had this type of flexibility, it sure had exemptions and you can have assignemnts scoped down to a resource group but its not as flexible as security filtering in group policy.

  ![Screenshot showing group policy filtering](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/01.jpg)

This has now changed with Azure Policy resource selectors which is a new capability in Azure Policy that allows you to gradually rollout a policy by filtering the resources that the assignment is applied to. By the time this post was written, you can scope resource according to location, resource type and resources at the subscription level which do not have a location. This is particularly helpful as you now can gradually rollout an Azure policy by just editing the assignment, you no longer have to edit the definition to do that.

## Video demonstration

<iframe width="547" height="547" src="https://www.youtube.com/embed/OUCIPP-z8os" title="Azure Policy resource selectors" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

## Demo

Let's explore how you can leverage this new feature to gradually rollout an Azure Policy assignment based on a resource region.

### Setup

We have two AKS clusters in the same resource group residing in the *West Europe* and *East US* regions and we have a requirement to deploy the Azure Policy add-on on the two clusters so we can properly govern the workloads running inside them. We will use the Azure Policy resource selector feature to first rollout this policy in the *West Europe* region then after validation, we will extend to clusters in the *East Us* region just by editing the policy assignment.

  ![Screenshot showing two AKS clusters](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/02.jpg)

We can see initially that both of our clusters do not have this add-on enabled.

  ![Screenshot showing the Azure Policy add-on not enabled on the first cluster](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/03.jpg)

  ![Screenshot showing the Azure Policy add-on not enabled on the second cluster](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/04.jpg)

Now we will assign a new [Azure Policy to enabled the add-on](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F0a15ec92-a229-4763-bb14-0ea34a568f8d) to the resource group containing both clusters. We can see that the resource selectors option is now visible in the portal.

  ![Screenshot showing the Azure Policy aassignment screen with resource selectors](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/05.jpg)

We will choose the *resourceLocation* selector to scope this assignment first to the resources in the *West Europe* region.

  ![Screenshot showing the resource selector with location as the selector](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/06.jpg)

After about 15 minutes, looking at the AKS clusters' policy tab, we can see that the policy has been applied only to the *West Europe* cluster although the policy has been applied to the resource group having both clusters.

  ![Screenshot showing the West Europe cluster with the add-on deployed](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/07.jpg)

  ![Screenshot showing the East US cluster with the add-on not deployed](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/08.jpg)

Now after performing all our tests on the AKS cluster in the *West Europe* region and validating all our requirements, we are ready to complete the rollout of the Azure Policy deploying the add-on to the *East Us* region. All we have to do is to edit the existing policy assignment and add the second region to our policy resource selector.

  ![Screenshot showing adding East US to the policy resource selector](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/09.jpg)

  ![Screenshot showing the policy being applied to the east us region](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/10.jpg)

  ![Screenshot showing the policy compliance state](https://images.seifbassem.com/images/Posts/Azure-Policy-Resource-Selectors/11.jpg)

## Summary

[Azure Policy resource selectors](https://learn.microsoft.com/azure/governance/policy/concepts/assignment-structure#resource-selectors-preview) by the time of this post is in preview, its a great capability to allow you to scope Azure Policy assignments and gradually rollout a policy based on conditions (currently limited to location, no locations and resource types) without having to change the policy definition.