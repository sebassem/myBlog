---
title: "Azure Monitor workbooks - Query the cost of Unattached managed disks"
images:
  - "https://images.seifbassem.com/images/Posts/AzureAutomation-and-EndpointAnalytics/banner.jpg"
date: 2021-07-02 17:08:42 +0200
tags: ["Azure","Azure Monitor"]
categories: ["posts"]
draft: true

---

<!--more-->

# Azure Monitor Workbooks
Azure Monitor Workbooks is a great canvas that you can customize to display interactive information about your Azure environment , it provides you with various visualizations that match your needs and also provides very extensible sources of data that you can query. You can simply query a log analytics workspace or a metric or even a public weather API "if it makes sense to you 😄" which is very cool and opens up the door for very creative use cases.

In this series , i will try to share some creative examples of using workbooks to show it's capabilities and give you ideas on how to use this service. This post will show how we can inventory all managed disks that are not being used and show how much cost they have on my subscription.

## Listing all unattached managed disks
The first step is obviously to discover all the idle disks that are not attached to any VM , to understand where we can optimize costs as disks are billed even if they are not used. I will use an **Azure resource Graph** query to do that.

1. Add a Subscription Parameter
We will first add a parameter to select one or more subscriptions:
![alt](1.jpg)

2. Unattached disks inventory
Will query the subscription(s) specified in the parameter above
`
ResourceContainers | where type =~ 'Microsoft.Resources/subscriptions' | extend SubscriptionName=name | join (resources | where type =~ 'microsoft.compute/disks' and tostring (properties.diskState) == 'Unattached' and name !has '-ASRReplica' | extend DiskID=id, DiskName=name, SKUName=sku.name, SKUTier=sku.tier, DiskSizeGB=tostring(properties.diskSizeGB),ResourceGroupName=resourceGroup, Location=location, TimeCreated=tostring(properties.timeCreated))on subscriptionId 
| order by id asc 
| project DiskID,DiskName, DiskSizeGB, SKUName, SKUTier, ResourceGroupName, Location, TimeCreated, SubscriptionName
`
![alt](2.jpg)

Now we can see we have 2 disks that are not attached and we can see some information about them , like their resource group , creation date , size and tier as well but not the cost. Cost information is not available in Azure Resource Graph , so we will have to leverage the superpowers of workbooks to get this information from somewhere else.

3. Getting cost information for all disks
There is an [API endpoint](https://docs.microsoft.com/en-us/rest/api/cost-management/query/usage?WT.mc_id=modinfra-27678-socuff) that exposes usage data for Azure resources . You can try it directly in the documentation , it's showing us below all cost information related to all disks in our subscription.

![alt](3.jpg)

Adding this API request to our workbook , in this case we will use **Azure Resource Manager** as our query source. There is a great [article by Bill York](https://techcommunity.microsoft.com/t5/itops-talk-blog/customize-cost-data-visualizations-with-azure-workbooks-and/ba-p/2387779) on techcommunity explaining how to query this API in a workbook.

![alt](4.jpg)

As for the request body we will need to do some tweaking to query only disks and also get the cost of the last month so we can see the impact those disks have on our bill.

`
{
    "type": "Usage",
    "timeframe": "TheLastMonth",
    "dataset": {
      "granularity": "None",
	  "filter":{
		  "dimensions" : {
                      "name" : "resourceType",
                      "operator" : "In",
                      "values" : [
                         "microsoft.compute/disks"
                      ]
                  }
	  },
      "aggregation": {
       "totalCost": {
          "name": "PreTaxCost",
          "function": "Sum"
        }
      },
     "grouping": [
        {
         "type": "Dimension",
          "name": "ResourceId"
        }
      ]
    }
  }
`
Now let's try to run this query , it returns all the disks we have (attached and unattached) and shows their cost for last month as well.

![alt](5.jpg)

I will hide this query as it will be a supporting query that we don't want to show in our workbook by making this query conditionally visible using a variable.

![alt](6)

Now the last step would be to merge both queries we created to only list the costs of unattached disks. 

1. Merge query to get the cost of only unattached disks
I will add a third query , this time of type **Merge** and select the disk ID column to merge the queries we created to only show cost information for unattached disks.








