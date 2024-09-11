---
title: "Azure Verified Module - CICD self-hosted agents"
images:
  - "https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/banner.png"
date: 2024-09-10 17:08:42 +0200
tags: ["Azure","Bicep","Infrastructure-as-code","Azure-Landing-Zones"]
categories: ["posts"]
draft: false
---

<!--more-->

In the ever-evolving landscape of software development, the need for robust and efficient continuous integration (CI) and continuous delivery (CD) pipelines has become paramount. Self-hosted runners and agents play a crucial role in this context, particularly when using platforms like GitHub and Azure DevOps. These self-hosted solutions offer a unique blend of flexibility and control, allowing organizations to tailor their CI/CD workflows to meet specific requirements. Whether it's handling specialized build environments, integrating with proprietary tools, or managing complex dependencies, self-hosted runners provide the customization needed to streamline development processes and enhance productivity.

Security and compliance are other critical aspects where self-hosted runners and agents shine. By hosting runners on their own infrastructure, organizations can enforce stringent security measures and ensure compliance with industry standards and regulations. This level of control is especially important for enterprises dealing with sensitive data or operating in highly regulated sectors. Self-hosted runners allow for the implementation of advanced security protocols, such as network isolation, access controls, and encryption, thereby mitigating risks associated with third-party hosted solutions.

A new Azure verified pattern module has been published which helps you to easily deploy self-hosted runners and agents using infrastructure-as-code. Capabilities of this module are:

- Supports Azure Container Apps with auto scaling from zero
- Supports Azure Container Instances
- Supports Public or Private Networking
- Uses managed identity authentication
- Deploys all Azure resources required for the end to end solution or optionally supply your own resources

## Module usage

Let's explore how using this module will look like. In this scenario, I will use this module to deploy GitHub self-hosted runners on Azure Container Apps using public networking.

### GitHub Actions self-hosted runners

![Screenshot showing using the module to deploy GitHub runners on Azure container apps](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/02.gif)

#### Bicep code

```bicep
module githubRunner 'br/public:avm/ptn/dev-ops/cicd-agents-and-runners:0.1.0' = {
  name: 'githubRunner'
  params: {
    computeTypes: [
      'azure-container-app'
    ]
    namingPrefix: 'gh'
    networkingConfiguration: {
      addressSpace: '10.0.0.0/16'
      networkType: 'createNew'
      virtualNetworkName: 'vnet001'
    }
    selfHostedConfig: {
      githubOrganization: 'sebassem'
      githubRepository: 'private-runners'
      personalAccessToken: '*************************'
      selfHostedType: 'github'
    }
    privateNetworking: false
  }
}
```

After the deployment is complete, this is what gets deployed.

![Screenshot showing the resources deployed in azure](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/03.png)

Now, let's configure a sample GitHub action to utilize the self-hosted runners we deployed.

![Screenshot showing using creating a github action using self-hosted](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/04.png)

When running it, we can see the action using our self-hosted runners on top of Azure Container apps.

![Screenshot showing the action running using the self-hosted runner](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/05.png)

![Screenshot showing the azure container apps job](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/06.png)

Looking at the Azure Container App, we can see that its configured to scale down to zero to save costs when there are no actions triggered.

![Screenshot showing the scaling configuration of Azure Container apps](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/07.png)

### Azure DevOps self-hosted runners

Now let's try to deploy Azure DevOps on Azure Container Instances with private networking this time.

![Screenshot showing the scaling configuration of Azure Container apps](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/08.gif)

#### Bicep code

```Bicep
module azureDevOpsAgent 'br/public:avm/ptn/dev-ops/cicd-agents-and-runners:0.1.0' = {
  name: 'azureDevOps'
  params: {
    computeTypes: [
      'azure-container-instance'
    ]
    namingPrefix: 'dev'
    networkingConfiguration:  {
      addressSpace: '10.0.0.0/16'
      networkType: 'createNew'
      virtualNetworkName: 'vnet002'
    }
    selfHostedConfig: {
      agentsPoolName: 'aci-pool'
      devOpsOrganization: 'sebassem0787'
      personalAccessToken: '*********************'
      selfHostedType: 'azuredevops'
    }
    privateNetworking: true
  }
}
```

After the deployment is complete, this is what gets deployed. This time we can see additional resources getting deployed as we chose to deploy with private networking like private endpoints, private dns zones and a nat gateway.

![Screenshot showing the resources deployed in azure](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/09.png)

Now, let's configure a sample Azure DevOps pipeline to utilize the self-hosted runners we deployed. First, we need to create an agent pool named `aci-pool`.

![Screenshot showing creating an agent pool named aci-pool](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/10.png)

The, we need to edit the pipeline yaml to utilize that pool.

![Screenshot showing editing the pipeline yaml](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/11.png)

When running it, we can see the pipeline using our self-hosted agent on top of Azure Container Instances this time.

![Screenshot showing the action running using the self-hosted runner](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/12.png)

Looking at the Azure Container Instance deployed, we can see that indeed a container was spun up, ran and then got terminated.

![Screenshot showing Azure container instance configuration](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/13.png)

And finally looking at the agent pool settings, we can see the self-hosted agent in our configuration and the pipeline we ran as a job on that agent.

![Screenshot showing Agent pool configuration](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/14.png)

![Screenshot showing a job running on our agent pool](https://images.seifbassem.com/images/Contributions/cicd-runners-and-agents/15.png)

## Resources

- [Bicep Azure Verified module for self-hosted runners and agents](https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/dev-ops/cicd-agents-and-runners)
- [Terraform Azure Verified module for self-hosted runners and agents](https://github.com/Azure/terraform-azurerm-avm-ptn-cicd-agents-and-runners)