---
title: "Test your GitHub actions locally on your dev machine"
images:
  - "https://images.seifbassem.com/images/Posts/Test-github-actions-locally/banner.png"
date: 2023-09-23 17:08:42 +0200
tags: ["Azure","Github","DevOps","Bicep"]
categories: ["posts"]
draft: true
---

<!--more-->

I recently stumbled upon The "Act" project, this is a powerful tool that enables users to run GitHub Actions locally on their own machines. GitHub Actions is a popular workflow automation tool provided by GitHub, allowing developers to automate various tasks and processes within their software projects. However, sometimes it's necessary to test and debug these actions locally before committing and pushing changes to the repository.

There are many benefits to using Act, including:

**Faster feedback loop:** With Act, you can test your GitHub Actions workflows locally without having to push your changes to GitHub. This can save you a lot of time and frustration, as you can quickly identify and fix any problems with your workflows before you deploy them to production.

**Reduced resource usage:** GitHub Actions workflows can be resource-intensive, especially if you are using complex workflows or running them frequently. By testing your workflows locally with Act, you can reduce the amount of resources that you are using on GitHub's runners.

**Improved development workflow:** Act can help you to improve your development workflow by making it easier to test and debug your GitHub Actions workflows. This local testing capability ultimately helps streamline the development process, ensuring the reliability and effectiveness of GitHub Actions before they are deployed to the production environment.

Let's give it a spin and see how it works.

## Setup

- Act relies on having _Docker Desktop_ on windows, we can use _Winget_ to install it.

```shell
winget install -e --id Docker.DockerDesktop
```

- We can also install Act using _winget_.

```shell
winget install nektos.act
```

![Screenshot showing installing act using winget](https://images.seifbassem.com/images/Posts/Test-github-actions-locally/01.png)

## Act features

- GitHub actions use runners to execute your workflows, act provides you with default runners that almost have the same software installed as the GitHub runners but it allows you to use your own runner images.
- When running Act by default, it will run all workflows with a _push_ trigger. You can customize that to select different triggers. For example, running all workflows with a _pull_request_ trigger.

```shell
act pull_request
```

- By default, it will also run all jobs in a workflow, but you can select to run just one job.

```shell
act -j 'Login to Azure'
```

- Usually, you would have GitHub actions secrets passed to your workflows. You can do the same locally with act by either providing the secrets inline or pass them in a secrets/env file.

```shell
act -secret-file .\secrets.env
```

> **NOTE: There are much more features and some limitations to be aware of, will include all information in the references section**

## Run a local GitHub action workflow

- I'm going to create a simple workflow to use in this demo. The workflow will login to Azure using cli, lint some bicep code that creates a storage account, run a _what-if_ deployment. I will provide the Azure credentials as secrets as well.

```python
name: "Validate Bicep code"

on:
  push:
    branches:
      - main
  workflow_dispatch: {}

permissions:
  id-token: write
  contents: write
  pull-requests: write

jobs:
  Lint-and-preview:
    name: "Lint-and-preview"
    runs-on: ubuntu-latest
    env:
      RESOURCE_GROUP: "bicep-rg"

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Manually install Azure CLI
        uses: pietrobolcato/install-azure-cli-action@main

      - name: "Az CLI login"
        uses: azure/login@v1
        with:
          creds: '{"clientId":"${{ secrets.AZURE_CLIENT_ID }}","clientSecret":"${{ secrets.AZURE_CLIENT_SECRET }}","subscriptionId":"${{ secrets.AZURE_SUBSCRIPTION_ID }}","tenantId":"${{ secrets.AZURE_TENANT_ID }}"}'

      - name: Bicep Lint
        run: az bicep build --file src/main.bicep

      - name: "What-If"
        run:  az deployment group what-if --resource-group "${{ env.RESOURCE_GROUP }}" --name whatif-${{ github.run_id }} --template-file src/main.bicep --result-format ResourceIdOnly
```

> **NOTE: I'm using a custom "Install Azure CLI" action as of the latest version when I wrote this, there is a bug there Azure CLI doesn't get installed on the runner**

- I already have some GitHub actions secrets defined in my repo to be able to authenticate to Azure. I will create an .env file to have the same secrets to be able to use them locally with act.

![Screenshot showing github secrets](https://images.seifbassem.com/images/Posts/Test-github-actions-locally/02.png)

![Screenshot showing github secrets locally](https://images.seifbassem.com/images/Posts/Test-github-actions-locally/03.png)

- Testing my workflow first on GitHub, I can see it is working and running a _what-if_ deployment for my bicep code.

![Screenshot showing running the github action](https://images.seifbassem.com/images/Posts/Test-github-actions-locally/04.png)

- When running Act the first time, you will have to choose the default runner image to use. Depending on what tools and software you need pre-installed, select the right image for you. I will select the medium one since the large is 20+ GB 😧.

![Screenshot showing selecting the runner image](https://images.seifbassem.com/images/Posts/Test-github-actions-locally/05.png)

- Let's now try to run this workflow locally.

```shell
act -W '.\.github\workflows\bicep-validate.yaml' --secret-file .\.env
```

![Screenshot showing runner act](https://images.seifbassem.com/images/Posts/Test-github-actions-locally/06.png)

- After the workflow runs, I can see that my _what-if_ deployment has run successfully on my bicep code, showing that a storage account will be created.

![Screenshot showing runner act completed](https://images.seifbassem.com/images/Posts/Test-github-actions-locally/07.png)

## Recap

As we've seen in the demo, _Act_ allows you quickly test/debug a worklow locally, running the whole thing or just a couple of jobs before pushing it to GitHub. This allows faster time to troubleshooting and validating your actions before pushing to a production environment.

### Resources

- Act GitHub repository : [https://github.com/nektos/act](https://github.com/nektos/act)