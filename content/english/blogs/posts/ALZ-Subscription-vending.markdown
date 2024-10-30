---
title: "Azure Landing Zones - Subscription Vending"
images:
  - "https://images.seifbassem.com/images/Posts/custom-tagged-union-data-type/banner.png"
date: 2024-08-06 17:08:42 +0200
tags: ["Azure","Bicep","Infrastructure-as-code","Azure-Landing-Zones"]
categories: ["posts"]
draft: true
---

<!--more-->

Azure landing zones are a pivotal part of the cloud adoption framework, providing a structured approach to scaling your cloud footprint. One of the core design principles of Azure landing zones is subscription democratization. This principle advocates for distributing the management of Azure resources across multiple subscriptions, allowing for greater granularity in access control and billing. By embracing subscription democratization, organizations can empower different teams with the autonomy to manage their resources effectively, fostering an environment of innovation and agility.

The benefits of subscription democratization are manifold. It enhances security by limiting the blast radius of potential breaches and simplifies governance by aligning subscriptions with organizational structures. Moreover, it allows for more precise cost management and accountability, as each team or department can have visibility over their consumption and spending. This granular approach can lead to more efficient resource utilization and, ultimately, a more cost-effective cloud presence.

However, implementing subscription democratization is not without its challenges, especially for large organizations. Managing a multitude of subscriptions requires a robust governance framework to ensure consistency and compliance across all units. The process of assigning and overseeing these subscriptions at scale can be complex, necessitating clear policies and procedures. Additionally, there's the challenge of providing adequate training and support to ensure all teams can manage their subscriptions effectively. Despite these hurdles, the long-term benefits of subscription democratization make it a worthy endeavor for organizations looking to optimize their cloud operations.

## Why do we need Subscription vending?

Subscription vending streamlines the process by providing an official entry point for application teams to request subscriptions, removing the need for them to navigate the process independently. This accelerates access to application landing zones, enabling quicker workload onboarding. Additionally, it allows the platform team to enforce governance on these zones with minimal effort.

Ideally the process should look like this:

1. Collect subscription request data (workload information, display name, tags, role assignments, resource providers and features, peering to hub,...etc )
2. Initiate platform automation ()
3. Create the subscription by using infrastructure-as-code

![Screenshot showing the Subscription vending process](https://learn.microsoft.com/azure/architecture/landing-zones/images/subscription-vending-components.png)

## Subscription vending implementation


## Resources

https://registry.terraform.io/modules/Azure/lz-vending/azurerm/latest/submodules/subscription
https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/lz/sub-vending
https://learn.microsoft.com/azure/architecture/landing-zones/subscription-vending
https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/subscription-vending
https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/subscription-vending-product-lines