---
title: "Experimenting with Windows Virtual Desktop and Orchestration groups"
images:
  - "https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/banner.png"
date: 2020-09-10 17:08:42 +0200
tags: ["Azure Functions","Azure","Azure Virtual Desktop"]
categories: ["posts"]
draft: false
---

<!--more-->

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC2.gif)

# What we will do is as follows:
1. Create an Azure function that will enable/disable drain mode on the session hosts
2. Configure Configuration manager to manage Windows 10 multi-session session hosts and deliver updates
3. Prepare pre-update and post-update scripts that will trigger the azure function
4. Create a new Orchestration group that updates one session-host at a time with a specific order
5. Deploy updates and have orchestration groups do its magic

## Create an azure function to enable/disable drain mode
- We will create a new Http-triggered Azure function with PowerShell core as the runtime stack and function as the authorization method
- Create a managed identity for this function to assign permission to the resource group hosting the session hosts to be able to enable/disable drain-mode. For simplicity we will assign this identity as a contributor on the resource group
- 
![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC3.png)

- Next, we need to add the WVD PowerShell modules for the function to be able to load them automatically

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC4.png)

-Lastly, the function code would take the resource group, host pool, drain-mode status and session host name as parameters and disable/enable accordingly

 ![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC5.png)

 ## Configure Configuration manager to manage Windows 10 multi-session session hosts and deliver updates
Windows 10 multi-session is considered a server SKU, so we need to enable updates for Windows Server, version 1903 and later to allow for Windows 10 multi-session updates to be synchronized. More information is outlined [here](https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-automatic-updates)

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC6.gif)

Next, we create a collection to include our Windows 10 multi-session devices using [query](https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-automatic-updates#create-a-query-based-collection)

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC7.gif)

## Prepare pre-update and post-update scripts
We will need 2 scripts to trigger our azure function, the only difference is whether we are enabling or disabling drain mode

**Pre-Update script**
Invoke the azure function with a disable parameter to prevent new sessions on this session host till it is patched, and then output "Started update" in a log file to mark the start of the update

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC8.png)

**Post-Update script**
Invoke the azure function with an enable parameter to allow new sessions on this session host, and then output "Finished update" in a log file to mark the start of the update

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC9.png)

## Create a new Orchestration group that updates one session-host at a time with a specific order

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC10.gif)

## Deploy updates and have orchestration groups do its magic
Orchestration starts when any client in the group tries to install any software update at deadline or during a maintenance window. It starts for the entire group and makes sure that the devices update by following the orchestration group rules. So, we will deploy a software update to our WVD collection that we created earlier and see what happens on the client, configuration manager console and on the session host properties.

> If updates are initiated by users from Software Center, orchestration will be bypassed.

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC11.gif)

Checking that new sessions are allowed on all session hosts and the orchestration group's status before the update kicks in

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC12.png)

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC13.png)

Next, we wait till the session hosts refresh the policy and the update, you will notice that based on the order we selected in the orchestration group "CMpool1-2" gets the update first

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC14.png)

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC15.png)

Checking the MaintenanceCoordinator.log on the session host, we can see that the orchestration is happening, and the pre-script calling our azure function is being executed before the update

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC16.png)

Checking the drain mode on the session host, we can confirm that our function has executed and this host is not accepting any new hosts during the update

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC17.png)

The update has been deployed successfully and the host needs to reboot

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC18.png)

Checking the MaintenanceCoordinator.log again after the reboot, we can see that the post-script will run to call our Azure function and disable drain-mode and mark the end of maintenance for this host

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC19.png)

The session host "CMpool1-2" can now accept new sessions after being successfully patched

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC20.png)

The same process will continue on the rest of the 2 session hosts based on the order we specified in the orchestration group

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC21.png)

![Orchetrationgroup](https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/WVD-MEMC22.png)

# Recap
[Orchestration groups](https://docs.microsoft.com/en-us/mem/configmgr/sum/deploy-use/orchestration-groups) is a very cool pre-release feature of configuration manager , that can be used to automate the patching process for workloads that need specific tasks to be performed pre or post the patching process , also providing the ability to update devices based on a percentage, a specific number, or an explicit order.

