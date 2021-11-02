---
title: "Re-usable Bicep modules using Azure Container Registry"
images:
  - "https://images.seifbassem.com/images/Posts/Bicep-Azure-Container-Registry/banner.png"
date: 2021-11-01 17:08:42 +0200
tags: ["Azure","Bicep","Infrastructure-as-code"]
categories: ["posts"]
draft: false
---

<!--more-->
## Build re-usable Bicep modules
Bicep enables you to organize your infrastructure into modules, by dividing complex environments into multiple files for better readability and re-usability. Given this capability, we still needed a way to share those Bicep files and modules within your organization, store them centrally and apply RBAC for more control on how can deploy what.

Now (In Preview), you can publish Bicep modules into an Azure Container Registry and give read access to users who need to deploy them. Let's explore this new feature and see how it would work.

## Scenario
1. We will create a Storage Account module with the following requirements to be deployed with diagnostic settings of any resource that gets deployed in our environment.

**Requirements:**
- Disable public access
- Enforce TLS 1.2
- Allow only HTTPs traffic
- Deny Shared Key Access

```python
@description('The Azure Storage Account name prefix')
param storageAccountPrefix string

@description('The Azure Storage Account Sku name')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
])
param skuName string

@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

var storageAccountName = '${storageAccountPrefix}${uniqueString(resourceGroup().id)}'

resource stg 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  kind: 'StorageV2'
  location: location
  sku: {
    name: skuName
  }
  properties:{
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

output storageID string = stg.id
```

> Since this is a module, we will specify the Storage Account ID as an output to be exposed to any other deployment using this module.

2. Next, we need to create an Azure Container registry to publish our modules and get it's login server URI.

![New Azure container registry](https://images.seifbassem.com/images/Posts/Bicep-Azure-Container-Registry/1.jpg)

![New Azure container registry login server](https://images.seifbassem.com/images/Posts/Bicep-Azure-Container-Registry/2.jpg)

3. Then, we publish our module to the newly created registry.

```python
bicep publish .\storageAccount.bicep --target 'br:bicepacr001.azurecr.io/bicep/modules/storageaccounts/diagnostic:v1.0'
```

> Make sure to update the Azure CLI and also to have the Bicep CLI on version 0.4.1008 or later for this to work.

![Publish module to ACR](https://images.seifbassem.com/images/Posts/Bicep-Azure-Container-Registry/3.jpg)

![Publish module to ACR-manifest](https://images.seifbassem.com/images/Posts/Bicep-Azure-Container-Registry/4.jpg)

4. Now, having our module published, let's create a new web app that will reference this module to store the diagnostic settings.

### Parameters and variables
We will define the web app's parameters and also the Storage Account ones specified in our module. The Storage Account module needs two parameters; the name prefix and the SKU.

```python
param webAppName string = uniqueString(resourceGroup().id) 
param sku string = 'F1'
param runtimeStack string = 'NODE|14-lts'
param location string = resourceGroup().location
param stgAccountSKU string = 'Standard_LRS'
param stgaccPrefix string = 'stg'

var appServicePlanName = toLower('AppServicePlan-${webAppName}')
var webSiteName = toLower('wapp-${webAppName}')
```
### Web app code

```python
resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
  properties:{
    reserved: true
  }
  kind: 'linux'
}
resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: runtimeStack
    }
  }
}
```

### Storage Account module reference
We will reference the Azure Container Registry and the repo containing our module, passing the parameters needed by our module.

```python
module stg 'br:bicepacr001.azurecr.io/bicep/modules/storageaccounts/diagnostic:v1.0' ={
  name: 'storageDeploy'
  params: {
    skuName: stgAccountSKU
    storageAccountPrefix: stgaccPrefix
  }
}
```

### Diagnostic settings creation
We will reference the symbolic name of our Storage Account module and use the output we defined to get the created Storage Account ID and send some diagnostic logs to it.

```python
resource diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview'={
  name: 'diagwebapp'
  scope: appService
  properties: {
    storageAccountId: stg.outputs.storageID
    logs: [
      {
        enabled: true
        category: 'AppServiceHTTPLogs'
      }
      {
        enabled: true
        category: 'AppServiceConsoleLogs'
        retentionPolicy: {
          days: 100
          enabled: true
        }
      }
    ]
  }
}
```

### Full code
```python
param webAppName string = uniqueString(resourceGroup().id) 
param sku string = 'F1'
param runtimeStack string = 'NODE|14-lts'
param location string = resourceGroup().location
param stgAccountSKU string = 'Standard_LRS'
param stgaccPrefix string = 'stg'


var appServicePlanName = toLower('AppServicePlan-${webAppName}')
var webSiteName = toLower('wapp-${webAppName}')

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
  properties:{
    reserved: true
  }
  kind: 'linux'
}
resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: runtimeStack
    }
  }
}

module stg 'br:bicepacr001.azurecr.io/bicep/modules/storageaccounts/diagnostic:v1.0' ={
  name: 'storageDeploy'
  params: {
    skuName: stgAccountSKU
    storageAccountPrefix: stgaccPrefix
  }
}

resource diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview'={
  name: 'diagwebapp'
  scope: appService
  properties: {
    storageAccountId: stg.outputs.storageID
    logs: [
      {
        enabled: true
        category: 'AppServiceHTTPLogs'
      }
      {
        enabled: true
        category: 'AppServiceConsoleLogs'
        retentionPolicy: {
          days: 100
          enabled: true
        }
      }
    ]
  }
}

```

### Deploy the Bicep file
Let's deploy the webapp Bicep deployment and see what happens.

```python
az deployment group create -g webapp --template-file .\webpapp.bicep
```
Once the deployment is complete, let's see what gets created in the Resource Group.

![Resources created](https://images.seifbassem.com/images/Posts/Bicep-Azure-Container-Registry/5.jpg)

Going into the Web App diagnostic settings, we can see that our Storage Account is configured already.

![Diagnostic settings configured](https://images.seifbassem.com/images/Posts/Bicep-Azure-Container-Registry/6.jpg)

## Recap
[Usin this new feature](https://docs.microsoft.com/azure/azure-resource-manager/bicep/private-module-registry), you can simplify the collaboration within your organization and promote re-usability of infrastructure-as-code modules while maintaining good governance and security practices already available in Azure Container Registry.

