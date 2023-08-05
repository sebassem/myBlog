---
title: "Azure Governance Visualizer Accelerator"
images:
  - "https://images.seifbassem.com/images/Contributions/AzGovViz-Accelerator/banner.png"
date: 2023-07-20 17:08:42 +0200
tags: ["Azure","Governance","Cloud adoption framework"]
categories: ["Contributions"]
draft: false

---

The Azure Governance Visualizer ((AzGovViz)) is a PowerShell script that iterates through Azure tenant's management group hierarchy down to the subscription level. It captures data from the most relevant Azure governance capabilities - such as Azure Policy, Azure role-based access control (Azure RBAC), and Azure Blueprints. From the collected data, the visualizer shows your hierarchy map, creates a tenant summary, and builds granular scope insights about your management groups and subscriptions.

  ![Screenshot showing Azure governance tools](https://github.com/JulianHayward/Azure-MG-Sub-Governance-Reporting/raw/master/img/AzGovVizConnectingDots_v4.2.png)

We have recently released a new accelerator that significantly reduces the complexity and time it takes to deploy Azure Governance Visualizer. This new accelerator provides an easy and fast deployment process that automates the creation and publishing of AzGovViz to an Azure Web Application and provides automation to configure the pre-requisites for AzGovViz. Give it a try now to visualize your current Azure environment and gain insights into your current governance posture.

- **AzGovViz :** [https://github.com/JulianHayward/Azure-MG-Sub-Governance-Reporting](https://github.com/JulianHayward/Azure-MG-Sub-Governance-Reporting)

- **AzGovViz Accelerator:** [https://github.com/Azure/Azure-Governance-Visualizer-Accelerator](https://github.com/Azure/Azure-Governance-Visualizer-Accelerator)