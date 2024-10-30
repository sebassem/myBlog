---
title: "Tips - Deploying multiple Azure OpenAI models"
images:
  - "https://images.seifbassem.com/images/Posts/AOAI-Bicep-Multiple-Models/banner.png"
date: 2024-10-29 17:08:42 +0200
tags: ["Azure","Troubleshooting","Tips","INFRASTRUCTURE-AS-CODE","Bicep","Azure-OpenAI","AI"]
categories: ["posts"]
draft: false
---

<!--more-->

I was recently developing some Bicep code to deploy Azure OpenAI and a couple of OpenAI models on Azure. I hit a strange error when I tried to deploy multiple models using loop.

### Problematic code

```bicep
@description('The name of the OpenAI Cognitive Services account')
param openAIAccountName string = 'openai${uniqueString(resourceGroup().id,location)}'

@description('The location of the OpenAI Cognitive Services account')
param location string = resourceGroup().location

@description('The name of the OpenAI Cognitive Services SKU')
param openAISkuName string = 'S0'

@description('The type of Cognitive Services account to create')
param cognitiveSvcType string = 'AIServices'

@description('The array of OpenAI models to deploy')
param azureOpenAIModels array = [
  {
    name: 'gpt-35-turbo'
    version: '0125'
  }
  {
    name: 'gpt-4o-mini'
    version: '2024-07-18'
  }
]

resource openAIAccount 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: openAIAccountName
  location: location
  sku: {
    name: openAISkuName
  }
  kind: cognitiveSvcType
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource openAIModelsDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = [for model in azureOpenAIModels: {
  parent: openAIAccount
  name: '${openAIAccountName}-${model.name}-deployment'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: model.name
      version: model.version
    }
    currentCapacity: 10
  }
}]
```

When deploying this code, I get an error that another operation is in progress for the parent resource.

![Screenshot showing the ARM deployment error](https://images.seifbassem.com/images/Posts/AOAI-Bicep-Multiple-Models/01.png)

![Screenshot showing the ARM deployment error detailed](https://images.seifbassem.com/images/Posts/AOAI-Bicep-Multiple-Models/02.png)

After some research, it appears that Azure OpenAI doesn't like to have multiple deployments at the same time so to solve this issue there are two options:

- Create a resource per deployment and use a `dependson` to maintain sequential deployment. The problems with this approach is that the code is not reusable as you need to manually specify a resource per model, and readability-wise will not be the easiest to read if you have multiple models.

```bicep
  resource openAIAccount 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: openAIAccountName
  location: location
  sku: {
    name: openAISkuName
  }
  kind: cognitiveSvcType
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource openAI35Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = {
  parent: openAIAccount
  name: '${openAIAccountName}-${gpt35}-deployment'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0125'
    }
    currentCapacity: 10
  }
}

resource openAI4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = {
  parent: openAIAccount
  name: '${openAIAccountName}-${gpt4o}-deployment'
  dependsOn: [
    openAI35Deployment
  ]
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
    currentCapacity: 10
  }
}
```

- Create a loop and use `batchsize` with a value of 1 to control the number of sequential loop executions. This is my preferred method as allows me to parametrize my code and make it more reusable and readable.

```bicep
@description('The array of OpenAI models to deploy')
param azureOpenAIModels array = [
  {
    name: 'gpt-35-turbo'
    version: '0125'
  }
  {
    name: 'gpt-4o-mini'
    version: '2024-07-18'
  }
]

resource openAIAccount 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: openAIAccountName
  location: location
  sku: {
    name: openAISkuName
  }
  kind: cognitiveSvcType
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

@batchSize(1)
resource openAIModelsDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = [for model in azureOpenAIModels: {
  parent: openAIAccount
  name: '${openAIAccountName}-${model.name}-deployment'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: model.name
      version: model.version
    }
    currentCapacity: 10
  }
}]
```

After redeploying using `batchsize`, I can see that my Bicep deployment succeeds and both models are deployed.

![Screenshot showing the successfull deployment](https://images.seifbassem.com/images/Posts/AOAI-Bicep-Multiple-Models/04.png)
