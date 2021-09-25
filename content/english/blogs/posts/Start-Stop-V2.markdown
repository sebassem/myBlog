---
title: "Automatic start/stop of virtual machines to save cost V2"
images:
  - "https://images.seifbassem.com/images/Posts/Start-Stop-V2/banner.png"
date: 2021-09-24 17:08:42 +0200
tags: ["Azure","Cost Management"]
categories: ["posts"]
draft: false
---

<!--more-->

The cloud gives you infinite scale and scalability, and with this great amount of scale, comes the responsibility and the need for better cost management. Running virtual machines 24/7 if not needed can incur unnecessary costs on your bill, examples would be testing/development machines or services that need to be run on-demand or seasonally for specific tasks.
In Azure, you can use different methods to solve this issue but today i will examine a redefined built-in solution that can help automate the starting and stopping of virtual machines across your environment based on different criteria.

## Start/stop V1
When V1 of this solution was first introduced, it relied on Azure Automation and Log Analytics. The new version now uses Azure Functions and Logic Apps instead, it still provieds the same capabilities but using newer technologies in Azure.

![V1](https://images.seifbassem.com/images/Posts/Start-Stop-V2/19.jpg)

## V2 deployment
To start deploying the new version, you need to go to this [GitHub repo](https://github.com/microsoft/startstopv2-deployments) and deploy to Azure.

![deployment](https://images.seifbassem.com/images/Posts/Start-Stop-V2/1.jpg)

Fill in the required parameters following your naming conventions

![Parameters](https://images.seifbassem.com/images/Posts/Start-Stop-V2/2.jpg)

This shouldn't take long ⏲️

![Parameters](https://images.seifbassem.com/images/Posts/Start-Stop-V2/4.jpg)
![Parameters](https://images.seifbassem.com/images/Posts/Start-Stop-V2/5.jpg)

We get 5 logic apps that have all the orchestrate the functionality of this solution and an Azure function with managed identity enabled.
1. **ststv2_vms_Scheduled_start:** auto-start of VMs based on a schedule   
2. **ststv2_vms_Scheduled_stop:** auto-stop of VMs based on a schedule     
3. **ststv2_vms_Sequenced_start:** auto-start of VMs based on a schedule and order defined by tags
4. **ststv2_vms_Sequenced_stop:** auto-stop of VMs based on a schedule and order defined by tags
5. **ststv2_vms_AutoStop:** auto-stop of VMs if processor utilization is less than a specified percentage

Also contributor permissions for this managed identity is automatically granted on the subscription level.

![RBAC permissions](https://images.seifbassem.com/images/Posts/Start-Stop-V2/14.jpg)

> 💡 To [control virtual machines in other subscriptions](https://docs.microsoft.com/en-us/azure/azure-functions/start-stop-vms/deploy#enable-multiple-subscriptions), you would need to grant contributor permission to the managed identity on those subscriptions.

I have created 3 virtual machines to test those different logic apps.

![VMs](https://images.seifbassem.com/images/Posts/Start-Stop-V2/6.jpg)

### Scheduled start/stop
Since the machines are turned-off, let's start with the auto-start capability. We go to the **ststv2_vms_Scheduled_start** logic app and edit it to configure the right schedule. We start first by editing the **recurrence** step to specify when this logic app will be triggered. In this case 6:00AM every day.
![auto-start](https://images.seifbassem.com/images/Posts/Start-Stop-V2/7.jpg)

Then we edit the **Scheduled** step which has an Azure function to execute this auto-start capability. We can scope this logic app to different scopes as follows:
- **Subscription scope:** Any virtual machine in this subscription(s) will get started based on the schedule
  ![subscription scope](https://images.seifbassem.com/images/Posts/Start-Stop-V2/9.jpg)
- **Resource group scope:** Any virtual machine in this resource group(s) will get started based on the schedule
  ![resource group scope](https://images.seifbassem.com/images/Posts/Start-Stop-V2/8.jpg)
- **Virtual machine scope:** Only the listed virtual machine(s) will get started based on the schedule
  ![resource group scope](https://images.seifbassem.com/images/Posts/Start-Stop-V2/20.jpg)

> 💡 You can also exclude certain virtual machines in any of the subscription or resource group scopes.
  ![Exclusions](https://images.seifbassem.com/images/Posts/Start-Stop-V2/10.jpg)

This is all what is needed to configure the auto-start logic app, then we enable it and wait for the trigger to execute.

![Enable logic app](https://images.seifbassem.com/images/Posts/Start-Stop-V2/15.jpg)

![Start VMs](https://images.seifbassem.com/images/Posts/Start-Stop-V2/16.jpg)

### Sequenced start/stop
The above logic app is useful if there is no need for the machines to be started/stopped in a particular order, but what if there was ? We have another logic app pair that allows us to do just that; ststv2_vms_Sequenced_start and ststv2_vms_Sequenced_stop.

They are basically the exact same configuration but you will notice a new value in the Azure Function step "Sequenced:true"

![Sequenced](https://images.seifbassem.com/images/Posts/Start-Stop-V2/11.jpg)

To set the order, we would need to add specific tags to the machines within our scope to help the Azure Function to understand which machines to start first. In this example i will set the order as follows:
1. VM001
2. VM003
3. VM002

![VM001](https://images.seifbassem.com/images/Posts/Start-Stop-V2/12.jpg)

![VM003](https://images.seifbassem.com/images/Posts/Start-Stop-V2/13.jpg)

![VM002](https://images.seifbassem.com/images/Posts/Start-Stop-V2/21.jpg)

Then we enable the logic app and wait for the trigger.

![sequenced stop enable](https://images.seifbassem.com/images/Posts/Start-Stop-V2/17.jpg)

We can see that the VMs start in the order we have specified.
![sequenced stop](https://images.seifbassem.com/images/Posts/Start-Stop-V2/18.jpg)

### Idle VM shutdown
Finally, this solution allows also to stop virtual machines that have CPU utilization below a specific threshhold. It creates a metric alert based on our inputs to turn off those machines.

We can see that the logic app is a little bit different with more parameters to be set for the Azure Function to create a metric alert

![CPU stop](https://images.seifbassem.com/images/Posts/Start-Stop-V2/22.jpg)

**-The parameters we need to configure:**
- **AutoStop_Frequency:** The evaluation frequency for this metric rule
- **AutoStop_MetricName:** the metric we want to evaluate, in our scenario "CPU"
- **AutoStop_Threshold:** the threshhold for the metric value; shutdown if CPU is less than this threshhold
- **AutoStop_TimeAggregationOperator:** aggregation for this metric; average, maximum, minimum,...etc
- **AutoStop_TimeWindow:** The window size over which Azure will analyze selected metric for triggering an alert; the time window looking back for this metric

Once this is enabled and the trigger is executed, a metric alert will be created which checks the virtual machine(s) based on the above parameters and will shutdown the machines if they are below this CPU threshhold.

> 💡 Most probably you would need to target different sets of virtual machines in your environment and a single logic app wouldn't be convenient, you can simply duplicate the logic apps that you need and configure different schedules/parameters as needed.

### Monitoring
As part of this solution deployment, a dashboard is created to allow for monitoring the start/stop of virtual machines and the failure/success attempts for troubleshooting. Also emails are configured to be sent to notify admins on start/stop activities.

![Dashboard](https://images.seifbassem.com/images/Posts/Start-Stop-V2/23.jpg)

### Recap
This is a very useful solution to automate starting/stopping virutal machines based on schedules or CPU utilization, i find this solution much easier than the previous one based on Azure Automation even if it provides the same functionality.

**V1 solution:** https://docs.microsoft.com/en-us/azure/automation/automation-solution-vm-management

**V2 solution:** https://docs.microsoft.com/en-us/azure/azure-functions/start-stop-vms/overview 