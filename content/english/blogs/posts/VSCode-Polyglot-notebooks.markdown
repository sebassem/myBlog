---
title: "Build PowerShell notebooks using VScode and Polyglot"
images:
  - "https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/banner.png"
date: 2023-11-25 17:08:42 +0200
tags: ["Azure","VS Code"]
categories: ["posts"]
draft: false
---

<!--more-->

Notebooks are interactive files that allow you to mix executable code, visualizations, equations, and narrative text. They are composed of code cells that make it easy to quickly iterate on code and document your work. Notebooks are popular among data scientists, machine learning engineers, and researchers, but they can be used by anyone for a variety of tasks, such as teaching, learning, and prototyping.

![Screeshot showing the final polyglot notebook](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/00.gif)

Notebooks are commonly used by data scientists and are typically used with Python which makes them not really useful for IT pros or developers. But now with Polyglot notebooks this is about to change. Let's explore what Polyglot notebooks bring to the table:

- Support for multiple languages: VS Code Polyglot Notebooks support a wide range of programming languages, including Python, C#, F#, PowerShell, JavaScript, SQL, and KQL (Kusto Query Language). This allows you to use the right language for the job, without having to switch between different notebooks.
- Native integration with Visual Studio Code: VS Code Polyglot Notebooks are native to Visual Studio Code, so you can take advantage of all the features that VS Code has to offer, such as code completion, syntax highlighting, and debugging.
- Better performance: VS Code Polyglot Notebooks are generally faster than Jupyter Notebooks, especially when working with large notebooks.
- More lightweight: VS Code Polyglot Notebooks are more lightweight than Jupyter Notebooks, making them easier to install and run on resource-constrained machines.

Let's explore how to use it to build a step-by-step guide on how to get all virtual machines in Azure using PowerShell and Azure Resource Graph.

## Preparing your machine to run Polyglot notebooks

You would need to install the VS Code (obviously😄), .Net SDK 7 and then add the extension. You can install all of this using Winget on Windows. I will also add the PowerShell extension to the mix

   ```shell
   winget install -e --id Microsoft.VisualStudioCode --no-upgrade
   winget install -e --id Microsoft.DotNet.SDK.7 --no-upgrade
   code --install-extension ms-dotnettools.dotnet-interactive-vscode
   code --install-extension ms-vscode.powershell
   ```

## Creating a new notebook

- Open VS Code and click File > Create New File > Polyglot notebook.

![Screeshot showing creating a new notebook](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/01.png)

- Choose the _dib_ extension (its faster and more lightweight)

![Screeshot showing creating a new notebook with dib extension](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/02.png)

- Choose the primary language, you want to use. I will choose PowerShell for this blog post.

![Screeshot showing creating a new notebook with Powershell as the main language](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/03.png)

- An empty notebook is created for us.

![Screeshot showing a new notebook](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/04.png)

- Lets start by adding some titles in markdown to explain what we will do.

![Screeshot showing adding an h1 header](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/05.png)

![Screeshot showing adding an h2 header](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/06.png)

![Screeshot showing adding an h2 header](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/07.png)

- Then we add the PowerShell code we need to install the Azure Resource Graph module.

```PowerShell
Install-Module -Name Az.ResourceGraph -Force -AllowClobber
```

![Screeshot showing adding an h2 header](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/08.png)

- I will repeat the same to add all the steps we need so the final result should look like this.

![Screeshot showing adding an h2 header](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/09.png)

- Now, for every PowerShell cell, we can click run to execute every step along the way.

![Screeshot showing executing the powershell script](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/10.png)

- We can also create variables which enabled us to share data between the different commands we are running. I will create a new variable to prompt for an Azure region and then use it in a PowerShell command.

```powershell
#!set --name location --value @input:"Please enter the Azure region"
Write-Host "You selected $location" -ForegroundColor Green
```

![Screeshot prompting for user input](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/11.png)

- Once I run this cell, I'm prompted by this message to get the variable's value.

![Screeshot prompting for user input](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/12.png)

![Screeshot the output of the PowerShell command with the user input](https://images.seifbassem.com/images/Posts/VsCode-Polyglot-notebooks/13.png)

## Recap

I hope you enjoyed this blog post on polyglot notebooks in vscode. Polyglot notebooks are a great way to combine different languages and frameworks in one interactive document. As an IT professional, you can use them for training purposes, interactive documentation, and more. If you want to learn more about polyglot notebooks, check out the official [documentation](https://devblogs.microsoft.com/dotnet/announcing-VsCode-Polyglot-notebooks-harness-the-power-of-multilanguage-notebooks-in-visual-studio-code/) and some examples on [GitHub](https://github.com/dotnet/interactive/tree/main/docs). Thanks for reading and happy coding.
