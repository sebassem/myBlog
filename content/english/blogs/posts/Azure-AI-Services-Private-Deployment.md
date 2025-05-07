---
title: "Simplifying private deployment of Azure AI services using AVM"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/banner.png"
date: 2025-05-06 17:08:42 +0200
tags: ["Azure","AI","IaaC","Bicep","Security"]
categories: ["posts"]
draft: false
---

<!--more-->

I recently worked with a couple of customers on designing an architecture for their AI solutions on Azure utilizing the different Azure AI services (AI Foundry, Azure OpenAI service, AI Search,...etc) where I got a chance to explore those services more closely and understand how to deploy them securely after multiple attempts and lots of documentation scanning.

In this blog post, I will walk you through my experience on how to deploy Azure AI services using Bicep in a locked down manner and how to simplify the code using Azure Verified Modules (AVM).

## AI AI AI

![Screenshot showing a meme about AI](https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExMWNkaWYydWo2b2VmZWhucGozMDAxc284NGNzcmF1aWVycGJnNjFqZyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/MZ2mzOCVZqltHCCxcR/giphy.gif)

Ever since ChatGPT went mainstream and cloud providers started rolling out their own enterprise AI platforms, everyone’s been racing to bring AI into their apps and workflows. Microsoft, in particular, has made Azure the go-to platform for enterprise AI, with offerings like Azure OpenAI Service, Copilot Studio, Azure AI Foundry, Azure AI Search, and an expanding suite of Copilots and agents. Whether it’s improving customer support, automating internal tasks, or building smarter apps, companies are betting big on AI to boost productivity and unlock new value. But as fast as this adoption is moving, it also brings a new set of responsibilities—especially when it comes to security and compliance.

AI isn’t just another app feature. It interacts with sensitive data, generates content dynamically, and opens up new attack surfaces like prompt injection, data leakage, model misuse, to name a few. Azure provides tools and practices like Defender for Cloud, Purview, Policy enforcement, managed identities, private endpoints and more. Secure AI adoption isn’t just about enabling services; it’s about baking security and compliance into every part of the architecture from day one.

## High level concepts

When it comes to Azure, there are lots of AI services that can help enterprises build their AI solutions, let's explore those services and what each can do so when we switch to the demo, its clear how each component interacts with each other:

### **Azure OpenAI Service**

Azure OpenAI Service is a deployment model tailored for applications that require access to OpenAI's advanced language models, such as GPT-4, GPT-4o, o-series models and more, all within the secure and compliant Azure environment. This integration allows developers to build applications that leverage natural language understanding, code generation, image creation, and speech-to-text capabilities. By offering enterprise-grade security, scalability, and compliance. You would usually use this deployment model if you are just focused on using Azure OpenAI models.

### **Azure AI Services**

Azure AI Services is another deployment model which offers a broader range of AI capabilities beyond language models, encompassing services like computer vision, speech recognition, and decision-making. It provides access to various AI services, including Azure OpenAI, content safety, speech, vision, and more, facilitating the development of diverse intelligent applications.

### **Azure AI Search**

Azure AI Search is an enterprise-grade search solution that combines traditional keyword search with advanced AI capabilities like semantic search and vector-based retrieval. It allows developers to build rich search experiences and generative AI applications that understand user intent and context. If your application requires an enterprise-level Retrieval-Augmented Generation (RAG) solution, then AI Search would be the best fit.

### **Azure AI Foundry (Formerly Azure AI Studio)**

Azure AI Foundry is a comprehensive platform designed for developers and IT administrators to design, customize, and manage AI applications and agents. It offers a rich set of AI capabilities and tools through a unified portal, SDK, and APIs, facilitating secure data integration, model customization, and enterprise-grade governance. This is the main one stop-shop for developing AI solutions on top of Azure. Regardless of which model from above you would deploy, AI Foundry will be the main portal to help you configure, customize and consume your AI services. There are two main concepts within Foundry:

   ![Screenshot showing AI Foundry architecture](https://learn.microsoft.com/azure/ai-foundry/media/concepts/ai-studio-architecture.png)

   ![Screenshot showing AI Foundry Hub components](https://learn.microsoft.com/azure/ai-foundry/media/concepts/resource-provider-connected-resources.svg)

#### **Azure AI Foundry Hub**

An Azure AI Foundry Hub is based on the Azure Machine Learning service and it serves as the central resource for managing security, connectivity, and computing resources across multiple projects within an organization. It enables teams to govern and share resources efficiently, ensuring consistent configurations and compliance across various AI initiatives.

#### **Azure AI Foundry Project**

An Azure AI Foundry Project is a child resource of the hub and it acts as the workspace where developers and data scientists build, customize, test, and deploy AI models and applications. Projects allow for the integration of various AI services, model training, and evaluation within a governed environment. It's also based on the Azure Machine Learning service.

### **Azure Verified modules (AVM)**

Azure Verified Modules are pre-built, validated Bicep/Terraform modules developed, maintained and supported by Microsoft to simplify and standardize the deployment of Azure resources and patterns. These modules encapsulate best practices from the Azure Well-Architected Framework, enabling users to deploy secure, reliable, and scalable infrastructure as code with minimal effort. By abstracting complex configurations—such as private endpoints, role assignments, diagnostic settings, and more, these modules reduce boilerplate code, enhance readability, and ensure consistency across environments. We will use AVM modules in our architecture to simplify our code.

## Solution architecture

Let's assume we want to build an enterprise-level AI solution that leverages Azure OpenAI models and AI Search capabilities to create a chatbot on top of the enterprise data. We also need to provide developers with isolated workspaces to consume those resources securely to build their applications. Let's break down what we need to think about from a security perspective to achieve that goal:

### Networking

First thing to consider is how to lock down networking since all of the above are PaaS resources with public endpoints. We need to deploy them in a private network using private endpoints to lock them down, prevent access through their private endpoints and control ingress/egress traffic.

   ![Screenshot showing private deployment of AI Services](https://learn.microsoft.com/azure/ai-foundry/media/how-to/network/azure-ai-network-outbound.svg)

#### AI Foundry Hub

AI Foundry Hub has an option to be deployed into a managed virtual network which allows for the private deployment of the compute resources used by this machine learning workspace and lets you control the inbound and outbound traffic to the internet and/or other resources like Azure OpenAI, AI Search, Storage Accounts and more. You can deploy it in 3 modes:

- **"Allow internet outbound":** Allow all internet outbound traffic from the managed virtual network.
- **"Allow only approved outbound":** Outbound traffic is allowed by specifying service tags to specific services and endpoints. In this mode, you must add rules for each outbound connection you want to allow.
- **"Disabled:"** Inbound and outbound traffic aren't restricted.

The Hub also requires some Azure services like a Storage Account, a Key Vault and a container registry, they can be created by the Hub or you can provide existing ones. We will deploy all of them privately as well.

For the Hub to securely connect to the different AI services, we can configure shared privateLink resources to the different AI services. This will allow us to securely connect to them via the private endpoints. This also allows us to not require allowing Azure trusted services which can be a security concern for some customers.

> **Note:** Trusted services will still be required to be enabled on Azure AI Search service

Once we deploy the Hub using private networking, any child project will inherit this private configuration so we don't need to explicitly configure private endpoints for each project.

#### Azure OpenAI or Azure AI Services

Both deployment models are types of the Azure Cognitive Account resource, so their configuration is mainly the same when it comes to private networking. We will need to disable public access and deploy a private endpoint.

#### Azure AI Search

For Azure AI Search, we will also need to:

- Disable public access
- Deploy a private endpoint
- Configure shared privateLink resources to both Azure OpenAI/AI Service resource and any Storage Account we will host data in. This will allow for secure connection via the private endpoints. This step will create additional private endpoints in the Azure OpenAI/AI service and Storage Account that needs to be approved to allow those secure connections.

When deploying AI Search privately, any indexer created needs a manual step to configure this indexer to execute in this private environment. We need to edit the JSON of this indexer to add the `"executionEnvironment": "private"` property, otherwise the indexer will always fail when it runs.

```json
{
    "name": "indexer",
    "dataSourceName": "blob-datasource",
    "targetIndexName": "index",
    "parameters": {
        "configuration": {
            "executionEnvironment": "private"
        }
    },
    "fieldMappings": []
}
```

#### Azure Storage Account

We will need to deploy a storage account to be available as a blob storage for the foundry Hub so we can ingest data that can be indexed via Azure AI Search. We will need to disable public access and deploy two private endpoints; one for blob and one for file. We will also disable the shared access key as we want to only use identity-based authentication.

#### Private DNS Zones

Since we are deploying all resources privately via private endpoints, we will need to create and link some private DNS zones to our virtual network so our services are registered into those zones and we can resolve them inside of our virtual network.

| Service | Private DNS Zone |
|---------|-----------------|
| **Azure AI Foundry** | |
| | privatelink.api.azureml.ms |
| | privatelink.notebooks.azure.net |
| **Azure AI Services** | |
| | privatelink.openai.azure.com |
| | privatelink.cognitiveservices.azure.com |
| **Azure AI Search** | |
| | privatelink.search.windows.net |
| **KeyVault** | |
| | privatelink.vaultcore.azure.net |
| **Blob Storage** | |
| | privatelink.blob.core.windows.net |
| | privatelink.file.core.windows.net |
| **Azure Container Registry** | |
| | privatelink.azurecr.io |

#### Jumpserver

Since we will lockdown all of our Azure services to a virtual network using private endpoints, we will need to deploy a jump server in the same network to allow admins and developers to securely connect to those services for configuration, troubleshooting, testing,...etc. We will deploy a simple virtual machine without any public IP address and use Azure Bastion to securely RDP into it.

### Identity

- When it comes to identity, we will enable managed identities for each PaaS service we deploy to be able to connect securely to each service without the hassle of managing credentials. We can use system-assigned or user-assigned identities to grant RBAC roles, in this scenario we will use system-assigned. Each of the services we will deploy will require some roles on other services to allow for seamless and secure communication. Required roles can be found [here](https://learn.microsoft.com/azure/ai-services/openai/how-to/on-your-data-configuration#role-assignments). We will use Entra ID groups to manage those identities and centrally assign roles.

>**NOTE:** Role assignments are needed for the managed identities so services can securely connect to each other and also for developers' accounts accessing and consuming those services.

- For each PaaS service, we will use Entra ID authentication instead of local authentication. This will be achieved by setting the `disableLocalAuth` property to true.

- To configure Azure AI Foundry Hub to interact with the different AI services, there is the concept of connections which allows it to bring in resources like Azure OpenAI, AI Services, AI Search, Blob storage and more. Connections can be created using either API Keys or Entra ID so following best practices, we will create connections using Entra ID as the authentication method.

### Secrets

Most of the AI services we will deploy have some secrets, like API Keys, endpoints,...etc so we will need to also secure access to those secrets and for that, we will use KeyVault. The Azure Verified Modules for those resources makes this a breeze via an existing property called `secretsExportConfiguration`.

## Building our solution using AVM

Let's start to build and configure each component.

### Variables and parameters

We will define a parameters for the models we want to deploy.

   ```python
   param models = [
     {
           name: 'text-embedding-ada-002'
           model: {
             format: 'OpenAI'
             name: 'text-embedding-ada-002'
             version: '2'
           }
           sku: {
             name: 'Standard'
             capacity: 10
           }
     }
     {
       name: 'gpt0-4-mini'
           model: {
             format: 'OpenAI'
             name: 'gpt-4o-mini'
             version: '2024-07-18'
           }
           sku: {
             name: 'GlobalStandard'
             capacity: 10
           }
     }
   ]
   ```

We will define all the private DNS zones we need as variables.

   ```python
   var aiPrivateDNSZones = [
     {
       name: 'cognitiveSvcsPrivateDnsZone'
       zone: 'privatelink.cognitiveservices.azure.com'
     }
     {
       name: 'openAIPrivateDnsZone'
       zone: 'privatelink.openai.azure.com'
     }
     {
       name: 'aifoundryPrivateDnsZone'
       zone: 'privatelink.api.azureml.ms'
     }
     {
       name: 'aifoundryNotebookZone'
       zone: 'privatelink.notebooks.azure.net'
     }
     {
       name: 'aiSearchPrivateDnsZone'
       zone: 'privatelink.search.windows.net'
     }
   ]

   var storagePrivateDNSZonesArray = [
     {
       name: 'blobPrivateDnsZone'
       zone: 'privatelink.blob.${az.environment().suffixes.storage}'
     }
     {
       name: 'filePrivateDnsZone'
       zone: 'privatelink.file.${az.environment().suffixes.storage}'
     }
   ]

   var acrPrivateDNSZoneConfig = (acrPublicNetworkAccess == 'Disabled' && acrSku == 'Premium')
     ? [
         {
           name: 'acrPrivateDnsZone'
           zone: 'privatelink.azurecr.io'
         }
       ]
     : []

   var keyVaultPrivateDNSZoneConfig = [
     {
       name: 'keyVaultPrivateDnsZone'
       zone: 'privatelink.vaultcore.azure.net'
     }
   ]

   var privateDNSZonesArray = union(
     aiPrivateDNSZones,
     storagePrivateDNSZonesArray,
     acrPrivateDNSZoneConfig,
     keyVaultPrivateDNSZoneConfig
   )
   ```

### Networking resources

Defining the virtual network

   ```python
   module virtualNetwork 'br/public:avm/res/network/virtual-network:0.5.0' = {
     params: {
       name: virtualNetworkName
       location: location
       addressPrefixes: virtualNetworkAddressPrefix
       subnets: virtualNetworkSubnets
     }
   }
   ```

Defining the private DNS zones. We will use a loop to iterate through the variable array we created earlier.

   ```python
   module privateDNSZones 'br/public:avm/res/network/private-dns-zone:0.7.1' = [
     for privateDNSZone in privateDNSZonesArray: {
       name: privateDNSZone.name
       params: {
         name: privateDNSZone.zone
         location: 'global'
         virtualNetworkLinks: [
           {
             virtualNetworkResourceId: virtualNetwork.outputs.resourceId
           }
         ]
       }
     }
   ]
   ```

>**Note:** You can see how we can directly link the zones to the virtual network right from within the module without having to create another resource type

Defining the JumpServer networking components, like the network security group and the Bastion host.

   ```python
   module bastionHost 'br/public:avm/res/network/bastion-host:0.6.1' = {
     params: {
       name: 'bastionHost001-${environment}-${namingPrefix}'
       virtualNetworkResourceId: virtualNetwork.outputs.resourceId
       location: location
       skuName: bastionSKU
     }
   }

   module jumpServerNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.1' = {
     name: 'jumpServerNetworkSecurityGroup'
     params: {
       name: 'nsg-jumpServer-${location}-${environment}-${namingPrefix}'
       location: location
     }
   }
   ```

Defining the Jump server.

   ```python
   module jumpServer 'br/public:avm/res/compute/virtual-machine:0.14.0' = {
     name: 'jumpServer'
     params: {
       name: 'jsrv-${environment}-${namingPrefix}'
       adminUsername: windowsAdminUsername
       adminPassword: windowsAdminPassword
       managedIdentities: {
         systemAssigned: true
       }
       location: location
       imageReference: {
         offer: 'WindowsServer'
         publisher: 'MicrosoftWindowsServer'
         sku: '2022-datacenter'
         version: 'latest'
       }
       enableAutomaticUpdates: true
       extensionCustomScriptConfig: {
         enabled: true
         fileData: []
       }
       extensionCustomScriptProtectedSetting: {
         commandToExecute: 'powershell.exe -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(\\"https://community.chocolatey.org/install.ps1\\"));choco install vscode /y -Force;"'
       }
       roleAssignments: !empty(jumpServerLoginGroup)
         ? [
             {
               principalId: jumpServerLoginGroup
               principalType: 'Group'
               roleDefinitionIdOrName: '1c0163c0-47e6-4577-8991-ea5c82e286e4'
               description: 'Virtual Machine Administrator Login'
             }
           ]
         : null
       encryptionAtHost: false
       nicConfigurations: [
         {
           ipConfigurations: [
             {
               name: 'ipconfig01'
               subnetResourceId: filter(
                 virtualNetwork.outputs.subnetResourceIds,
                 subnetId => contains(subnetId, 'jumpServerSubnet')
               )[0]
               pipConfiguration: {}
             }
           ]
           nicSuffix: '-nic-01'
           enableAcceleratedNetworking: false
           networkSecurityGroupResourceId: jumpServerNetworkSecurityGroup.outputs.resourceId
         }
       ]
       osDisk: {
         caching: 'ReadWrite'
         diskSizeGB: 128
         managedDisk: {
           storageAccountType: 'Premium_LRS'
         }
       }
       osType: 'Windows'
       vmSize: jumpserverVMSize
       zone: 0
     }
   }
   ```

### Supporting resources

Next, we will deploy the supporting resources, like Storage Account for foundry, container registry and key vault.

#### Azure Container Registry

   ```python
   module acr 'br/public:avm/res/container-registry/registry:0.9.1' = {
     params: {
       name: 'acr${environment}${namingPrefix}001'
       location: location
       managedIdentities: {
         systemAssigned: true
       }
       acrAdminUserEnabled: false
       replications: []
       acrSku: acrSku
       anonymousPullEnabled: false
       publicNetworkAccess: acrPublicNetworkAccess
       zoneRedundancy: acrSku == 'Premium' ? 'Enabled' : 'Disabled'
       privateEndpoints: (acrPublicNetworkAccess == 'Disabled' && acrSku == 'Premium')
         ? [
             {
               name: 'acr-pe-${location}-${environment}-${namingPrefix}'
               subnetResourceId: filter(
                 virtualNetwork.outputs.subnetResourceIds,
                 subnetId => contains(subnetId, 'acrSubnet')
               )[0]
               location: location
               service: 'registry'
               privateDnsZoneGroup: {
                 privateDnsZoneGroupConfigs: [
                   {
                     privateDnsZoneResourceId: '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io'
                   }
                 ]
               }
             }
           ]
         : null
     }
   }
   ```

>**NOTE:** You can see how we define the private endpoint and private DNS configuration right within the module itself. If we were deploying without AVM, we would have needed additional 2-3 resources to achieve the same result.

#### Azure KeyVault

  ```python
  module keyVault 'br/public:avm/res/key-vault/vault:0.12.1' = {
    params: {
      name: 'kv${environment}${namingPrefix}${take(uniqueString(resourceGroup().id,location),3)}'
      location: location
      enableRbacAuthorization: true
      sku: 'standard'
      privateEndpoints: [
        {
          subnetResourceId: filter(
            virtualNetwork.outputs.subnetResourceIds,
            subnetId => contains(subnetId, 'keyVaultSubnet')
          )[0]
          service: 'vault'
          privateDnsZoneGroup: {
            privateDnsZoneGroupConfigs: [
              {
                privateDnsZoneResourceId: '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
              }
            ]
          }
        }
      ]
    }
  }
  ```

#### Azure Storage Account for AI Foundry

As we are creating the storage account, we are also assigning some role assignments within the module (we will assign roles to the 'azureOpenAIAdminGroup' Entra ID group). We are also creating two private endpoints, one for the blob service and one for the file service.

   ```python
   module azureAIfoundryStorageAccount 'br/public:avm/res/storage/storage-account:0.14.1' = {
     params: {
       name: 'foundrystg${environment}${namingPrefix}${take(uniqueString(deployment().name,location),4)}'
       allowBlobPublicAccess: false
       skuName: storageAccountSkuName
       allowSharedKeyAccess: false
       kind: 'StorageV2'
       blobServices: {
         containers: [
           {
             name: 'data'
             publicAccess: 'None'
           }
         ]
       }
       publicNetworkAccess: 'Disabled'
       roleAssignments: [
         {
           principalId: azureOpenAI.outputs.?systemAssignedMIPrincipalId ?? ''
           roleDefinitionIdOrName: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
           principalType: 'ServicePrincipal'
           description: 'Storage Blob Data Contributor'
         }
         {
           principalId: azureOpenAIAdminGroup
           roleDefinitionIdOrName: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
           principalType: 'Group'
           description: 'Storage Blob Data Contributor'
         }
       ]
       privateEndpoints: [
         {
           name: 'stg-pe-${location}-${environment}-${namingPrefix}'
           subnetResourceId: filter(
             virtualNetwork.outputs.subnetResourceIds,
             subnetId => contains(subnetId, 'storageSubnet')
           )[0]
           location: location
           service: 'blob'
           privateDnsZoneGroup: {
             privateDnsZoneGroupConfigs: [
               {
                 privateDnsZoneResourceId: '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.${az.environment().suffixes.storage}'
               }
             ]
           }
         }
         {
           name: 'hub-stg-file-pe-${location}-${environment}-${namingPrefix}'
           subnetResourceId: filter(
             virtualNetwork.outputs.subnetResourceIds,
             subnetId => contains(subnetId, 'storageSubnet')
           )[0]
           location: location
           service: 'file'
           privateDnsZoneGroup: {
             privateDnsZoneGroupConfigs: [
               {
                 privateDnsZoneResourceId: '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.file.${az.environment().suffixes.storage}'
               }
             ]
           }
         }
       ]
     }
   }
   ```

### AI services

Deploying the Azure OpenAI service or AI services.

   ```python
   module azureOpenAI 'br/public:avm/res/cognitive-services/account:0.10.2' = {
     params: {
       name: 'openai${namingPrefix}${environment}${location}'
       kind: deployAIServices ? 'AIServices' : 'OpenAI'
       location: location
       managedIdentities: {
         systemAssigned: true
       }
       disableLocalAuth: true
       publicNetworkAccess: 'Disabled'
       deployments: models
       roleAssignments: [
         {
           principalId: azureOpenAIAdminGroup
           roleDefinitionIdOrName: 'a001fd3d-188f-4b5d-821b-7da978bf7442'
           principalType: 'Group'
           description: 'Cognitive Services OpenAI Contributor'
         }
       ]
       customSubDomainName: 'openai${namingPrefix}${environment}${location}'
       secretsExportConfiguration: {
         keyVaultResourceId: keyVault.outputs.resourceId
         accessKey1Name: 'openai-access-key1'
         accessKey2Name: 'openai-access-key2'
       }
       privateEndpoints: [
         {
           name: 'openAi-pe-${location}-${environment}-${namingPrefix}'
           subnetResourceId: filter(
             virtualNetwork.outputs.subnetResourceIds,
             subnetId => contains(subnetId, 'openAISubnet')
           )[0]
           location: location
           service: 'account'
           privateDnsZoneGroup: {
             privateDnsZoneGroupConfigs: [
                   {
                     privateDnsZoneResourceId: '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com'
                   }
                   {
                     privateDnsZoneResourceId: '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.cognitiveservices.azure.com'
                   }
                 ]
           }
         }
       ]
     }
   }
   ```

>**NOTE:** Note how we securely export the Azure OpenAI service secrets to KeyVault seamlessly within the module using the `secretsExportConfiguration` property.

Deploying the Azure AI search service.

   ```python
   module aiSearch 'br/public:avm/res/search/search-service:0.10.0' = {
     params: {
       name: 'aisearch${namingPrefix}${environment}'
       location: location
       managedIdentities: {
         systemAssigned: true
       }
       sku: 'standard2'
       secretsExportConfiguration: {
         keyVaultResourceId: keyVault.outputs.resourceId
       }
       disableLocalAuth: true
       publicNetworkAccess: 'Disabled'
       roleAssignments: [
         {
           principalId: azureOpenAI.outputs.?systemAssignedMIPrincipalId ?? ''
           roleDefinitionIdOrName: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
           principalType: 'ServicePrincipal'
           description: 'Search Index Data Reader'
         }
         {
           principalId: azureOpenAI.outputs.?systemAssignedMIPrincipalId ?? ''
           roleDefinitionIdOrName: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
           principalType: 'ServicePrincipal'
           description: 'Search Service Contributor'
         }
         {
           principalId: azureOpenAIAdminGroup
           principalType: 'Group'
           roleDefinitionIdOrName: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
           description: 'Search Service Contributor'
         }
       ]
       networkRuleSet: {
         bypass: 'AzureServices'
       }
       sharedPrivateLinkResources: [
         {
           privateLinkResourceId: azureAIfoundryStorageAccount.outputs.resourceId
           groupId: 'blob'
           resourceRegion: azureAIfoundryStorageAccount.outputs.location
           status: 'Approved'
           requestMessage: 'Please approve the private endpoint connection for the storage account.'
         }
         {
           privateLinkResourceId: azureOpenAI.outputs.resourceId
           groupId: 'openai_account'
           resourceRegion: azureOpenAI.outputs.location
           status: 'Approved'
           requestMessage: 'Please approve the private endpoint connection for the Azure OpenAI account.'
         }
         {
           privateLinkResourceId: azureOpenAI.outputs.resourceId
           groupId: 'cognitiveservices_account'
           resourceRegion: azureOpenAI.outputs.location
           status: 'Approved'
           requestMessage: 'Please approve the private endpoint connection for the Azure OpenAI account.'
         }
       ]
       privateEndpoints: [
         {
           name: 'aiSearch-pe-${location}-${environment}-${namingPrefix}'
           service: 'searchService'
           privateDnsZoneGroup: {
             privateDnsZoneGroupConfigs: [
               {
                 privateDnsZoneResourceId: '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.search.windows.net'
               }
             ]
           }
           subnetResourceId: filter(
             virtualNetwork.outputs.subnetResourceIds,
             subnetId => contains(subnetId, 'openAISubnet')
           )[0]
         }
       ]
     }
   }
   ```

>**Note:** You can see how we securely connect AI Search to other services like Azure OpenAI and blob services using `sharedPrivateLinkResources`. This will create additional private endpoints on those services that we will have to approve.

Approving the private endpoints created by AI Search.

   ![Screenshot showing approving Azure OpenAI private endpoints](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/02.png)

   ![Screenshot showing approving Storage account private endpoints](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/03.png)

Deploying AI Foundry Hub. A couple of things to note here:

- We set the isolationMode to `AllowInternetOutbound` which allows all internet outbound. To lock things more, we can set it to `AllowOnlyApprovedOutbound` which will deploy an Azure Firewall in the backend so we can whitelist the outbound connections.
- We configure the `connections` property to set the different Azure AI services that will connect to our Foundry Hub.
- We set `provisionNetworkNow` to true which will provision the managed network. This also will be automatically triggered once a compute resource is created or you manually provision the managed network using PowerShell/Azure CLI.

   ```python
   module azureAIfoundry 'br/public:avm/res/machine-learning-services/workspace:0.12.0' = {
     params: {
       name: 'foundry${environment}${namingPrefix}'
       sku: 'Standard'
       kind: 'Hub'
       publicNetworkAccess: 'Disabled'
       associatedKeyVaultResourceId: keyVault.outputs.resourceId
       associatedStorageAccountResourceId: azureAIfoundryStorageAccount.outputs.resourceId
       associatedApplicationInsightsResourceId: azureAIfoundryAppInsights.outputs.resourceId
       systemDatastoresAuthMode: 'Identity'
       roleAssignments: [
         {
           principalId: deployerPrincipal
           roleDefinitionIdOrName: 'e503ece1-11d0-4e8e-8e2c-7a6c3bf38815'
           principalType: 'User'
           description: 'AzureML Compute Operator'
         }
         {
           principalId: deployerPrincipal
           roleDefinitionIdOrName: 'f6c7c914-8db3-469d-8ca1-694a8f32e121'
           principalType: 'User'
           description: 'AzureML Data Scientist'
         }
       ]
       location: location
       managedIdentities: {
         systemAssigned: true
       }
       managedNetworkSettings: {
         isolationMode: 'AllowInternetOutbound'
       }
       sharedPrivateLinkResources: [
         {
           name: 'OpenAI'
           properties: {
             groupId: 'account'
             privateLinkResourceId: azureOpenAI.outputs.resourceId
             status: 'Approved'
             resourceRegion: location
           }
         }
         {
           name: 'blob'
           properties: {
             groupId: 'blob'
             privateLinkResourceId: azureAIfoundryStorageAccount.outputs.resourceId
             status: 'Approved'
             resourceRegion: location
           }
         }
         {
           name: 'file'
           properties: {
             groupId: 'file'
             privateLinkResourceId: azureAIfoundryStorageAccount.outputs.resourceId
             status: 'Approved'
             resourceRegion: location
           }
         }
         {
           name: 'search'
           properties: {
             groupId: 'searchService'
             privateLinkResourceId: aiSearch.outputs.resourceId
             status: 'Approved'
             resourceRegion: location
           }
         }
       ]
       provisionNetworkNow: true
       connections: [
         {
           name: 'AzureOpenAI'
           category: deployAIServices ? 'AIServices' : 'AzureOpenAI'
           isSharedToAll: true
           connectionProperties: {
             authType: 'AAD'
           }
           metadata: {
             ApiType: 'Azure'
             ResourceId: azureOpenAI.outputs.resourceId
           }
           target: azureOpenAI.outputs.endpoint
         }
         {
           name: 'AISearch'
           category: 'CognitiveSearch'
           isSharedToAll: true
           connectionProperties: {
             authType: 'AAD'
           }
           metadata: {
             ApiType: 'Azure'
             type: 'azure_ai_search'
             ResourceId: aiSearch.outputs.resourceId
           }
           target: 'https://${aiSearch.outputs.name}.search.windows.net'
         }
       ]
       privateEndpoints: [
         {
           name: 'foundry-pe-${location}-${environment}-${namingPrefix}'
           service: 'amlworkspace'
           privateDnsZoneGroup: {
             privateDnsZoneGroupConfigs: [
               {
                 privateDnsZoneResourceId: '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms'
               }
               {
                 privateDnsZoneResourceId: '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net'
               }
             ]
           }
           subnetResourceId: filter(
             virtualNetwork.outputs.subnetResourceIds,
             subnetId => contains(subnetId, 'openAISubnet')
           )[0]
         }
       ]
     }
   }
   ```

Deploying AI Foundry project where developers would do the work. You can notice here that we didn't configure any private endpoints as the project will inherit the networking configuration of the hub it's part of.

   ```python
   module azureAIfoundryProject 'br/public:avm/res/machine-learning-services/workspace:0.12.0' = {
     name: 'azureAIfoundryProject'
     params: {
       name: 'project${environment}${namingPrefix}'
       sku: 'Standard'
       kind: 'Project'
       location: location
       hubResourceId: azureAIfoundry.outputs.resourceId
       managedIdentities: {
         systemAssigned: true
       }
       friendlyName: 'AI Phoenix Project'
       systemDatastoresAuthMode: 'Identity'
       publicNetworkAccess: 'Disabled'
       roleAssignments: [
         {
           principalId: azureOpenAIAdminGroup
           roleDefinitionIdOrName: '64702f94-c441-49e6-a78b-ef80e0188fee'
           principalType: 'Group'
           description: 'Azure AI Developer'
         }
       ]
     }
   }
   ```

### Role assignments

We've seen in the above modules, that we set the role assignments within the module definition but since the RBAC roles needed are a little bit interwinded, there can be some circular dependencies so we won't be able to do all of them within each module. We will have to additionally define some required assignments. Reference to all assignments needed can be found [here](https://learn.microsoft.com/azure/ai-services/openai/how-to/on-your-data-configuration#role-assignments)

```python
module azureAIfoundrySearchRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: azureAIfoundry.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: aiSearch.outputs.resourceId
    roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    principalType: 'ServicePrincipal'
    description: 'Search Service Contributor'
  }
}

module azureAIfoundryStgPERoleAssignmentBlob 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: azureAIfoundryProject.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: azureAIfoundryStorageAccount.outputs.privateEndpoints[0].resourceId
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalType: 'ServicePrincipal'
    description: 'Reader'
  }
}

module azureAIfoundryStgPERoleAssignmentFile 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: azureAIfoundryProject.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: azureAIfoundryStorageAccount.outputs.privateEndpoints[1].resourceId
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalType: 'ServicePrincipal'
    description: 'Reader'
  }
}

module azureAIfoundryStgRoleAssignmentFile 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: deployer().objectId
    resourceId: azureAIfoundryStorageAccount.outputs.resourceId
    roleDefinitionId: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
    principalType: 'User'
    description: 'Storage File Data Privileged Contributor'
  }
}

module azureAifoundryAIRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: azureAIfoundry.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: azureOpenAI.outputs.resourceId
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalType: 'ServicePrincipal'
    description: 'Reader'
  }
}

module azureAifoundrySearchRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: azureAIfoundry.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: aiSearch.outputs.resourceId
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalType: 'ServicePrincipal'
    description: 'Reader'
  }
}

module azureAIfoundryStgRoleAssignmentTable 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: azureAIfoundry.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: azureAIfoundryStorageAccount.outputs.resourceId
    roleDefinitionId: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
    principalType: 'ServicePrincipal'
    description: 'Storage Table Data Contributor'
  }
}

module azureAIfoundryStgRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: azureAIfoundry.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: azureAIfoundryStorageAccount.outputs.resourceId
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalType: 'ServicePrincipal'
    description: 'Reader'
  }
}


module azureAISearchRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: aiSearch.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: azureOpenAI.outputs.resourceId
    roleDefinitionId: 'a001fd3d-188f-4b5d-821b-7da978bf7442'
    principalType: 'ServicePrincipal'
    description: 'Cognitive Services OpenAI Contributor'
  }
}

module azureAISearchRoleAssignment2 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: aiSearch.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: azureOpenAI.outputs.resourceId
    roleDefinitionId: '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68'
    principalType: 'ServicePrincipal'
    description: 'Cognitive Services Contributor'
  }
}

module azureAIStgSearchRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: aiSearch.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: azureAIfoundryStorageAccount.outputs.resourceId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: 'ServicePrincipal'
    description: 'Storage Blob Data Contributor'
  }
}

module azureAIAOAISearchRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  params: {
    principalId: aiSearch.outputs.?systemAssignedMIPrincipalId ?? ''
    resourceId: azureOpenAI.outputs.resourceId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
    description: 'Cognitive Services OpenAI User'
  }
}
```

### Testing our setup

After the deployment is complete, if we try to access any of the PaaS services, we will be blocked as we should only connect from the private virtual network. If I try for example to connect to the AI Foundry project from my device, I get this message:

   ![Screenshot showing access denied from untrusted network](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/04.png)

Now, let's connect to the jump server using bastion and attempt the following:

- Upload a markdown file to the blob storage
- Import and vectorize the blob storage container into AI Search
- Import the created indexer into the Foundry project
- Test the solution using the chat playground

After uploading a sample markdown file to the storage account, I will go to the search service and select "Import and vectorize data". Since we configure all the needed role assignments, we should use managed identity as the authentication type.

   ![Screenshot showing opening the import and vectorize data option](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/05.png)

Next, we will select the embedding model that we deployed in our Azure OpenAI instance and also select managed identity as the authentication type.

   ![Screenshot showing configuring the embedding model](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/06.png)

>**NOTE:** At this step, of any of the role assignments or private endpoints are not configured properly, you will get some errors preventing you from continuing with this wizard.

Once we create the AI Search index, we see that it fails immediately as by default it's not configured to run in a private environment.

   ![Screenshot showing the failed AI search index](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/07.png)

To fix that, we need to edit the indexer's JSON and add the property `"executionEnvironment": "private"`.

   ![Screenshot showing editing the JSON of the index](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/08.png)

   ![Screenshot showing adding the private execution environment to the json file](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/09.png)

   ![Screenshot showing a successfull run of the indexer](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/10.png)

Once that is in-place, we can navigate to the AI Foundry project and to the chat playground. We can see that the model we specified in the parameters is indeed deployed. Let's try to add our data (markdown file in the blob storage account).

   ![Screenshot showing the foundry chat playground](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/11.png)

We will select "Azure AI Search" as the data source since we already imported the storage account's container and created the index.

   ![Screenshot showing selecting ai search as the data source](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/12.png)

We will select the index that was created in AI Search.

  ![Screenshot showing adding the index created by ai search](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/13.png)

We will configure the vector settings to create embeddings using the embedding model we deployed.

   ![Screenshot showing configuring the embedding settings](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/14.png)

Finally, we can see that we successfully imported the index from AI Search and can now use this vector store to chat with our data using the different AI models.

   ![Screenshot showing a successfull configuration of chat with your data](https://images.seifbassem.com/images/Posts/Azure-AI-Services-Private-Deployment/15.png)

### Next steps

What we have deployed and configured is just the AI infrastructure, the next step would be the application layer to consume the AI service endpoint to be able to integrate this functionality in any application.


## Resources
 - [Azure AI Foundry architecture](https://learn.microsoft.com/azure/ai-foundry/concepts/architecture)
 - [AI Foundry and managed network](https://learn.microsoft.com/azure/ai-foundry/how-to/configure-managed-network?tabs=portal)
 - [Azure AI Foundry connections](https://learn.microsoft.com/azure/ai-foundry/concepts/connections)
 - [Azure OpenAI chat baseline architecture in an Azure landing zone](https://learn.microsoft.com/azure/architecture/ai-ml/architecture/azure-openai-baseline-landing-zone)
 - [Private connection for Azure AI Search](https://learn.microsoft.com/azure/search/search-indexer-howto-access-private?tabs=portal-create)
 - [Role assignments for private data access](https://learn.microsoft.com/azure/ai-services/openai/how-to/on-your-data-configuration#role-assignments)
 - [Azure Verified Modules](https://aka.ms/AVM)