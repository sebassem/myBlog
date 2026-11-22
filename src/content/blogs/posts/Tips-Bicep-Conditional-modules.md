---
title: "Tips - Bicep conditional modules"
images:
  - "https://images.seifbassem.com/images/Posts/Bicep-conditional-modules/banner.png"
date: 2023-09-18 17:08:42 +0200
tags: ["Azure","Troubleshooting","Tips","INFRASTRUCTURE-AS-CODE","Bicep"]
categories: ["posts"]
draft: false
---

<!--more-->

I was recently developing some Bicep modules and hit a very strange problem that got me troubleshooting for hours. I was referencing the outputs of one module from the other and had both modules deployed if a certain condition is met. The strange behavior was that although both modules had the same condition which was false, I got one of those modules always being deployed regardless if the condition was met or not.

Let's look at a sample scenario to see the problem and what was the workaround to make it work. I will create two modules, one for a virtual network and one for a storage account. I will configure a service endpoint for the _Microsoft.Storage_ service on one of the virtual network's subnet. Both modules will get deployed only if a parameter name _condition_ is true.

### Storage account module

```python
param storageAccountPrefix string = 'stgse'
param storageAccountSku string = 'Standard_LRS'
param storageAccountKind string = 'StorageV2'
param location string = resourceGroup().location
param subnetRef string = ''

var storageAccountName = '${storageAccountPrefix}${uniqueString(resourceGroup().id)}'

resource stg 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku:{
    name: storageAccountSku
  }
  kind: storageAccountKind
  properties: {
    supportsHttpsTrafficOnly: true
    networkAcls:{
      bypass: 'None'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnetRef
          action: 'Allow'
        }
      ]
    }
  }
}
```

### Virtual network module

You can see I'm adding a _storageSubnetRef_ output for the service endpoint subnet Id to be used in the Storage Account module.

   ```python
   param vnetName string = 'rsg-vnet-001'
   param location string = resourceGroup().location
   param addressPrefix string = '10.0.0.0/16'

   var subnets = [
     {
       name: 'default'
       addressPrefix: '10.0.1.0/24'
       serviceEndpoints: []
     }
     {
       name: 'storage'
       addressPrefix: '10.0.2.0/24'
       serviceEndpoints: [
         {
           service: 'Microsoft.Storage'
         }
       ]
     }
   ]

   resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
     name: vnetName
     location: location
     properties: {
       addressSpace: {
         addressPrefixes: [
           addressPrefix
         ]
       }
       subnets: [for subnet in subnets: {
         name: subnet.name
         properties: {
           addressPrefix: subnet.addressPrefix
           serviceEndpoints: subnet.serviceEndpoints
         }
       }]
     }
   }
   output storageSubnetRef string = vnet.properties.subnets[1].id
   ```

### Main.bicep

In the main bicep file, I'm adding a parameter named _condition_ which will be the conditional parameter to deploy both modules. You can also see the _storageSubnetRef_ value referenced in the storage module.

   ```python
   param storageAccountPrefix string = 'stgse'
   param storageAccountSku string = 'Standard_LRS'
   param storageAccountKind string = 'StorageV2'
   param location string = resourceGroup().location
   param vnetName string = 'rsg-vnet-001'
   param addressPrefix string = '10.0.0.0/16'
   param condition bool = false

   module virtualNetwork 'network.bicep' = if(condition){
     name: 'vnet'
     params: {
       vnetName: vnetName
       addressPrefix: addressPrefix
       location: location
     }
   }


   module storageAccount 'storage.bicep' = if(condition){
     name: 'storage'
     params: {
       location: location
       storageAccountKind: storageAccountKind
       storageAccountPrefix: storageAccountPrefix
       storageAccountSku: storageAccountSku
       subnetRef: virtualNetwork.outputs.storageSubnetRef
     }
   }
   ```

### Running the deployment

- When I try to run this deployment, it should not create anything given that the _condition_ parameter is false so we should get an empty resource group with no errors but this doesn't happen.

```azurecli
az group create -n bicepModules-rg -l eastus
az deployment group create -f ./main.bicep -l eastus
```

   ![Screenshot showing the deployment failed with an error that the vnet module is not found](https://images.seifbassem.com/images/Posts/Bicep-conditional-modules/01.png)

- I get an error that the _vnet_ deployment wasn't found, so the deployment attempted to deploy the storage module which depends on the output from the vnet module but since it wasn't deployed, we got this error.

### Workaround

The way to overcome this, is to add the same condition on the output reference in the storage module.

#### Main.bicep modified

  ```python
   param storageAccountPrefix string = 'stgse'
   param storageAccountSku string = 'Standard_LRS'
   param storageAccountKind string = 'StorageV2'
   param location string = resourceGroup().location
   param vnetName string = 'rsg-vnet-001'
   param addressPrefix string = '10.0.0.0/16'
   param condition bool = false

   module virtualNetwork 'network.bicep' = if(condition){
     name: 'vnet'
     params: {
       vnetName: vnetName
       addressPrefix: addressPrefix
       location: location
     }
   }


   module storageAccount 'storage.bicep' = if(condition){
     name: 'storage'
     params: {
       location: location
       storageAccountKind: storageAccountKind
       storageAccountPrefix: storageAccountPrefix
       storageAccountSku: storageAccountSku
       subnetRef: condition ? virtualNetwork.outputs.storageSubnetRef : ''
     }
   }
   ```

- Using this method, we get the expected behavior and none of the modules get deployed.

![Screenshot showing a successful deployment](https://images.seifbassem.com/images/Posts/Bicep-conditional-modules/02.png)
