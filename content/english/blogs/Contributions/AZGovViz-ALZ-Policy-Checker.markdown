---
title: "Azure Landing Zones - Policy assignments checker"
images:
  - "https://images.seifbassem.com/images/Contributions/AzGovViz-Policy-Assignment/01.png"
date: 2025-05-25 17:08:42 +0200
tags: ["Azure","Bicep","Infrastructure-as-code","Azure-Landing-Zones"]
categories: ["Contributions"]
draft: false
---

<!--more-->

One of the main challenges of maintaining your Azure Landing Zone (ALZ) deployment, is keeping up to date with the latest ALZ policy assignments across your management group hierarchy. To secure and optimize your environment, the ALZ team regularly updates the policy assignments which can introduce some challenges on identifying what has changed and where it does apply.

I recently contributed a new feature to the Azure Governance Visualizer (AzGovViz) tool "ALZ Policy assignments checker", which visualizes your ALZ hierarchy and shows the missing policy assignments that you should have assigned to your different ALZ management groups. Here is a blog post on this feature and how you can use it today.

**Blog post**: <https://techcommunity.microsoft.com/blog/azuregovernanceandmanagementblog/keep-your-azure-landing-zones-policy-assignments-up-to-date-with-azure-governanc/4292789>