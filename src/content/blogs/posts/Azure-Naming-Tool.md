---
title: "Azure Naming Tool"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/banner.png"
date: 2022-08-06 17:08:42 +0200
tags: ["Azure","Cloud Adoption Framework","Governance"]
categories: ["posts"]
draft: false
---

<!--more-->

While working with lots of customers helping them to increase the quality of their workloads using the Well-Architected Framework, I usually advise them to create, maintain and enforce a naming convention on their Azure resources for better governance and visibility. I usually guide them to the Cloud Adoption Framework guidelines for creating a naming convention - which has some great guidance - but the problem is they have to build some sort of process or build an internal tool to automate it and make it easier to their business units and application owners to consume.

  ![Screenshot showing the Cloud Adoption Framework naming convention documentation](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/01.jpg)

  ![Screenshot showing the Cloud Adoption Framework naming convention documentation](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/02.jpg)

The Azure naming tool is a .NET containerized tool with a RESTful API that helps admins configure the naming convention components and then it can be easily consumed through a web UI or an API to automatically generate a name for any Azure resource according to the best practices defined in the Cloud Adoption Framework. In this post, I will give this new tool a spin.

## Azure Naming Tool local setup

The tool is hosted on GitHub, so first we need to download/clone the repo to a local directory.

  ![Screenshot showing the folder structure of the naming tool](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/03.jpg)

We will need Docker Desktop installed and running locally to be able to build and run the containerized image.

  ![Screenshot showing Docker Desktop running](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/04.jpg)

To build the Docker image, we need to run the following Docker command while in the root directory.

  ```bash
  docker build -t azurenamingtool .
  ```

  ![Screenshot showing building the docker image](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/05.jpg)

Validating that the image is now built locally.

  ```bash
  docker images
  ```

  ![Screenshot showing building the docker image](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/06.jpg)

We can now, run a new Docker container locally using the built image. I will use port 8081 but you can use any other free port.

  ```bash
  docker run -d -p 8081:80 --mount source=azurenamingtoolvol,target=/app/settings azurenamingtool:latest
  ```

  ![Screenshot showing running a docker container](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/07.jpg)

>NOTE
> You can see that we are using a persistent volume to to store configuration files. When deploying locally, Docker will use your machine's storage but in production, you will need to think about which type of storage available to you.

Navigating to http://localhost:8081, we can see that the tool is now up and running.

  ![Screenshot showing the Azure naming tool running locally](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/08.jpg)

## Exploring the Azure Naming Tool

Let's navigate what the tool provides in terms of configuration and features. After providing a password and logging into the tool, I clicked the **Admin** button and in this screen, I can change the password and view/generate an API key to be able to programmatically use and integrate this tool with other internal tools you might have.

  ![Screenshot showing the admin page of the tool](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/09.jpg)

The naming convention according to the Cloud Adoption Framework guidance should be composed of some of the following components: Resource Type, Business unit, Application or service name, Deployment environment and location. In the **Components** section of the tool, you can see those components with an option to change their order or even deleting them if they are not relevant to you.

  ![Screenshot showing the components of a naming convention](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/10.jpg)

And below the components and every other section of the tool, you can find a **Configuration** section, which allows you to export your configuration to JSON for backup and easy import/export later on if you need to revert back.

  ![Screenshot showing the configuration section](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/11.jpg)

In each component, you can add what is relevant to your organization from environments, functions ,...etc.

  ![Screenshot showing the environment component of a naming convention](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/12.jpg)

In the **Orgs** section, I will add two new Orgs; HR and Marketing and provide a short name for each to be used in the naming convention.

  ![Screenshot showing adding two new Orgs](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/13.jpg)

You can also configure the delimiters to be used in the naming convention as some resources allow certain delimiters and some don't allow delimiters at all like Storage Accounts.

  ![Screenshot showing adding delimiters](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/14.jpg)

The **Reference** section allows you to select an Azure Resource from the dropdown and provides examples of how the naming convention will look like based on the configuration you provided.

  ![Screenshot showing naming convention reference](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/15.jpg)

After finishing the configuration, let's try to generate a new name using the tool.

  ![Screenshot showing generating a name](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/16.gif)

>NOTE
>You can see that I got some errors while generating the name. Most resouces have a maximum characters count, so you will see the tool designate some components as OPTIONAL.

Going through the tool using the UI is great but its manual and you might already have some CI/CD pipeline for creating your Azure resources so consuming this tool using an API will be much more suitable. In the homepage of the tool you can see there is an API swagger page that references all of the available endpoints you can consume.

  ![Screenshot showing the homepaage of the naming tool](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/17.jpg)

  ![Screenshot showing swagger API documentation](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/18.jpg)

## Deploying the Azure Naming Tool on Azure Web Apps

We have experimented with the tool locally, so let's now deploy it on Azure as a Web App to make it more production-ready.

Sine this tool is available as a containerized image, we need to create an Azure Container Registry to be able to store the image.

  ![Screenshot showing an Azure Container registry](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/19.jpg)

>TIP
>Do not forget to enable the Admin user

  ![Screenshot showing Azure Container registry with the admin user enabled](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/20.jpg)

Before pushing the image, I need to tag it with the login server of the Azure Container Registry.

  ```bash
  docker tag azurenamingtool acrcafnamingtool.azurecr.io/azurenamingtool:v1
  ```

  ```bash
  docker push acrcafnamingtool.azurecr.io/azurenamingtool:v1
  ```

  ![Screenshot showing pushing the image to the Azure Container registry](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/21.jpg)

Remember the persistent volume we talked about earlier, now would be a good time to create it before deploying the tool. I will use an Azure File share in that scenario but you can use any other storage you prefer.

  ![Screenshot showing creating a new Azure file share](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/22.jpg)

Now we are ready to create the Web App, we need to select **Docker Container** as the publish method, and provide the Azure Container Registry and image details.

  ![Screenshot showing creating a new web app from the Azure Portal](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/23.jpg)

  ![Screenshot showing creating a new web app and providing the container registry details](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/24.jpg)

After creating the Web App, we need to provide the volume configuration to use the Azure File Share we created earlier to mount it to the */app.settings* path in the container.

  ![Screenshot showing adding the file share as a volume to the web app](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/25.jpg)

Finally, trying to browse to the Web App URL.

  ![Screenshot showing the tool deployed on azure web app](https://images.seifbassem.com/images/Posts/Azure-Naming-Tool/26.jpg)

## Resources

- Cloud Adoption Framework naming convention guidance can be found [here](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- The GitHub repo for the Azure naming tool can be found [here](https://github.com/microsoft/CloudAdoptionFramework/tree/master/ready/AzNamingTool)
- You can install Docker Desktop from [here](https://www.docker.com/products/docker-desktop/)