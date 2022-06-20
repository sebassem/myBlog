---
title: "Improving your security posture with Governance Rules"
images:
  - "https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/banner.png"
date: 2022-06-20 17:08:42 +0200
tags: ["Azure","Microsoft Defender for Cloud","Security"]
categories: ["posts"]
draft: false
---

<!--more-->

Microsoft Defender for Cloud analyzes your resources on a regular basis to identify potential security misconfigurations and weaknesses. It then provides detailed recommendations on the risks of those misconfigurations and actionable guidance on how to remediate those issues. Those recommendations would add up to your secure score where you can track your progress and compliance. One missing piece with this great feature is how to orchestrate assignment, tracking and reporting the progress of the remediation of those recommendations.

A new feature has been recently introduced to allow you to assign owners to recommendations based on severity or type and designate a deadline for remediation, in addition to a report to have full visibility on remdiation timelines. This feature is called **Governance Rules** and in this post, I will give it a spin.

## Governance Rules

Looking at first at my current environment, I have a secure score of _36%_ with lots of recommendations.

  ![Screenshot showing the Microsoft Defender for Cloud recommendations](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/01.jpg)

If we go to the Defender for Cloud settings, we can see the new **Governance Rules** feature.

  ![Screenshot showing the Microsoft Defender for Cloud portal with governance rules](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/02.jpg)

Let's try to create a new rule, give it a name, a description and explore the options available

  ![Screenshot showing the creation of a new governance rule](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/03.jpg)

**Affected recommendations:** I will select the _High_ and _Medium_ severities so that this rule only applies to recommendations with those severity levels. We can alternatively manually select the exact recommendations from the list.

  ![Screenshot showing the creation of a new governance rule](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/04.jpg)

**Owner:** we can type in an email address or have it populated automatically if we have the right tag applied to the resources. I already have an owner tag assigned to one of the affected resources.

  ![Screenshot showing tags assigned to an Azure Arc server](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/05.jpg)

**Remediation timeframe:** This will be the time it should take the owner to remediate this recommendation. We can choose to apply a _Grace Period_ which would make this recommendation not to have an effect on our total secure score till the allocated timeframe expires.

**Notification:** Here we can select if there should be a weekly summary email to the owner and their manager (populated from Azure AD) for open items.

Finally, we have our governance rule all set and ready. Immediatley, we get a popup saying that our rule matches some existing recommendations.

  ![Screenshot showing the governance rule created](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/06.jpg)

  ![Screenshot showing the governance rule popup to apply to existing recommendations](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/07.jpg)

Navigating back to the Defender for Cloud portal, we can see the status column showing different statuses like _On time_ which means the rule applies to them since they have either medium or high severity.

  ![Screenshot showing the defender for cloud recommendations](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/08.jpg)

We can also see a new **Governance report** button at the top which would take us to a really nice workbook that help us keep track of all work being done on the remediation process.

  ![Screenshot showing the defender for cloud recommendations](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/09.jpg)

  ![Screenshot showing the governance rules report](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/10.jpg)

  ![Screenshot showing the governance rules report](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/11.jpg)

Remember, the grace period option we specified ? After checking the secure score in 24 hours, I can see now that the score has changed since all the high and medium recommendations which are within the timeframe will not add up to the score.

  ![Screenshot showing the secure score](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/12.jpg)

In addition to that, I started to get an email in a couple of days with my manager on it about my assigned tasks and timeframe.

  ![Screenshot showing the email digest from governance rules](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/13.jpg)

## Remediation process

After assigning owners and looking at the reporting, I need to start working on the remediation before the deadline. I will choose one of the recommendations on an Azure Arc-enabled server and start remediating it.

  ![Screenshot showing the vulnrability assessment solution recommendation](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/14.jpg)

  ![Screenshot showing the recommendation remediation page](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/15.jpg)

After waiting for some time for the vulnerability assessment solution to get on-boarded on the machine and start reporting back, I can see in the governance workbook that my task is now complete.

  ![Screenshot showing the governance rules workbook](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/16.jpg)

  ![Screenshot showing the governance rules workbook](https://images.seifbassem.com/images/Posts/MDFC-Governance-Rules/17.jpg)

## Recap

This is definitely a simple but very powerful feature to streamline the remediation process and drive accountability across system owners with enhanced reporting and weekly status emails. More information on this feature can be found [here](https://docs.microsoft.com/azure/defender-for-cloud/governance-rules).