---
title: "Azure Migrate - Modernize your applications during migration"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/banner.jpg"
date: 2021-07-29 17:08:42 +0200
tags: ["Azure","Azure Migrate","AKS","Azure App services"]
categories: ["posts"]
draft: false

---

<!--more-->

# Overview
It was [recently announced](https://azure.microsoft.com/en-us/blog/accelerate-your-azure-migration-and-modernization-journey-with-expended-programs-and-offers/) that the Azure Migrate program has been rebranded to **Azure Migration and Modernization Program** where additional capabilities are being added to help customers not only lift-and-shift their servers and applications to Azure but also to modernize them during migration. 

When customers plan to move to Azure , it's always advised to evaluate their applications and determine the right way to move them to the cloud. The cloud adoption framework provides [great guidance](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/digital-estate/5-rs-of-rationalization) on this rationalization process where you have 5 different methods to think of your application migration : 
1. **Rehost** : simply a lift-and-shift migration where i will just move my application to the cloud with minimal or no change to the architecture.
2. **Refactor** : i will look to use some PaaS services to refactor my application , for example using Azure SQL instead of hosting SQL on a Virtual machine or using Azure Web Apps instead of an IIS windows Virtual machine.
3. **Rearchitect** : in this model i will look to rearchitect my application to be more cloud-native , examining all it's components and trying to leverage cloud-native capabilities changing the design of my application to drive more operationl efficiency and cost benefits.
4. **Rebuild** : i will look to rebuild the application from the ground up as it is no longer meeting the business requirements , so a new code base is needed to drive benefit to the business and also building it as a cloud-native application will drive more operational efficiency.
5. **Replace** : i will look for SaaS applications that can provide the same value my application provides or even a native Azure service that can provide the same capabilities.

# Azure Migration and Modernization Program (AMMP)

A new tool has been introduced (still in Preview) , that allows us to containerize .NET and jave applications and migrate them directly to Azure Kubernetes service or Azure app service , it will discover your application , detect it's dependencies and build a Dockerfile that will be used to build the container image of this application. Doing just that is a great way to modernize your applications but in most situations it won't be enough to benefit from the full benefits of the cloud , some re-architeture might be needed to add more value and make most of your migration to Azure . The documentation calls this out nicely below.

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/19.jpg)

Since the Application Containerization tool is still in preview , there are some pre-requisites listed [here](https://docs.microsoft.com/en-us/azure/migrate/tutorial-app-containerization-aspnet-kubernetes#prerequisites) , the most important ones are : 

- This tool currently only supports ASP.NET (using Microsoft .NET framework 3.5 or later) and java web applications (using java 7 or later)
- The machine running the tool needs to have connectivity to the application servers
- PowerShell remoting needs to be enabled on the application servers
- Microsoft Web Deploy tool needs to be installed on the machine running the tool
- 
## Application Containerization tool test drive

In this demo , i will deploy an ASP.NET application on Windows server 2012 and will try to leverage this tool to containerize and deploy to Azure Web Apps.

### Application server preperation
![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/3.jpg)

Enabling PowerShell remoting

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/4.jpg)

Since i'm lazy 😄 , i cloned a [blogging platform](https://github.com/BlogEngine/BlogEngine.NET) from GitHub using ASP.NET and deployed it to a windows server VM with IIS.

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/21.jpg)

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/18.jpg)

### Application Containerization tool server preperation
Downloaded the tool from this [link](https://go.microsoft.com/fwlink/?linkid=2134571)

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/5.jpg)

The tool is installed using a PowerShell script

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/6.jpg)

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/7.jpg)

Once installed , we need to select what type of application we will containerize and also the target location whether it's AKS or App services. In this example i will migrate to App services.

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/22.jpg)

Checking pre-requisites

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/23.jpg)

Signing in to Azure and selecting the right tenant and subscription

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/24.jpg)

Adding the IP address or hostname of the application server along with the right credentials to discover the supported applications to containerize

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/25.jpg)

It discovered my application and it allows me to name the container , add additional application folders and parameterize any application configuration like connection strings (most probably you might be migrating the data tier as well with the application).

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/26.jpg)

![Azure Migrate docs](https://docs.microsoft.com/en-us/azure/migrate/media/tutorial-containerize-apps-aks/discovered-app-configs-asp.png)

It builds the Dockerfile for our application and we can even edit it to add other components if needed . We can also create or use an existing Azure container registry to store the image that will be built by the tool to deploy later.

🍹 Building the image can take some time , so it's a good idea to get something to drink till this is complete 

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/27.jpg)

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/28.jpg)

The final step , would be the deployment . Since we choose at the beginning of the wizard that we are deploying to Azure App service , we can create or use an existing App service plan to deploy our app.

💡 The exeprience is very similar if we chose to deploy to AKS.

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/29.jpg)

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/30.jpg)

Now that deployment is complete , let's explore our application containerized on Azure App services 🚀

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/31.jpg)

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/32.jpg)

We can start leveraging the power of Azure App service like autoscaling for container instances

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/33.jpg)

Or even add Azure AD as the identity platform for our application to leverage Conditional access and other security capabilities.

![Azure Migrate docs](https://images.seifbassem.com/images/Posts/Azure-Migrate-Modernize/34.gif)


# Recap

Azure Migrate is growing to be the one-stop shop to safely and efficiently migrate your workloads and applications to Azure with more additional capabilities being added like the App Containerization tool to help you think about modernizing your applications as well to gain the most benefit of moving to Azure.

<figure class="video_container">
<iframe width="560" height="315" src="https://www.youtube.com/embed/9MJ-FvzJiHI" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>

