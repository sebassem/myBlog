---
title: "Tips - Pre-check your AI models quotas using AZD"
images:
  - "https://images.seifbassem.com/images/Posts/azd-ai-quota-check/banner.png"
date: 2025-07-20 17:08:42 +0200
tags: ["Azure","AI","OpenAI","Foundry","Bicep","AZD"]
categories: ["posts"]
draft: false
---

<!--more-->

When deploying Azure OpenAI models, you usually have to first do some due diligence to determine which Azure regions support the models and models' versions you want to deploy and additionally you need to check if those regions have capacity to accommodate the quotas you want in your deployments.

   ![Screenshot showing a table from the docs with the GPT4.0 regions](https://images.seifbassem.com/images/Posts/azd-ai-quota-check/01.png)

As a developer, you usually don't care about this as you just want to have your models deployed and configured without worrying about the infrastructure. In most organizations adopting the Azure Developer CLI (azd), there are usually azd templates published and made available to developers to deploy their AI applications, and developers would get failed deployments if they don't get the right combination of model/region/capacity.

I recently discovered a very nice feature of azd that allows the CLI to do the work of finding the right region with available capacity for the model(s) that gets specified in the bicep template so you don't have to do the work and get to a successful deployment quickly. Let's see the deployment experience before and after using this feature.

## Experience before

This is a very simple bicep template that deploys two OpenAI models:

- `gpt-4o-realtime-preview`
- `gpt-4o`

If we look at the docs, we can see that `gpt-4o-realtime-preview` is only available in very limited regions. The location parameter is left for the user to specify and defaults to the resource group location.

   ```python
   @description('Optional. The Azure OpenAI models to deploy')
   param deployments array = [
     {
       name: 'llm-test-deployment'
       model: {
         format: 'OpenAI'
         name: 'gpt-4o-realtime-preview'
         version: '2024-12-17'
       }
       sku: {
         capacity: 2
         name: 'GlobalStandard'
       }
     }
     {
       name: 'llm-prod-deployment'
       model: {
         format: 'OpenAI'
         name: 'gpt-4o'
         version: '2024-11-20'
       }
       sku: {
         capacity: 450
         name: 'GlobalStandard'
       }
     }
   ]
   
   @description('The Azure location for the resources. Defaults to the resource group location.')
   param location string = resourceGroup().location
   
   param namingPrefix string = take(newGuid(),4)
   
   module openAI 'br/public:avm/res/cognitive-services/account:0.11.0' = {
     params: {
       name: 'openai-${uniqueString(resourceGroup().id,location,namingPrefix)}'
       kind: 'OpenAI'
       location: location
       sku: 'S0'
       deployments: deployments
     }
   }
   ```

When we try to deploy this using `azd up` in eastus region, we can see that we get an error message that the model is not supported in this region.

   ![Screenshot showing error deploying the ai model](https://images.seifbassem.com/images/Posts/azd-ai-quota-check/02.png)

This is expected but not ideal, as we need to go back to the docs to find the supported region and then find if there is capacity to support our application.

## Experience after

Now let's update our code to use the new azd feature.

   ```python
   @description('Optional. The Azure OpenAI models to deploy')
   param deployments array = [
     {
       name: 'llm-test-deployment'
       model: {
         format: 'OpenAI'
         name: 'gpt-4o-mini'
         version: '2024-07-18'
       }
       sku: {
         capacity: 90
         name: 'GlobalStandard'
       }
     }
     {
       name: 'llm-prod-deployment'
       model: {
         format: 'OpenAI'
         name: 'gpt-4o'
         version: '2024-11-20'
       }
       sku: {
         capacity: 450
         name: 'GlobalStandard'
       }
     }
   ]
   
   @metadata({azd:{
     type: 'location'
     usageName: [
       'OpenAI.GlobalStandard.gpt-4o,450'
       'OpenAI.GlobalStandard.gpt-4o-mini,450'
     ]
   }})
   @description('The Azure location for the AI models.')
   param aiModelsLocation string
   
   @description('The Azure location for the resources. Defaults to the resource group location.')
   param location string = resourceGroup().location
   
   param namingPrefix string = take(newGuid(),4)
   
   
   module openAI 'br/public:avm/res/cognitive-services/account:0.11.0' = {
     params: {
       name: 'openai-${uniqueString(resourceGroup().id,location,namingPrefix)}'
       kind: 'OpenAI'
       location: aiModelsLocation
       sku: 'S0'
       deployments: deployments
     }
   }
   ```

You can see that we added a new parameter `aiModelsLocation` with azd-specific metadata that defines the models we want to deploy and optionally, the quotas we need. This piece of metadata, will instruct azd to first find the supported regions with available capacity and only allow us to select from them to avoid having deployment errors.

- The **type: 'location'** property instructs azd to display a region selector interface in the cli.
- The **usageName** property defines the models we need to deploy and their respective quotas.

```python
   @metadata({azd:{
     type: 'location'
     usageName: [
       'OpenAI.GlobalStandard.gpt-4o,450'
       'OpenAI.GlobalStandard.gpt-4o-mini,450'
     ]
   }})
   @description('The Azure location for the AI models.')
   param aiModelsLocation string
   ```

![Screenshot showing the regions returned by azd](https://images.seifbassem.com/images/Posts/azd-ai-quota-check/03.png)

We can see that we get prompted to select the region but we only get back 23 regions which are supported and have capacity for our defined OpenAI models. Now let's try to select another model that is only available in fewer regions like `gpt-4o-realtime-preview`

   ```python
   @description('Optional. The Azure OpenAI models to deploy')
   param deployments array = [
     {
       name: 'llm-test-deployment'
       model: {
         format: 'OpenAI'
         name: 'gpt-4o-realtime-preview'
         version: '2024-12-17'
       }
       sku: {
         capacity: 2
         name: 'GlobalStandard'
       }
     }
     {
       name: 'llm-prod-deployment'
       model: {
         format: 'OpenAI'
         name: 'gpt-4o'
         version: '2024-11-20'
       }
       sku: {
         capacity: 450
         name: 'GlobalStandard'
       }
     }
   ]
   
   @metadata({azd:{
     type: 'location'
     usageName: [
       'OpenAI.GlobalStandard.gpt-4o,450'
       'OpenAI.GlobalStandard.gpt-4o-realtime-preview,2'
     ]
   }})
   @description('The Azure location for the AI models.')
   param aiModelsLocation string
   
   @description('The Azure location for the resources. Defaults to the resource group location.')
   param location string = resourceGroup().location
   
   param namingPrefix string = take(newGuid(),4)
   
   
   module openAI 'br/public:avm/res/cognitive-services/account:0.11.0' = {
     params: {
       name: 'openai-${uniqueString(resourceGroup().id,location,namingPrefix)}'
       kind: 'OpenAI'
       location: aiModelsLocation
       sku: 'S0'
       deployments: deployments
     }
   }
   ```

![Screenshot showing the ai model regions](https://images.seifbassem.com/images/Posts/azd-ai-quota-check/04.png)

We can see that we only get back one region that matches the models and quotas we selected which is very cool as now the cli does the work for us and we are able to enable developers to deploy ai applications much faster.