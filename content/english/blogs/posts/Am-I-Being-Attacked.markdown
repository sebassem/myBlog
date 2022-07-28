---
title: "Am I being attacked?!"
images:
  - "https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/banner.png"
date: 2022-07-27 17:08:42 +0200
tags: ["Azure","Microsoft Sentinel","Security"]
categories: ["posts"]
draft: false
---

<!--more-->

Recently there has been some new tools introduced in Microsoft Sentinel to help security teams understand better the types and methods of attacks they have faced, in addition to intelligence to help them perform proactive threat modeling to implement better defenses.

There has been very tight integration with the MITRE ATT&CK library which provides a knowledge base of adversary tactics and techniques based on real-world observations. Let's explore the new tools.

## Threat Analysis & Response Workbook

The first tool is a workbook that helps you understand the following:

-  Lists the out-of-the box Microsoft Sentinel detections coverage across MITRE ATT&CK framework and the number of events coming for those detections.

  ![Screenshot showing the Sentinel detections](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/01.jpg)

-  Lists all of the Sentinel GitHub content categorized by detection type like hunting, analytics,..etc which is mapped to the corresponding MITRE tactics and also content by cloud platform, which helps understand for example what is avaialble for Azure Vs AWS Vs Office 365,...etc

  ![Screenshot showing the Sentinel GitHub content](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/02.jpg)

  ![Screenshot showing the Sentinel GitHub content by cloud platform](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/03.jpg)

-  Lists all of detections and alerts by Microsoft service so showing detections by Microsoft Defender for Linux, Microsoft Defender for Identity, Microsoft Defender for Containers ,...etc

  ![Screenshot showing all of the detections](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/04.jpg)

  ![Screenshot showing all of the detections by service](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/05.jpg)

-  Shows a heatmap of all of the MITRE ATT&CK matrix categorized by cloud platform such as Azure, AWS, GCP as well as by service such as Azure AD, Office 365, Windows, Linux

  ![Screenshot showing MITRE Heatmap](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/06.jpg)

  ![Screenshot showing MITRE Heatmap by platform](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/07.jpg)

> NOTE
> This workbook is mainly informational to help you understand your current posture and gaps.

## Dynamic Threat Analysis & Response Workbook

This workbook is actually pretty powerful, it visualizes all of the attacks to your cloud, onprem and multi-cloud resources and categorizes them to the corresponding MITRE ATT&CK tactic. This workbook allows you to perform hunting and investigation activities where you can focus on a specific user, source Ip address, country or machine.

  ![Screenshot showing the dynamic threat analysis workbook](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/08.jpg)

Filtering by a specific source Ip address and detecting product

  ![Screenshot showing the dynamic threat analysis workbook with filtering](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/09.jpg)

You get also useful logs to do more in-depth investigation, defense recommendations against those types of attacks, different resources to close those gaps in your environment and remediation through response playbooks.

  ![Screenshot showing the defense recommendations](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/10.jpg)

  ![Screenshot showing the defense recommendations](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/11.jpg)

## MITRE ATT&CK Blade

This is a new blade in Microsoft Sentinel that helps you to visualize your current coverage to understand if there are any blind spots or areas where you need to create your own analytics rules.

  ![Screenshot showing the MITRE blade in Sentinel](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/12.jpg)

## Workbooks deployment

To deploy those two workbooks you can either search for them in the content hub.

  ![Screenshot showing the Sentinel content hub](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/13.jpg)

  ![Screenshot showing installing the first workbook](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/14.jpg)

You can also simply deploy an [ARM template](https://github.com/Azure/Azure-Sentinel/tree/master/Solutions/ThreatAnalysis%26Response) which will install both workbooks into your Sentinel services

![Screenshot showing the GitHub repo for workbooks deployment](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/15.jpg)

![Screenshot showing the workbooks deployed](https://images.seifbassem.com/images/Posts/Am-I-Being-Attacked/16.jpg)

## Video walkthrough

  <figure class="video_container">
 <iframe width="560" height="315" src="https://www.youtube.com/embed/8Qb8p-WjpXY" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>

