---
title: "Estimate your Infrastructure-as-code costs before deploying"
images:
  - "https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/banner.png"
date: 2022-07-03 17:08:42 +0200
tags: ["Azure","infrastructure as code","Terraform"]
categories: ["posts"]
draft: false
---

<!--more-->

I recently stumbled on a very useful API called [Infracost](https://www.infracost.io/), that allows you to estimate the cost of the resources that will be deployed by your Terraform code across Azure, AWS and GCP. You can get the cost estimates locally or even better, you can integrate with your CI/CD pipelines so with every pull request you can understand your cloud costs upfront and see how much the new changes will affect your bill before approving this pull request.

## Setting up Infracost locally

Since I'm using Windows, I will use Chocolatey to install Infracost.

 ```PowerShell
  choco install infracost
 ```

  ![Screenshot showing Infracost CLI](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/01.jpg)

Then, I need to register to get an API key.

  ![Screenshot showing registration for an API key](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/02.jpg)

Now, we are ready to try out the Infracost API. I have a sample Terraform code to create two virtual machines; a domain controller and a member server to joing this domain.

  [![Screenshot showing terraform code](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/03.jpg)](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/03.jpg#lightbox)

Running the Infracost CLI to get an estimate of the costs of the resources that will be created by our Terraform code.

  ```PowerShell
    infracost breakdown --path . --show-skipped
  ```

  ![Screenshot showing running the Infracost CLI to get cost estimate](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/04.jpg)

We can see it nicely breaks down the cost of our two virtual machines (calculating compute and disk) and public Ip address. Also at the end, it shows the free resources like virtual network, subnets and resources that are not yet supported by the API.

One other cool thing Infracost allows us to do is to create a baseline of our costs and then compare if we make any changes in the future to understand the drift that will happen in cost.

  ```PowerShell
    infracost breakdown --path . --format json --out-file infracost-base.json
  ```

  ![Screenshot showing running the Infracost CLI to get cost baseline](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/05.jpg)

Having our baseline saved, I'm going to modify the domain controller VM size and add a storage account to my Terraform code.

  ![Screenshot showing changing the VM size to F4s](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/06.jpg)

  ![Screenshot showing adding a storage account](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/07.jpg)

Running Infracost again to compare the changed against our baseline, we can see a breakdown of the changes to our infrastructure (old cost Vs new cost).

**New storage account costs**

  ![Screenshot showing adding a storage account](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/08.jpg)

**Virtual machine size change**

  ![Screenshot showing cost of new VM size](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/09.jpg)

**Monthly cost change**

  ![Screenshot showing cost of the monthly cost change](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/10.jpg)

## Integrating Infracost with CI/CD

Running Infracost is very useful to check your local code costs, but it can be more useful if it can integrate with our CI/CD pipelines for a more streamlines approach. Currently is has a variety of integrations with [different platforms](https://www.infracost.io/docs/integrations/cicd/). I will try the GitHub actions integration.

First step, is to generate a repository secret for Infracost.

  ![Screenshot showing creation of a repository secret](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/11.jpg)

The, we need to add an action yaml definition. The documentation are pretty good with a template you can use, you only need to change the location of your terraform code. Basically the GitHub action will do the following:

 - Authenticate to the Infracost API using the repository secret
 - Create a baseline cost estimate and saves it in a temporary file
 - Checks out the pull request branch
 - Create a diff with the cost changes compared to the baseline file

  ![Screenshot showing the action yaml](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/12.jpg)

After setting up our GitHub action, I will submit a new pull request with changes to the virtual machine size and OS disk type.

  ![Screenshot showing changing VM size and disk type](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/13.jpg)

  ![Screenshot showing the pull request details](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/14.jpg)

Once the pull request is submitted and GitHub action runs, I can see that Infracost shows me the cost changes I should expect if I approve the pull request with details on what has changed.

  ![Screenshot showing the pull request details](https://images.seifbassem.com/images/Posts/Iaac-Cost-Infracost/15.jpg)
