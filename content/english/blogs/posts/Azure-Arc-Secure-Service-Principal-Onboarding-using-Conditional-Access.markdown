---
title: "Secure Azure Arc servers onboarding using Conditional Access"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Arc-servers-Conditional-Access/Banner.png"
date: 2022-01-04 17:08:42 +0200
tags: ["Azure","Azure Arc"]
categories: ["posts"]
draft: true
---

<!--more-->

One of the most common methods of onboarding servers to Azure Arc is using a short-lived service principal with least privilege, yet there are some concerns around having this service principal's identity compromised specially if it's not recycled frequently, where an attacker can use it to onboard other servers outside of your organization.

Recently it was announced in Ignite 2021, that Conditional Access policies (In Preview) can be now applied to not only users but also [workload identities](https://docs.microsoft.com/azure/active-directory/conditional-access/workload-identity#sign-in-logs). This allows applying Conditional Access policies to service principals which adds great flexibility to better secure your identities. In this post, I will test this new capability to only allow Azure Arc onboarding from within one location and block any other attempts to onboard originating from outside of this trusted location.

## Block Azure Arc onboarding service principal

First, I will create a policy to block the service principal to demonstrate how this feature will work.

- Create a new Conditional Access policy
- Select **Workload identities** in the assignments section
- Select the service principal I already created for Azure Arc-enabled servers onboarding
- Select **All cloud apps** in the cloud apps section
- Select **Block Access** in the access controls section
- Enable this policy

![Conditional access policy to block all service principals](https://images.seifbassem.com/images/Posts/Azure-Arc-servers-Conditional-Access/1.jpg)

- Now trying to onboard a server using this service principal, I get an error that a Conditional Access policy has blocked this request.

![Conditional access policy blocking onboarding](https://images.seifbassem.com/images/Posts/Azure-Arc-servers-Conditional-Access/3.jpg)

## Allow Azure Arc onboarding only from trusted locations

Next, I will create a new trusted location and add it to the policy to only grant access for this service principal from a specific IP range.

Create a new IP ranges-based named location and add your datacenter(s) IP ranges and mark them as a trusted location

> In this example, I only added one IP address as a named location but you can add IP ranges or countries to the list. More information can be found [here](https://docs.microsoft.com/azure/active-directory/conditional-access/location-condition#named-locations).

![Create a new named location](https://images.seifbassem.com/images/Posts/Azure-Arc-servers-Conditional-Access/4.jpg)

Edit the Conditional Access policy and add a condition to block all locations except for the trusted ones.

![Add trusted locations to policy](https://images.seifbassem.com/images/Posts/Azure-Arc-servers-Conditional-Access/5.jpg)

![Exclude trusted locations from blocking](https://images.seifbassem.com/images/Posts/Azure-Arc-servers-Conditional-Access/6.jpg)

Now, attepmting to onboard again, everything works smoothly and the server gets onboarded successfully.

![Onboarding success message](https://images.seifbassem.com/images/Posts/Azure-Arc-servers-Conditional-Access/7.jpg)

![Azure Arc center portal](https://images.seifbassem.com/images/Posts/Azure-Arc-servers-Conditional-Access/8.jpg)