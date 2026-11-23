---
title: "Deploying Applications to Azure Virtual Desktop with Windows package manager"
images:
  - "https://images.seifbassem.com/images/Posts/AVD-Orchestration-Groups/banner.jpeg"
date: 2020-09-10 17:08:42 +0200
tags: ["Azure","Windows","Azure Virtual Desktop"]
categories: ["posts"]
draft: true
---

<!--more-->

# Windows very own package manager
Did you ever wish that installing applications in Windows 10 can be as easy as this?

*****6.gif

Windows has finally has got it's own package manager (winget) where you can easily install/uninstall/search/import/export applications without worrying about where to get or store their installation sources. It's still in it's early phases , [version 1.0 was announced](https://devblogs.microsoft.com/commandline/windows-package-manager-1-0/) in May 2021 but nontheless it's a very useful utility.

****5.jpg

To get started with it , you can install it using one of the following methods : 

- If you are using Windows Insider
- You can install the preview version of the [Windows App installer](https://www.microsoft.com/p/app-installer/9nblggh4nns1?ocid=9nblggh4nns1_ORSEARCH_Bing&rtc=1&activetab=pivot:overviewtab)
  
*****1.jpg

- You can install it from it's [GitHub repo](https://github.com/microsoft/winget-cli/releases) manually.
*****1.jpg
Ok , so now what does this have to do with Azure Virtual Desktop ?!!🤔
*****2.jpg
*****3.jpg

# Application management in Azure Virtual Desktop
When using AVD , you need to think about how to deliver applications to your users as there are multiple ways to achieve that based on your requirements and deployment scenario. Currently you can do MSIX app attach , remote app streaming , include applications in your golden image or even deploy them using Endpoint manager. 

In this post i will focus on the golden image scenario and particularly using Azure Image Builder(AIB) which is a great tool for automating the process of image creation, building , updating and distribution.
When using AIB , you have a JSON template where you define how you would like the image to be built , by running PowerShell scripts , shell commands , creating files and folders , restart commands and installing updates. Having said that , you can use the shell commands and PowerShell scripts to install all the applications you need for your users during the image build process by hosting their binaries some where and adding PowerShell scripts to download and install them to your image. The challenge i see with this approach is that you need to maintain the applications sources and keep them up-to-date when new versions are available and also it provides some complexity to manage the scripts you would need to install them correctly . 

## Using Windows Application Manager with Azure Image Builder
I will try to use the magic of winget to seamlessly install and manage applications in the AIB process , let's see how this goes 👀

### Applications needed
My AVD users , will need the following applications:
- VSCode
- Google Chrome
- Firefox
- Git
- Notepad++ "will need to fix on the latest version"
- WinRAR
- PowerBI

1. Prepare the applications
   Using Winget you have multiple ways to install your applications , you can simply type `winget install Notepad++` then `winget install VSCode` and add all of those commands to your AIB PowerShell command or even better you can create JSON template specifying your applications with all needed metadata like versions , publishers and custom switches. I will use the second option to make things easier to maintain , will create a [JSON template](https://aka.ms/winget-packages.schema.1.0.json) and store it in a GitHub repo.

****7.jpg

1. Build the AIB image
   I will follow the basic process for preparing AIB outlined [here](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder)

2. Customizing the image template file
   First thing , i will change the default template image to use Windows 10 Multisession with Microsoft 365 Apps
   *****8.jpg
   Then i will start modifying the AIB customizers as follows ;
   - Creating a new folder to store all downloads
    ***9.jpg
   - Download Winget pre-requisites , download Winget , the applications refernece file
   ****10.jpg
   - Install pre-requisites and Winget and then restart
  *****11.jpg 
   - Then run Winget to install all applications in the reference file
  *****12.jpg
   - Finally , will add a step to check and install any missing updates
  *****13.jpg

3. Now , let's build this image and create a new HostPool and see what our users will get





For more in-depth overview of the Windows Package manager see this cool vide from Sarah Lean

https://www.techielass.com/how-to-install-winget-windows-package-manager/
