---
title: "Continuously deploy your infrastructure via Bicep and azd"
images:
  - "https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/banner.png"
date: 2023-12-25 17:08:42 +0200
tags: ["Azure","Azure Developer CLI","Bicep"]
categories: ["posts"]
draft: false
---

<!--more-->

In this post, I will go through how the Azure Developer CLI (azd) can help you automate the deployment of infrastructure on Azure and create a deployment pipeline on GitHub so you can continuously deploy those resources while tracking changes.

## Overview

The Azure Developer CLI (azd) is an open-source tool that helps developers accelerate the time it takes to get their application from local development environment to Azure. It provides a set of best practice, developer-friendly commands that map to key stages in your workflow, whether you’re working in the terminal, your editor or integrated development environment (IDE), or CI/CD (continuous integration/continuous deployment). You can use azd with extensible blueprint templates that include everything you need to get an application up and running on Azure. These templates include reusable infrastructure as code assets and proof-of-concept application code that can be replaced with your own app code.

You can also create your own templates or find ones to build upon. Once you’ve installed Azure Developer CLI, you can get your app running on Azure in just a few steps: select an Azure Developer CLI template, initialize the project with the template by running azd init, package, provision and deploy the app by running azd up, and continue iterating on your application code and deploying changes as needed by running azd deploy. Azure Developer CLI is a useful tool for developers who want to streamline their workflow and deploy their applications to Azure more efficiently.

> NOTE: Check out [this previous post](https://www.seifbassem.com/blogs/posts/azure-developer-cli/) for more context on how useful it is to use azd with bicep.

## Setup

In this demonstration, I will simply deploy a storage account to Azure using bicep. I will first create the template folder structure for azd.

```md

├── .devcontainer                                [ For DevContainer ]
├── .github                                      [ Configures a GitHub workflow ]
├── .vscode                                      [ VS Code workspace configurations ]
├── .azure                                       [ Stores Azure configurations and environment variables ]
├── infrastructure                               [ Contains infrastructure as code files ]
│   ├── main.bicep                               [ Main infrastructure file ]
│   ├── main.parameters.json                     [ Parameters file ]
└── azure.yaml                                   [ Describes the app and type of Azure resources]
```

![Screenshot showing folder structure](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/01.png)

I will add a very simple storage account bicep deployment to represent the Azure infrastructure.

![Screenshot showing bicep code for the storage account](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/02.png)

Then, I will [download the sample GitHub action](https://github.com/Azure-Samples/azd-starter-bicep/blob/main/.github/workflows/azure-dev.yml) available in any azd template and add it to my "*.github/workflows*" folder.

![Screenshot showing the github action](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/03.png)

And finally, my *azure.yaml* file which azd needs to understand my Azure infrastructure and application (if any). As you can see, I only specify where my bicep code is located which is in the *infrastructure* folder.

>NOTE: The bicep folder needs to contain also a parameters file for azd to be able to deploy the infrastructure.

![Screenshot showing azure.yaml](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/04.png)

## Deployment

Once everything is in place in my directory. I will only need to run `azd pipeline config` to do the following:

![Screenshot showing running azd pipeline config](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/05.png)

- Initialize my current directory as a git repository.

![Screenshot showing initializing local repo as a Git repository](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/06.png)

- Create or use an existing GitHub remote repository.

![Screenshot showing creation of a new GitHub repo](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/07.png)

- Create an Azure service principal and configure GitHub authentication to be able to deploy to Azure.

![Screenshot showing creation of a new GitHub repo](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/08.png)

- Configure needed GitHub secrets on the repository.

![Screenshot showing creation GitHub secrets](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/09.png)

![Screenshot showing command complete](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/10.png)

![Screenshot showing created GitHub repository](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/11.png)

Now, checking my GitHub actions runs, I can see that the workflow has indeed ran but there is an error. I'm using azd to deploy to a resource group which at the time of this post is still a preview feature. To fix that, I had to edit the workflow to enable this feature.

![Screenshot showing error running the workflow](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/12.png)

![Screenshot showing adding the resource group preview feature](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/13.png)

Once fixed, the workflow has executed successfully and my storage account is deployed.

![Screenshot showing successful workflow run](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/14.png)

![Screenshot showing successful storage account deployment](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/15.png)

Note that the TLS version used in the storage account is 1.0 which is not the most secure. So let's use the pipeline created by azd to change that instead of directly going to the portal.

All I need to do is to create a new branch, add the *minimumTLSVersion* property to my code and push my changes to GitHub and azd auto-magically will take this all the way to Azure.

![Screenshot showing configuring the tls version in Bicep](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/16.png)

Create a new pull request. Here you can add all kind of checks, scans or tests you would like to have a proper pipeline according to your organization's policies.

![Screenshot showing the changed files in the pull request](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/17.png)

Now, after merging the pull request. I can see my workflow has started to run.

![Screenshot showing merging the pull request](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/18.png)

![Screenshot showing the GitHub workflow running](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/19.png)

Finally, the storage account has been updated to use the 1.2 TLS version successfully.

![Screenshot showing the updated TLS version on azure](https://images.seifbassem.com/images/Posts/Bicep-continous-deployment-azd/20.png)

## References

- Intro to _azd_

<figure class="video_container">
 <iframe width="560" height="315" src="https://www.youtube.com/embed/9z3PiHSCcYs" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
</figure>

- [azd documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview)
- [Configure a pipeline with azd](https://learn.microsoft.com/azure/developer/azure-developer-cli/configure-devops-pipeline?tabs=GitHub)
