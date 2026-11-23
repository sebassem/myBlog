---
title: "Build your own custom copilot for Azure!!"
images:
  - "https://images.seifbassem.com/images/Posts/custom-Azure-copilot/banner.png"
date: 2024-01-20 17:08:42 +0200
tags: ["Azure","AI","Open AI","Copilot"]
categories: ["posts"]
draft: false
---

<!--more-->

## Large language models (LLMs) taking the world by storm

Large language models, such as those developed by OpenAI, are advanced artificial intelligence systems designed to understand and generate human-like text based on vast amounts of training data. OpenAI's language models are particularly noteworthy for their immense scale, boasting billions of parameters. These models have the capability to comprehend context, generate coherent responses, and perform a wide array of natural language processing tasks, including text completion, translation, summarization, and more (just like this past paragraph 😄).

There is an infinite number of scenarios and applications of large language models for developers like building smart agents for a travel agency that you can just tell it what you want and it can go and book your entire trip or creating a medical chatbot that understands natural human language or even an AI-enhanced social media manager that can manage your whole social media accounts.

**TL;DR Watch a quick demonstration on what we will build in this post**

![Screenshot showing a demonstration on what we will build](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/00.gif)

## Searching for a good application of LLM in the cloud world 👀

As a cloud architect (working mainly with Azure), I started to look for ways I can follow the innovation happening and build something for Azure using LLMs. After weeks of thinking, I could only think of numerous ideas but not related to Azure. Until Microsoft released *copilot for Azure* which allows you to simply chat with Azure using human language and ask it for things like inventorying your environment, searching for a specific resource, understanding your azure spend or even the performance of one of your Azure resources.

The way it works in a very shallow way is by translating your ask to an azure resource graph query and execute it. It of course can do more magical stuff, but this is usually how it does its magic. I will add a video to the resources for a more technical walkthrough of how it works.

## Now I'm on to something 🕵️

I started reading the Open AI documentation to understand its APIs and how to use them until I got exposed to the *function calling* concept which immediately struck me💡. If you think about how LLMs work in a simple way, they are trained on a large set of data, so they can answer or come up with answers usually from that data (they lack external interaction). If you ask it a question about something that happened on a date after the date of its training data, it won't be able to answer you.

![Screenshot showing asking chatgpt a question](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/01.png)

Another limitation is that it cannot natively connect to your data or you systems, so If you ask it what is a resource group it will definitely provide an answer but if you ask it what resources are in a specific resource group in one of your subscriptions, it won't be able to provide an answer.

![Screenshot showing chatgpt not being able to answer a question about azure resources](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/02.png)

The only way to overcome this is to either open up the AI model on the internet so it can search for information it wasn't trained on or (more interestingly) give it a hand with function calling.

## OpenAI Function Calling: Empowering Large Language Models with functions

OpenAI’s function calling is a feature that allows you to connect large language models to external tools. It enables you to describe functions and have the model intelligently choose which functions and their arguments to call to be able to answer your query.

Function calling solves several problems, including the ability to more reliably get structured data back from the model and take actions. For example, you can create assistants that answer questions by calling external APIs, convert natural language into API calls, and extract structured data from text.

The basic sequence of steps for function calling is as follows:

- Call the model with the user query and a set of functions defined by you (no code is needed at that stage, just some metadata around those functions so the LLM knows when and how to call them when it's stuck).
- The model can choose to call one or more functions; if so, the model will return the function name it needs to ask for help and the parameters it needs extracted from the user's question.
- Once the function(s) execute(s) and returns its response, the model will be called again by appending the function response as a new message, and it will summarize the results back to the user.

![Screenshot showing Open AI function calling flow](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/03.png)

## Bringing it all together 🧠

Given the previous context, what we will try to do this post is to leverage Open AI function calling to create a very basic assistant that can answer governance questions around my Azure environment.

High-level architecture:

1. We will first use Open AI Apis to create an *Azure governance* assistant.
2. We will provide this assistant with the most common tools/functions that it might need to be able to answer governance questions.
3. We will create an Azure function that will serve as a platform to execute the functions called by the AI assistant.
4. A key vault to store the Open AI Api key to be accessed from the Azure function.

## Building the AI assistant step-by-step

### Building the Azure governance assistant

While we can interact with the Open AI Api using Api calls, there is another easier way leveraging the great work by *MVP Doug Finke* who created an amazing PowerShell module that acts as a wrapper on top of the API which we will use.

- First, we need to generate an Api key from Open AI.

![Screenshot showing create an open ai Api key](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/04.png)

- To keep the key secure in the PowerShell code, I will use the *secret management* module to store it safely.

```powershell
## Installing the module
Install-Module Microsoft.PowerShell.SecretManagement
Install-Module Microsoft.PowerShell.SecretStore
## Importing the secret store module
Import-Module Microsoft.PowerShell.SecretStore
## Registering a new vault of type local, we can register different types of vaults here.
Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
## Storing the secret in the newly created vault
Set-Secret -Name OpenAIKey -Secret "<MY API KEY>"
## Retrieving the secret from the vault (We will need to remove it from the environment variables of course to keep it secure)
$env:OPENAI_API_KEY = Get-Secret -Name OpenAIKey -AsPlainText
```

- We also need to install the PowerShell AI module.

```powershell
## Installing the module
Install-Module -Name PSOpenAI
## Importing the PSOpenAI module
Import-Module PSOpenAI
```

- To create an Open AI assistant, we need to run the following code (this is what you would usually run if there were no tools/functions being provided).

```PowerShell
## Create an assistant
$Assistant = New-Assistant -Name "AzureGovernanceAssistant" -Model "gpt-3.5-turbo-1106" -Instructions "You are an assistant that helps answer questions around Azure resources and help improve the governance posture of an azure environment." -ApiKey $openAIKey
```

Creating the assistant like this will only use the data information that the model was trained on. We need to pass an additional parameter to let the model know that it has some additional tools/functions it can use if it gets stuck. Let's first define the functions we want to provide the model with.

We will create the following functions:

  - **getResourcesByTag :** This function will get all azure resources for a specific workload. This is done by the value of a workload tag that I have enforced on my azure resources.
  - **getAzureResourceRecommendations :** This function will get azure advisor recommendations for a resources. You can also specify what category of recommendation you need (Security | Cost | HighAvailability | OperationalExcellence | Performance).
  - **getResourceDetailsById :** This function will get all resource properties for an azure resource by its Id.
  - **getResourcesByResourceGroup :** This function will get all resource properties for an azure resource by its resource group.

>**NOTE: This is just a sample of what you can do, additional functions can be provided and you can even have functions that can take actions on your azure environment**

```PowerShell
$tools = @(
    @{
        "type"     = "function"
        "function" = @{
            "name"        = "getAzureResourceRecommendations"
            "description" = "Gets available recommendations and best practices for one resource by the resource Id. If the category is not provided, the default category should be Security. If multiple resources are provided as input, this function can be run multiple times per resource"
            "parameters"  = @{
                "type"       = "object"
                "properties" = @{
                    "resourceId" = @{
                        "type"        = "string"
                        "description" = "The resource id of the azure resource to get recommendations for."
                        "items"       = @{
                            "type" = "string"
                        }
                    }
                    "Category"   = @{
                        "type"        = "string"
                        "description" = "The category of the azure advisor recommendation. It can be Cost, HighAvailability, Performance, Security, or OperationalExcellence"
                        "items"       = @{
                            "type" = "string"
                        }
                    }
                    "resourceGroupName"   = @{
                        "type"        = "string"
                        "description" = "The name of the resource group to get recommendations for."
                        "items"       = @{
                            "type" = "string"
                        }
                    }
                }
                "required"   = @("resourceId")
            }
        }
    }
    @{
        "type"     = "function"
        "function" = @{
            "name"        = "getResourceDetailsById"
            "description" = "Gets all resource details and properties by its resource id."
            "parameters"  = @{
                "type"       = "object"
                "properties" = @{
                    "resourceId" = @{
                        "type"        = "string"
                        "description" = "The resource Id"
                    }
                }
                "required"   = @("resourceId")
            }
        }
    }
    @{
        "type"     = "function"
        "function" = @{
            "name"        = "getResourcesByResourceGroup"
            "description" = "Returns all resources and their properties in a specific resource group."
            "parameters"  = @{
                "type"       = "object"
                "properties" = @{
                    "resourceGroupName" = @{
                        "type"        = "string"
                        "description" = "The resource group name"
                    }
                }
                "required"   = @("resourceGroupName")
            }
        }
    }
    @{
        "type"     = "function"
        "function" = @{
            "name"        = "getResourcesByTag"
            "description" = "Gets a resource by the value of the workload tag it has assigned and also the resource type if provided. The input for this function is the name of the workload or the name of the project. The input can also contain a resource type."
            "parameters"  = @{
                "type"       = "object"
                "properties" = @{
                    "tagValue"     = @{
                        "type"        = "string"
                        "description" = "The value of the tag"
                    }
                    "resourceType" = @{
                        "type"        = "string"
                        "description" = "The resource type"
                    }
                }
                "required"   = @("tagValue")
            }
        }
    }
)
```

- As you can see, there is no code here, no Azure PowerShell/CLI, just metadata. Let's take one function definition and understand what's there.

```PowerShell
{
        "type"     = "function"
        "function" = @{
            "name"        = "getResourceDetailsById"
            "description" = "Gets all resource details and properties by its resource id."
            "parameters"  = @{
                "type"       = "object"
                "properties" = @{
                    "resourceId" = @{
                        "type"        = "string"
                        "description" = "The resource Id"
                    }
                }
                "required"   = @("resourceId")
            }
        }
    }
```

In this function definition, we have the following properties:

- **Name :** The function name, this is the name where Open AI will respond with if it needs to call this function.
- **Description :** The is the most important property, as this is how the model determines if it needs to call that function to answer the query or part of it. This needs to be very descriptive to achieve higher levels of accuracy.
- **Parameters :** This is where you define the parameters that this function expects, some of the parameters might be required and some might be optional. The model will extract those parameters from the user's query.

- Now, to properly create the assistant, we will run the previous command with the *tools* switch and pass the *tools* variable with all our functions definitions.

```PowerShell
$Assistant = New-Assistant -Name "AzureGovernanceAssistant" -Model "gpt-3.5-turbo-1106" -Instructions "You are an assistant that helps answer questions around Azure resources and help improve the governance posture of an azure environment." -ApiKey $openAIKey -tools $tools
```

- Once we run this command, we can look at the Open AI dashboard to see our newly created assistant.

![Screenshot showing a created AI assistant on the Open AI portal](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/05.png)

- We are now ready to start interacting with the AI assistant. We will first test it out in PowerShell locally then we will integrate it into a bot. To do this locally, we need to define the code of those functions, later on  we will do this in an azure function.

```PowerShell
function getAzureResourceRecommendations {
    param(
        [Parameter(Mandatory = $true)]
        [string]$resourceId,
        [Parameter(Mandatory = $false)]
        [string]$category = "Security",
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroupName
    )

    if ($null -ne $resourceGroupName) {
        $output = Get-AzAdvisorRecommendation -ResourceGroupName $ResourceGroupName -Category $category |
        Select-Object -Property @{
            Name       = 'Description'
            Expression = { $_.ShortDescriptionSolution }
        }, @{
            Name       = 'AffectedResourceId'
            Expression = { $_.ResourceMetadataResourceId }
        }, ResourceGroupName, @{
            Name       = 'ResourceType'
            Expression = { $_.ImpactedField }
        } | ConvertTo-Json -Depth 10

        if ($null -eq $output) {
            $output = "No recommendations found for the resource group $ResourceGroupName"
        }
    }
    else {
        $output = Get-AzAdvisorRecommendation -ResourceId $resourceId -Category $category |
        Select-Object -Property @{
            Name       = 'Description'
            Expression = { $_.ShortDescriptionSolution }
        }, @{
            Name       = 'AffectedResourceId'
            Expression = { $_.ResourceMetadataResourceId }
        }, ResourceGroupName, @{
            Name       = 'ResourceType'
            Expression = { $_.ImpactedField }
        } | ConvertTo-Json -Depth 10

        if ($null -eq $output) {
            $output = "No recommendations found for the resource $resourceId"
        }
    }

    return $output
}
function getResourceDetailsById {
    param(
        [Parameter(Mandatory = $true)]
        [string]$resourceId
    )
    Get-AzResource -ResourceId $resourceId | Select-Object Name, ResourceType, ResourceGroupName, ResourceId, Tags, Location, Sku, plan, Kind | ConvertTo-Json -Depth 10
}

function getResourceByResourceGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$resourceGroupName
    )
    Get-AzResource -ResourceGroupName $resourceGroupName | Select-Object Name, ResourceType, ResourceGroupName, ResourceId, Tags, Location, Sku, plan, Kind , Properties | ConvertTo-Json -Depth 10
}

function getResourcesByTag {
    param(
        [Parameter(Mandatory = $false)]
        [string]$tagName = "Workload",
        [Parameter(Mandatory = $true)]
        [string]$tagValue,
        [Parameter(Mandatory = $false)]
        [string]$resourceType
    )
    if ($null -ne $resourceType) {
        Get-AzResource -Tag @{ $tagName = $tagValue } | Where-Object { $_.ResourceType -like "*$resourceType*" } |  Select-Object Name, ResourceType, ResourceGroupName, ResourceId, Location, Tags , Properties | ConvertTo-Json -Depth 10
    }
    else {
        Get-AzResource -Tag @{ $tagName = $tagValue } | Select-Object Name, ResourceType, ResourceGroupName, ResourceId, Location, Tags , Properties | ConvertTo-Json -Depth 10
    }
}
```

- To interact with an assistant, the first thing we need to create is a *Thread*, think of it as a new chat session with a chatbot. This session remembers all the conversation with the user until this session expires or is closed. Let's create a new thread and add our first message asking about the resources in a workload named *Sierra*

```PowerShell
$Thread = New-Thread
$Thread = $Thread | Add-threadMessage -message "what resources do I have in the Sierra workload?" -passThru
```

- We now need to run the assistant to start answering this question. As you can see below, the model returns a status of *requires_action* as it cannot answer this query on the data it was trained on, it also passes the function name that it thinks can help along with the parameters it extracted from the user's query.

```powershell
## Run the assistant
$run = start-ThreadRun -thread $Thread -assistant $Assistant

## Get the run results once completed
$run = $run | wait-threadRun

## If the model cannot answer the question or part of it, it will look for tools/functions it has. This is defined by a run status of "requires_action"
if ($run.status -eq "requires_action") {
    ## Get function name needed to run
    $functionName = $run.required_action.submit_tool_outputs[0].tool_calls.function.name
    ## Get function parameters extracted by the model
    $functionParams = $run.required_action.submit_tool_outputs.tool_calls.function.arguments
    Write-Host "Calling function : $functionName"
    ## Convert the function parameters to a hashtable
    $functionParams = $functionParams | ConvertFrom-Json -asHashtable
    ## Execute the function with the passed parameters by using splatting
    $functionOutput = & $functionName @functionParams
    ## Capture the output of the function execution
    $toolsOutput = @(
        @{
            "tool_call_id" = $run.required_action.submit_tool_outputs.tool_calls.id
            "output"       = $functionOutput | ConvertTo-Json -Depth 10
        }
    )
    ## Submit the function's output back to the model and wait for a response
    Submit-ToolOutput $run -ToolOutput $toolsOutput
    $run = $run | wait-threadRun
}
if ($run.status -eq "in_progress") {
    $run = $run | wait-threadRun
}
## Return the model's response after it received the function's output
$Thread = $Run | Receive-ThreadRun
$messages = $Thread.Messages.SimpleContent.Content
$messages[$messages.length - 1]
```

![Screenshot showing the model calling the getResourcesByTag function](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/06.png)

We can see that the model knows it needs to call the *getResourcesByTag* function and provides the parameter *Sierra* as the workload. This shows the power of LLMs as it understands my natural language query and can translate it to structured data I can use to do more operations with it. We can see the response below after the model gets the JSON data returned by the function.

![Screenshot showing the model returning the response](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/07.png)

![Screenshot showing the azure portal with the sierra tag](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/08.png)

- I can continue to ask follow-up questions since we are on the same thread, the model remembers the previous context. Asking it *Do I have any recovery services vaults in project Sierra?*

```powershell
$Thread = $Thread | Add-threadMessage -message "Do I have any recovery services vaults in project Sierra?" -passThru

## Run the assistant
$run = start-ThreadRun -thread $Thread -assistant $Assistant
## Get the run results once completed
$run = $run | wait-threadRun
if ($run.status -eq "requires_action") {
    $functionName = $run.required_action.submit_tool_outputs[0].tool_calls.function.name
    $functionParams = $run.required_action.submit_tool_outputs.tool_calls.function.arguments
    Write-Host "Calling function : $functionName with parameters: $functionParams"
    $functionParams = $functionParams | ConvertFrom-Json -asHashtable
    $functionOutput = & $functionName @functionParams
    $toolsOutput = @(
        @{
            "tool_call_id" = $run.required_action.submit_tool_outputs.tool_calls.id
            "output"       = $functionOutput | ConvertTo-Json -Depth 10
        }
    )
    Submit-ToolOutput $run -ToolOutput $toolsOutput
    $run = $run | wait-threadRun
}
if ($run.status -eq "in_progress") {
    $run = $run | wait-threadRun
}
$Thread = $Run | Receive-ThreadRun
$messages = $Thread.Messages.SimpleContent.Content
$messages[$messages.length - 1]
```

![Screenshot showing the model answering the question on the recovery services vault](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/09.png)

### Create a more intuitive chatbot using our new AI assistant

We can continue to chat with the assistant using PowerShell but let's make it a little bit more scalable by using a very simple UI for a chatbot and creating an Azure function where our functions can run once the assistant needs help.

- I will create an Azure function app with PowerShell as it's runtime stack. We will need to add some PowerShell modules to our runtime so we are able to call the Open AI Apis, this can be done by adding the needed modules in the *requirements.psd1* file.

![Screenshot showing adding the needed modules for the azure function](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/10.png)

- We also need to securely store and access the Open AI Api key, we can use key vault for that purpose.

![Screenshot showing a keyvault secret for storing the open ai Api key](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/11.png)

![Screenshot showing the azure function key vault reference](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/12.png)

- We can easily reference this secret from the azure function app configuration.

![Screenshot showing the azure function key vault reference in the azure function settings](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/13.png)

- Next, we need to create a function with an HTTP trigger to be able to call it from the model.

![Screenshot showing the azure function for a new message](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/14.png)

After the function is created, we need to add the following code which does the following:

- The function will be triggered once there is a new message from the user.
- The function will take that message and threadId, it will fetch this thread, add the message to the thread and run the assistant to provide an answer.
- The function will also have all the code for the tools/functions defined in the assistant as this is the platform where our azure PowerShell code will be executed.
- Once the right function executes, our azure function will pass the response back to the model so it can be summarized and passed back to the user in the chatbot.

The code would look like this:

```powershell
using namespace System.Net

param($Request, $TriggerMetadata)

## Retrieving the Open AI Api key from the function app configuration
$env:OPENAI_API_KEY = $env:open_ai_key

## Defining the azure powershell functions that will run
function getAzureResourceRecommendations {
    param(
        [Parameter(Mandatory = $true)]
        [string]$resourceId,
        [Parameter(Mandatory = $false)]
        [string]$category = "Security"
    )
        $output = Get-AzAdvisorRecommendation -ResourceId $resourceId -Category $category |
        Select-Object -Property @{
            Name       = 'Description'
            Expression = { $_.ShortDescriptionSolution }
        }, @{
            Name       = 'AffectedResourceId'
            Expression = { $_.ResourceMetadataResourceId }
        } | ConvertTo-Json -Depth 10

        if ($null -eq $output) {
            $output = "No recommendations found for the resource $resourceId"
        }
    return $output
}

function getResourceDetailsById {
    param(
        [Parameter(Mandatory = $true)]
        [string]$resourceId
    )
    Get-AzResource -ResourceId $resourceId | Select-Object Name, ResourceType, ResourceGroupName, ResourceId, Tags, Location, Sku, plan, Kind | ConvertTo-Json -Depth 10
}

function getResourceByResourceGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$resourceGroupName
    )
    Get-AzResource -ResourceGroupName $resourceGroupName | Select-Object Name, ResourceType, ResourceGroupName, ResourceId, Tags, Location, Sku, plan, Kind , Properties | ConvertTo-Json -Depth 10
}

function getResourcesByTag {
    param(
        [Parameter(Mandatory = $false)]
        [string]$tagName="Workload",
        [Parameter(Mandatory = $true)]
        [string]$tagValue,
        [Parameter(Mandatory = $false)]
        [string]$resourceType
    )
    if($null -ne $resourceType){
        Get-AzResource -Tag @{ $tagName = $tagValue } | Where-Object {$_.ResourceType -like "*$resourceType*"} |  Select-Object Name, ResourceType, ResourceGroupName, ResourceId, Location, Tags , Properties | ConvertTo-Json -Depth 10
    }
    else{
        Get-AzResource -Tag @{ $tagName = $tagValue } | Select-Object Name, ResourceType, ResourceGroupName, ResourceId, Location, Tags , Properties | ConvertTo-Json -Depth 10
    }
}

## Capture the inputs from the function invocation like threadId and user message
$threadId = $Request.body.threadId
$userMessage = $Request.body.message

## Fetch the thread by the Id provided
$thread = Get-Thread $threadId

## Get the assistant by it's Id
$Assistant = Get-Assistant -assistant "<assistant Id>"

## Add the user provided message to the thread
$Thread = $Thread | Add-threadMessage -message $userMessage -passThru

## Run the assistant to generate a response
$run = Start-ThreadRun -thread $Thread -assistant $Assistant

$run = $run | wait-threadRun

if ($run.status -eq "requires_action") {
    $functionName = $run.required_action.submit_tool_outputs[0].tool_calls.function.name
    $functionParams = $run.required_action.submit_tool_outputs.tool_calls.function.arguments
    $functionParams = $functionParams | ConvertFrom-Json -asHashtable
    $functionOutput = & $functionName @functionParams
    Write-Host "Calling function : $functionName"
    $toolsOutput = @(
        @{
            "tool_call_id" = $run.required_action.submit_tool_outputs.tool_calls.id
            "output"       = $functionOutput | ConvertTo-Json -Depth 10
        }
    )
    Submit-ToolOutput $run -ToolOutput $toolsOutput
    $run = $run | wait-threadRun
}
if ($run.status -eq "in_progress") {
    $run = $run | wait-threadRun
}
$Thread = $Run | Receive-ThreadRun

$messages = $Thread.Messages.SimpleContent.Content
$message = $messages[$messages.length - 1]

## Generate the body of the azure function response back to the chatbot with the model generated response
$body = @{
    "threadId" = $threadId
    "message" = $message
}

$body = $body | ConvertTo-Json -Depth 10
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
```

For the UI, I used an [open-source chatbot UI code](https://www.codingnepalweb.com/create-chatbot-html-css-JavaScript/) that is very simple to use if you have HTML/CSS/JavaScript background. I just modified the JavaScript code in this app to do the following:

- Create a new thread whenever there is a new chat session.
- Invoke our azure function by passing the thread Id and user message.
- Once the azure function returns a response, the app will display the assistant's response in the chat interface.

![Screenshot showing the chatbot UI sample application](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/15.png)

## Testting our new AI assistant

Let's start testing the assistant by asking it questions about our azure environment and monitor what is happening in the azure function's logs.

- First, I will ask the same question we asked before in PowerShell: *what resources do I have in the Sierra workload?*

![Screenshot showing asking the chatbot about resources in project Sierra](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/16.png)

![Screenshot showing azure function log](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/17.png)

![Screenshot showing the chatbot response in the chat UI](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/18.png)

- I will follow-up with *are there any security best practices I'm missing on the virtual machine vm001?*

![Screenshot showing asking the chatbot if there are any best practices on vm001](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/19.png)

![Screenshot showing azure function log](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/20.png)

- Then I will switch gears to another workload I have. *what about the Alpha workload, what resources are there?*

![Screenshot showing asking the chatbot about the alpha workload](https://images.seifbassem.com/images/Posts/custom-Azure-copilot/21.png)

## Recap

The Open AI function calling capability is very powerful to build very robust AI-powered tools and assistants. This is just a demonstration on how you can think of using this capability in the world of the cloud using Azure or even other clouds there can be of course much better and more efficient ways to do the same.

Also this method is intended to create a very specific AI assistant, if you want to have a more general purpose assistant then copilot for Azure is the right solution to use.

## Resources

- Introduction to Azure Copilot

<figure class="video_container">
 <iframe width="560" height="315" src="https://www.youtube.com/embed/-qZZnwgb2ss?si=qClbV4Bv30I53lVZ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
</figure>

- Open AI function calling tutorial

<figure class="video_container">
<iframe width="560" height="315" src="https://www.youtube.com/embed/aqdWSYWC_LI?si=S90gejsia81Gl1Go" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
</figure>

- [Azure Copilot docs](https://learn.microsoft.com/azure/copilot/)
- [Open AI assistants docs](https://platform.openai.com/docs/assistants/overview)
- [PowerShell AI module](https://github.com/dfinke/PowerShellAI)
