---
title: "Planning a new Windows 10 build with Microsoft Teams"
images:
  - "https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/banner.png"
date: 2020-11-27 17:08:42 +0200
tags: ["Microsoft 365","Windows 10","Teams"]
categories: ["posts"]
draft: false
---

<!--more-->
# Microsoft Teams as a platform
Microsoft teams has grown to be the ultimate collaboration platform of the enterprise, with the latest innovations announced in Ignite and even after Ignite (it is getting very hard for me to keep up with the new features 😄), the sky is the limit to what you can build on top and the question now is not what apps i can integrate with Teams, but given the amazing flexibility of the platform , it's now how can i blend my day-to-day processes into the Teams platform.

I'm not a Teams expert by any means, but i will try in this article to demonstrate how easy it is to implement a sample process using Teams, that most organizations go through when a new build of Windows 10 is released

# Windows 10 - The challenge of moving to Windows as a service
Windows 10 introduced a new servicing model called "Windows as a service", allowing IT to deliver windows - as a service - to its end users where incremental updates to the operating system are delivered in a more predicable cadence (twice per year). This allows for a more pleasant user experience, continuous innovation, best-in-class security capabilities and response and a lower TCO.

The benefits of this new servicing models are achieved when organizations are able to define a repeatable and seamless process that they can go through with every release to deliver the new feature update without investing a lot of time and manpower. The process can include examining new features, identifying pilot groups, application compatibility, infrastructure readiness, ......etc.

Leveraging the Teams templates feature, you can define a team's structure designed around a business need or project, adding channels and applications to consistently allow for Teams creation in your organization. What we will do is leverage this feature to define a sample "Windows 10 new build" planning template to define a repeatable process we can go through with every new feature update of Windows 10 released.

# Building the process
Summary of what we are going to build:

1. Create a Teams template with all the necessary channels that we will need
2. Leverage Power Automate to trigger the creation of this Team every 6 months
3. Add the "New Features" article in one of the channels
4. Schedule a Kick-off meeting with all concerned stakeholders

## Create a Teams template with all the necessary channels that we will need
First, let's create a template using the admin center and add all the needed channels and applications.
![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-1.png)

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-2.png)

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-3.png)

Next, we need to add all the channels we need according to our planning process. As an example, i have added the following channels:

- Reporting: Connect to a Power BI report to assess the current builds in our environment
- Tasks: Connect to Planner to assign tasks and deadlines
- Feedback: Connect to forms to get early feedback from early adopters of the new build
- Application readiness: Connect to Planner to assign testing tasks to application owners

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-4.png)

## Leverage Power Automate to trigger the creation of this Team every 6 months
At the moment, you can only automate the deployment of a team from a template using Graph API, so what we'll do is to create a flow to create this new team twice per year using our newly created template.

First, we need to define a schedule when this new team will be created. As an example, i will have it created every 6 months starting from September.

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-5.png)

Then, we will use the [create team endpoint ](https://docs.microsoft.com/en-us/graph/api/team-post?view=graph-rest-beta&tabs=http) in the graph api and pass along our new template ID

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-6.png)

## Add the "New Features" article in one of the channels
The template feature gives us a skeleton of the team we need but it doesn't allow us to customize the channels or apps during the provisioning process, so say that we need to add the "What's New in Windows 10 20H2" article to the "What's New" channel, for that we can use Graph API to inject this website into our channel.

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-7.png)

## Schedule a Kick-off meeting with all concerned stakeholders
Finally, we need to send all stakeholders a kick-off meeting to start the planning process using our newly created team. We can use the "Find time" connector to suggest meeting slots to attendees

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-8.png)

Finally, we get this team created with all the channels we need to start planning the deployment of a new Windows 10 build twice per year automatically

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-9.png)

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-10.png)

![Windows10_With_Teams](https://images.seifbassem.com/images/Posts/Plan-Windows-10-Teams/Windows10-teams-11.png)

## Summary
The Teams templates feature is very useful to define a reusable Teams structure, and when combined with Microsoft graph and power automate can allow you to respond to any event that happens in your organization in an automated manner to bring people together to collaborate.

