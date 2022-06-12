---
title: "SSH into your Azure Arc-enabled servers from anywhere"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/banner.png"
date: 2022-06-12 17:08:42 +0200
tags: ["Azure","Azure Arc"]
categories: ["posts"]
draft: false
---

<!--more-->

A new capability has been introduced for Azure Arc-enabled servers which allows you to SSH into your Windows/Linux servers from anywhere without requiring inbound ports or public IP addresses. While its in preview, it can allow you to SSH to Windows using a local user and to Linux using an Azure user. This capability can become handy if you want to grant your team access to those servers from any location without going through the hassle of opening ports on your firewalls or raising any security concerns.

## Feature requirements

To start using this feature, we need to perform the following steps:

1. Register the _HybridConnectivity_ resource provider
2. Onboard the server to Azure Arc
3. Create the default endpoint for this Azure Arc-enabled server
4. Assign the user to connect with the _Virtual Machine Local User Login_ role
5. Enable the _sshd_ service (for Windows, we need to install OpenSSH)
6. Enable the SSH feature on the Azure Arc-enabled server using the _azcmagent_ command.

If you have a couple of servers, it can be ok to do those steps (specially 1-4) manually, but if you have 10s or 100s of servers and you want to enable it at scale then we need some sort of automation. I have a Hyper-V Windows server on my laptop that is Azure Arc-enabled ready to test this deployment.

  ![Screenshot showing the Hyper-v console](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/01.jpg)

  ![Screenshot showing Azure portal with Azure Arc-enabled server](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/02.jpg)

## At scale deployment of SSH on Arc-enabled Windows servers

First lets assign the _Virtual Machine Local User Login_ role to a normal user in my tenant.

  ![Screenshot showing an RBAC permission assigned](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/03.jpg)

Next, we need to populate the default connectivity endpoint for this Arc-enabled server.

  ![Screenshot showing CLI creating the defauly connectivity endpoint ](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/04.jpg)

Since this server is Windows, we would need to install _OpenSSH_ to have the needed _sshd_ service and then run the _azcmagent_ command to enable the SSH feature. To do this at scale, I'm going to use one of the capabilities that Azure Arc provides for servers which is VM extensions to install _OpenSSH_ and configure the agent.

 ```PowerShell
 $Setting = @{ "commandToExecute" = "powershell.exe -c Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0;Start-Service sshd;Set-Service -Name sshd -StartupType 'Automatic';azcmagent config set incomingconnections.ports 22" }

New-AzConnectedMachineExtension `
    -MachineName "WIN-S0EJKBIMSJL" `
    -name "SSHConfig" `
    -location "eastus" `
    -ExtensionType CustomScriptExtension `
    -publisher "Microsoft.Compute" `
    -settings $Setting `
    -ResourceGroupName "Arc-Win-Servers" `
 ```

  ![Screenshot showing the VM extension installation](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/05.jpg)

> _OpenSSH_ is available as an extension that you can install directly. I will install it manually using PowerShell as I need to configure the agent and install the _sshd_ service in one go.

  ![Screenshot showing the OpenSSH vm extension in the Azure portal](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/06.jpg)

We can see that the extension has been deployed successfully.

  ![Screenshot showing the vm extension installed](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/07.jpg)

## Connecting to the Azure Arc-enabled server using SSH

I will login in CLI using the user assigned with the _Virtual Machine Local User Login_ role.

  ![Screenshot showing the clark kent user](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/08.jpg)

Now trying to SSH into the Azure Arc-enabled server from CLI, I get prompted with the password of the local user and then I get into the machine using SSH.

  ![Screenshot showing the clark kent user SSH to the VM](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/09.jpg)

  ![Screenshot showing the clark kent user SSH to the VM](https://images.seifbassem.com/images/Posts/Azure-Arc-SSH/10.jpg)

## References

- If you want to have an automated demo of this feature, check out this [Azure Arc Jumpstart scenario](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/day2/arc_ssh/).
- [Feature documentation](https://docs.microsoft.com/azure/azure-arc/servers/ssh-arc-overview)
