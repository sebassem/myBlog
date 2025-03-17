---
title: "Testing the latest Bicep Toys - Fail, Deployer and Graph"
images:
  - "https://images.seifbassem.com/images/Posts/bicep-fail-deployer-graph/banner.png"
date: 2025-03-16 16:08:42 +0200
tags: ["Azure","Bicep","frastructure-as-code"]
categories: ["posts"]
draft: false
---

<!--more-->

Bicep had lots of interesting features released in the past 3-5 months that I really haven't had the time to test until now. For example, the `deployer()` function that allows you to get the ObjectId and TenantId of the principal deploying the Bicep template, the `fail()` function that allows you to fail the deployment with a custom message if a specific criteria or condition is not met, and lastly the `Graph` extension that allows you to interact with Entra ID objects the same way you interact with Azure resources.

In this post, I will show a very simple scenario to use all of those new feature. We have a shared Bicep template to deploy Azure Open AI and we want to limit the deployment of the latest flagship model (GPT 4.5) to only users who are members of a specific Entra ID group to make sure we govern the costs of this powerful models.

## Demo

To be able to use the Bicep Graph extension, we first need to define it in a `bicepconfig.json` file using an alias.

```json
{
    "experimentalFeaturesEnabled": {
        "extensibility": true
    },
    "extensions": {
      "microsoftGraphV1": "br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:0.2.0-preview"
    }
}
```

Then, we can reference the alias in our Bicep template.

```python
extension microsoftGraphV1
```

Let's first define a parameter for the Azure Open AI models so users can select the models of their choice.

```python
@description('The model to deploy into Azure Open AI.')
param model object = {
  Name: 'gpt-4o-mini'
  Version: '2024-07-18'
}
```

To get the identity of the principal deploying the shared template, we will define a variable using the `deployer()` function.

```python
var userId = deployer().objectId
```

We also need to reference the Entra ID group that we want to check membership against.

```python
resource groupMember 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: 'PhoenixProjectAdmins'
}
```

The final step is to defined the Azure Open AI resource. I will use Azure Verified Modules to do that.

```python
module aoai 'br/public:avm/res/cognitive-services/account:0.10.1' = {
  name: 'aoai'
  params: {
    name: 'aoai${uniqueString(resourceGroup().id)}'
    kind: 'OpenAI'
    sku: 'S0'
    location: location
    deployments: [
      {
        model: {
          name: model.Name
          format: 'OpenAI'
          version: model.Version
        }
        name: model.Name
        sku: {
          capacity: 10
          name: 'Standard'
        }
      }
    ]
  }
}
```

Just defining the deployments like this will allow anyone to deploy any model they want including GPT-4.5 which is not the behavior we want, so we need to use the `fail()` function here to add a conditions, let's refactor our code to add a condition to check the Entra ID group membership and fail the deployment if the user is not a member.

```python
module aoai 'br/public:avm/res/cognitive-services/account:0.10.1' = {
  name: 'aoai'
  params: {
    name: 'aoai${uniqueString(resourceGroup().id)}'
    kind: 'OpenAI'
    sku: 'S0'
    location: location
    deployments: [
      {
        model: {
          name: (model.Name == 'gpt-4.5-preview' && indexOf(groupMember.members.relationships, userId) == -1) ? fail('Deploying gpt-4.5 is not allowed for your user ${userId}. You have to be part of the PhoenixProjectAdmins security group.') : model.Name
          format: 'OpenAI'
          version: model.Version
        }
        name: model.Name
        sku: {
          capacity: 10
          name: 'Standard'
        }
      }
    ]
  }
}
```

Now, lets test the deployment by using *GPT-40-mini* in our parameters file and see what happens.

```python
using './main.bicep'

param location = 'swedenCentral'
param model = {
  Name: 'gpt-4o-mini'
  Version: '2024-07-18'
}
```

  ![Screenshot showing a successful Azure Open AI deployment with GPT-4o-mini in the Azure portal](https://images.seifbassem.com/images/Posts/bicep-fail-deployer-graph\01.png)

The deployment is successful and we can see the Azure Open AI resource and the model successfully deployed.

Now, let's try to do the same using GPT 4.5, we can see the we instantly get a failed deployment with our custom message.

```python
using './main.bicep'

param location = 'swedenCentral'
param model = {
  Name: 'gpt-4.5-preview'
  Version: '2025-02-27'
}
```

  ![Screenshot showing a failed Azure Open AI deployment with GPT-4.5 in the Azure portal](https://images.seifbassem.com/images/Posts/bicep-fail-deployer-graph\02.png)

## References

- `deployer()` function documentation can be found [here](https://learn.microsoft.com/azure/azure-resource-manager/bicep/bicep-functions-deployment#deployer)
- `fail()` function release notes can be found [here](https://github.com/Azure/bicep/releases/tag/v0.33.13)
- Graph extension documentation can be found [here](https://learn.microsoft.com/graph/templates/)