---
title: "Optimize cost with Virtual Machine Scale Set Spot Mix"
images:
  - "https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/banner.png"
date: 2023-03-13 17:08:42 +0200
tags: ["Azure","Cost Management","Spot"]
categories: ["posts"]
draft: false
---

<!--more-->

Azure Virtual Machine Scale Sets (VMSS) are a way to create and manage a group of identical VMs that can automatically scale up or down based on demand. VMSS can use Azure Spot Virtual Machines (Spot VMs) to reduce costs and optimize resource utilization. Spot VMs are unused Azure compute capacity that is available at a significant discount compared to standard (on-demand) VMs.

  ![Screenshot showing Virtual Machine Scale sets](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/01.png)

However, Spot VMs have some limitations and trade-offs. They can be evicted at any time when Azure needs the capacity back, and they may not be available in all regions or sizes. To mitigate these risks, you can use a new feature called Spot Priority Mix for VMSS. This feature allows you to specify a percentage distribution of standard and Spot VMs in your scale set, so that you can balance high availability and cost savings.

Let's see how we can use this feature using a demo.

## Demo

I will start by creating a normal Virtual Machine Scale Set using the portal and I will select the orchestration mode as **Flexible** to be able to use Spot instances.

  ![Screenshot showing creating a Virtual Machine Scale set](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/02.png)

To be able to use Spot instances also, we need to check the **Run with Azure Spot discount** option. And I will select the *Standard_D4s_v3* AS my VM size.

  ![Screenshot showing creating a Virtual Machine Scale set with spot discount](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/03.png)

In the **Spot** tab, I will have to specify the normal options for a spot instance like the eviction type whether its based on capacity or the maximum price I'm willing to pay, and eviction policy whether I need to keep the evicted VM in case I can redeploy it again.

  ![Screenshot showing creating a Spot instances eviction options](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/04.png)

Next, the most important screen where I specify the percentage of standard (uninterruptible) VMs Vs. Spot Instances in my scale set. In this example, I decided to have a minimum of 10 standard (uninterruptible) VMs and 70:30 ratio of standard (uninterruptible):Spot Instances.

  ![Screenshot showing scaling options for the virtual machine scale set](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/05.png)

Finally, I will specify that the minimum number of instances in this scale set should be 10 and I will use a manual scaling option for the sake of this demo.

  ![Screenshot showing the minimum number of vms for the virtual machine scale set](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/06.png)

So to summarize, we have a VMSS with the following settings:

- Minimum of 10 VMs in this scale set.
- The scale set needs to have at anytime at least 10 standard (uninterruptible) VMs.
- The ratio for standard (uninterruptible) VMs and Spot Instances at any point should be 70% to 30%.

After deploying this scale set, we can see that we don't have any Spot Instances deployed since we started with 10 VMs and we need to have a minimum of 10 standard (uninterruptible) VMs.

  ![Screenshot showing the instances in the virtual machine scale set](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/07.png)

If we scale up the VMSS to 20 instances, we start to see that we are getting 3 Spot Instances and 17 as standard (uninterruptible) VMs. This is due to adding 10 instances to the current scale set, we have 10 that need to be standard (uninterruptible) and the other 10 should be 70:30 standard (uninterruptible):Spot Instances.

  ![Screenshot showing the instances in the virtual machine scale set after scaling up](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/08.png)

  ![Screenshot showing the instances in the virtual machine scale set after scaling up with spot instances](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/09.png)

This allows us to balance high availability and cost when creating large Virtual Machine Scale Sets. If we take a look at the cost of the VM size we selected '*Standard_D4s_v3*' , we can see that with Spot Instances we save around 39% (166.59$ Vs. 274.48$) compared to the Pay-as-you-go price.

  ![Screenshot showing the pricing of the VM size](https://images.seifbassem.com/images/Posts/VMSS-Spot-Mix/10.png)
