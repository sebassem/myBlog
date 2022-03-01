---
title: "Discover configuration changes across your Azure Environment"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/banner.png"
date: 2022-02-28 17:08:42 +0200
tags: ["Azure","Azure Resource Graph","Azure Workbooks"]
categories: ["Posts"]
draft: false
---

<!--more-->

Azure Resource Graph is a very useful service on Azure that allows you to query at scale your resources and their properties with complex filtering to help you properly govern your environment. It was recently announced that currently in preview, you can query and discover changes in your Azure resources and their properties.

This capability would allow you to answer questions like :
 - What new resources have been created/deleted in this subscription in the past 24 hours?
 - What is the last change that happened on this web application and what properties were changed?
 - Show me all the changes that happened in the past day.

In this post, I will give this new capability a spin by creating a workbook to show the number of changes in the selected subscription(s) and then drilling down to understand what exactly has changed.

## Workbook creation

First things first, I will add some parameters to make my workbook reusable.

   ![Screenshot showing two parameters in the workbook](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/1.jpg)

**Subscription parameter** to select one or more subscriptions to query changes

   ![Screenshot showing editing the subscription parameter](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/2.jpg)

**Time range parameter** to select the needed time frame to query resource configuration changes

   ![Screenshot showing editing the time range parameter](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/3.jpg)

Next, I will add a new **Azure Resource Graph** query to get all the changes that happened in the selected subscription and during the selected time frame.

  ```python
  ResourceChanges
| extend changeTime = todatetime(properties.changeAttributes.timestamp),
changeType = tostring(properties.changeType), changeCount = tostring(properties.changeAttributes.changesCount)
| where changeTime {TimeRange:value}
| summarize count() by changeType
  ```

   ![Screenshot showing editing the azure resource graph query](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/4.jpg)

We can see that the time range parameter is "Last hour" and it's referenced in the query to only query the resource changes during that time. The number of changes is visible with the actual change happening, but let's make it more appealing, changing the visualization to **Tiles**.

   ![Screenshot showing the azure resource graph query with tiles visualization](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/5.jpg)

Now, we want to be able to click on any of those tiles and get more detailed information about the changes. Going into the query **Advanced settings** to export the "changeType" parameter for later use.

   ![Screenshot showing exporting a parameter in the query settings](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/7.jpg)

Next, to make use of this exported parameter, I will add a new **Azure Resource Graph** query to get more details about the change that happened based on the selected change type in the above query.

  ```python
  ResourceChanges
| extend changeTime = todatetime(properties.changeAttributes.timestamp), targetResourceId = tostring(properties.targetResourceId),
changeType = tostring(properties.changeType), correlationId = properties.changeAttributes.correlationId, 
changedProperties = properties.changes, changeCount = properties.changeAttributes.changesCount, resourceType=tostring(properties.targetResourceType)
| where changeType == "{argChanges}" and changeTime {TimeRange:value}
| project changeTime, resourceType,targetResourceId, changeType, correlationId, changeCount, changedProperties
  ```

   ![Screenshot showing an azure resource graph query](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/8.jpg)

I will make it only visible if we click on any of the changes in the above query.

   ![Screenshot showing editing the azure resource graph query](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/9.jpg)

The final workbook, should look like this:

   ![Screenshot showing workbook after editing](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/10.jpg)

## Testing the workbook

I will create a scenario where we have a storage account with some images that developers are using to design an application. All of a sudden, they cannot access the images anymore.

Images access working fine ✅

   ![Screenshot showing a working storage account blob retrieval](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/11.jpg)

Images access broken ❎

   ![Screenshot showing a not working storage account blob retrieval](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/12.jpg)

Using the workbook created, we can see that there is an **Update** change that happened in the last 15 minutes.

   ![Screenshot showing an update change in the workbook](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/13.jpg)

By drilling into this change we can see that the **allowBlobPublicAccess** property was changed to "false" which explains why the developers lost access.

   ![Screenshot showing the allowPublicAccess property change](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/14.jpg)

   ![Screenshot showing the allowPublicAccess property change](https://images.seifbassem.com/images/Posts/Azure-Resource-Configuration-changes/15.jpg)

## Resources

- [Feature announcement](https://azure.microsoft.com/updates/public-preview-resource-configuration-changes/)
- Azure Resource configuration changes docs with multiple query examples can be found [here](https://docs.microsoft.com/azure/governance/resource-graph/how-to/get-resource-changes)