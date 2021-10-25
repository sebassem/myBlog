---
title: "Deploying an ARM template using Azure Monitor Workbooks"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/banner.png"
date: 2021-10-24 17:08:42 +0200
tags: ["Azure","Azure Monitor","Azure Workbooks"]
categories: ["Posts"]
draft: false
---

<!--more-->

In a [previous post](https://www.seifbassem.com/blogs/unboxing/introducing-Azure-Monitor-Workbooks/), i talked about Azure Monitor Workbooks and how useful they are to visualize and monitor your environment interactively by querying multiple sources and displaying the results in different visualizations.

The sky is the limit to what you can build with Workbooks and in this post i will demonstrate one of the cool capabilities that allows to deploy an ARM template right from within the Workbook using [Link actions](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-link-actions).

## Scenario
Let's assume that you are interested in looking at the governance posture of your environment, more specifically to your tagging compliance. You would like to be able to see all of the untagged Virtual machines and be able to take action by deploying a certain tag to them. Let's start creating a Workbook that will do just that 🚀.

1. First thing is to add some parameters to make our Workbook more usable.
   - Add a Subscription parameter.
      ![Subscription parameter](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/1.jpg)

- Add a Resource group parameter.
      ![Resource group parameter](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/2.jpg)
  
![Parameters view](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/16.jpg)

2. We also need to add parameters for the tags that we will deploy. Those will be text parameters.

![Tags parameters](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/7.jpg)

3. Next, we need to add a query to list all untagged Virtual machines. We will use Azure Resource Graph to list them.

![Untagged VMs query](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/3.jpg)

![Untagged VMs query view](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/4.jpg)

💡 You can see that i have added a new column named **DeployTag** which i will use later for the ARM template.

4.  Now, let's go to **Column Settings** where all the magic happens.
5.  Change the **Column renderer** of the "DeployTag" column to **Link**, choose the view to be **ARM Deployment** and type in a label for this link **Deploy Tag**(this will be the text displayed for each Virtual machine).

![Column settings - ARM Deployment](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/5.jpg)

6. Then we need to configure the ARM deployment settings:
   - Since this is an ARM deployment, we need to get the Resource group Id. It's already exposed in the Virutal machines' query in the column **resourceGroupID**.
   - Set the URI for the ARM template to a static value and provide it's URI (in my case I have it hosted on GitHub).
   - To refresh the view with the parameters of the ARM template, press on the arrow button to initialize the view. You can see that the preview is showing the parameters we have in the ARM template.
   
  ![ARM Deployment initialize](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/9.jpg)
   
   - Select where the parameters will come from, in our case the Virtual machine name is in the previous query and the tags are parameters.

   ![Column settings - ARM Deployment URI](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/6.jpg)

   - Finally, go to the **UX Settings** tab to provide descriptive text when you start the deployment process.

      ![Column settings - UX Settings](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/10.jpg)

      ![Column settings - UX Settings button](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/11.jpg)
  
- Save and Close.

## Testing the Workbook

- If we click **Done Editing** and view our Workbook, we can see that we have one Virtual machine that is untagged and we can see the **Deploy Tag** link in the query.

![Workbook final view](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/12.jpg)

- On clicking this link, we can see the context menu with information on what will this action deploy as we specified in the **UX Settings**

![Workbook deploy menu](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/13.jpg)

- The deployment process starts and in a couple of seconds, we can see that the tag is successfully deployed to the Virtual machine.

![VM with tag deployed](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/14.jpg)

![VM with tag deployed not showing in the query](https://images.seifbassem.com/images/Posts/Azure-Monitor-Workbooks-ARM/15.jpg)













