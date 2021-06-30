---
title: "Azure Bicep - next gen Infrastructure as code"
images:
  - "https://images.seifbassem.com/images/Unboxing/Azure-Bicep/banner.jpg"
date: 2021-02-21 17:08:42 +0200
tags: ["Bicep","Azure","IaaC"]
categories: ["Azure Unboxing"]
draft: false
---

# Overview
I have always been a huge fan of Infrastructure-as-code (Iaac), it allows you to describe your infrastructure in a declarative way, store it in version control and modify in a controlled manner. This approach tries to eliminate human error, increases your efficiency in deploying and maintaining your resources, you can deploy complete datacenters in a matter of minutes be deploying a template file instead of spending hours/days clicking through the portal.

The real power of Iaac is that it uses a declarative syntax to define resources instead of using an imperative one. To explain the difference between them, i like to use a pizza analogy.

Imagine that you are craving eating a pizza, you have two options:
        ![pizza](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-1.jpg)

1. You call your favorite pizza shop; describe how you would like your pizza and that's it. 30-45 minutes later you get your pizza as you described, no questions asked, the hard work is done for you. This is what declarative looks like.
2. You go to the supermarket, buy the necessary ingredients, and go to the kitchen and follow a certain recipe and start cooking. 30-45 minutes later you get your pizza as you described but you had to figure out how to make it. This is what imperative looks like.

## Azure resource manager
Azure implements this concept in its management layer through Azure resource manager (or simply ARM), which is a REST api that acts as your front-door to Azure resources. You usually interact with Azure through either the portal, PowerShell, Azure CLI or other APIs, what happens is that all requests are sent to the Azure resource manager to be authenticated and authorized and then sent to the appropriate Azure service provider whether it's compute, storage, networking, or others.
![ARM](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-2.jpg)

This top layer manages RBAC, policies, subscriptions, resource groups, tags, activity log ...etc. so, you can have a unified management capability across azure resources.

Azure resource manager allows you Manage your infrastructure through declarative JSON templates which makes it easier (not 100% accurate) to describe and deploy resources.

## ARM Challenges
Before explaining the challenges with ARM, let's talk a look at what an ARM template that builds a virtual machine looks like.

> A picture is worth a thousand words
> 
![ARM](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-3.jpg)

Although VSCode makes the authoring process of ARM templates easier and you can simply export a template from the Azure portal directly, the above example shows that it's still not that easy to author and difficult to read especially in complex architectures.

# Azure Bicep to the rescue
Bicep is currently an experimental declarative language that acts as an abstraction for ARM, it's much easier to read and author and anything that can be done in ARM can be done in Bicep.

You would describe your infrastructure in Bicep language and then compile it to an ARM template, the significance of this is:

You get a human-readable syntax
Easier to learn language
You don't write any JSON
You get zero-day support for new resources or properties as it still calls the ARM api

## Bicep in action
First things first, we need to install the Bicep tools:

1. Install Bicep CLI: [https://github.com/Azure/bicep/blob/main/docs/installing.md](https://github.com/Azure/bicep/blob/main/docs/installing.md)
2. Install VSCode Bicep extension for intellisense: [https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)

Next, we are going to use Bicep to build a simple Azure web app and a service plan.

## Defining parameters
We will define parameters for the resources' location, a prefix for our web app, the service plan Sku and capacity.

![ARM](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-4.jpg)

Then we will add some variables for the tags and the web app name (leveraging the prefix parameter and adding hash string based on the resource group id)

![ARM](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-5.jpg)

Next , we add our two resources which are the app service plan and web app. You can see how easy it is to define a resource, where we are directly calling the resource api to get its attributes and the VSCode makes things easier by providing intellisense.

![ARM](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-6.jpg)

One last a cool feature of Bicep is the ability to bind to previously declared resources properties. In this case i want to output the URL of the web app that will be created.

![ARM](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-7.jpg)

Finally, let's compile this good-looking file into an ARM template and see how the Bicep and the ARM versions of this template compare.

*Bicep build ./webapp.bicep*

![ARM](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-8.jpg)

You can see on the left the bicep file we just authored and, on the right, the generated ARM template.

Then we can simply use PowerShell or CLI to deploy this generated ARM template to a resource group. You can see at the end the URL of the created web app is displayed as well as we defined in out Bicep file.

![ARM](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-9.jpg)

And here is our app up and running.

![ARM](https://images.seifbassem.com/images/Unboxing/Azure-Bicep/Azure-Bicep-10.jpg)

# Closing thoughts
Although Bicep is still experimental and you should not use it in production, it's very tempting to play with and it shows tremendous potential to simplify how we approach Iaac on Azure. It's human-readable syntax, zero-day support for Azure resources accompanied with the power of VSCode promises to deliver big time.

# References
- [Previous article on ARM templates](https://www.linkedin.com/post/edit/6695276505158688768/)
- [Project Bicep GitHub repo](https://github.com/Azure/bicep)
- [Project Bicep playground](https://bicepdemo.z22.web.core.windows.net/)

<figure class="video_container">
 <iframe width="560" height="315" src="https://www.youtube.com/embed/ykHA5QTYlDc" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>

<figure class="video_container">
 <iframe width="560" height="315" src="https://www.youtube.com/embed/wkQIyenVfxc" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>



