---
title: "Deploy Azure App Services anywhere using Azure Arc"
images:
  - "https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/banner.png"
date: 2021-08-19 17:08:42 +0200
tags: ["Azure","Azure Arc","App Services"]
categories: ["posts"]
draft: false
---

<!--more-->

At the date of this post, Azure has [60+ regions](https://infrastructuremap.microsoft.com/explore) around the world where you can deploy applications and services close to your users and comply with your regulatory needs. For some organizations there might be still a need to deploy on-premises where they would miss out on cloud innovation, elasticity and scalability or they would have a requirement to deploy to multiple cloud providers to avoid vendor lock-in where they would face challenges with multiple tools and platforms.

# Deploy anywhere with Azure Arc

Azure Arc has recently introduced a new [capability](https://docs.microsoft.com/en-us/azure/app-service/overview-arc-integration) to deploy Azure App services anywhere using Arc-enabled Kubernetes clusters, enabling you to deploy Azure cloud services (Web apps , Azure functions , Logic apps and Event grid) inside your datacenter or even on other cloud providers ...How cool is that 😎 ??!!

A lot of organizations are adopting Kubernetes in very rapid way to deliver faster value to their customers and if you are one of them and want to provide your developers with a strong and capable PaaS platform to deploy cloud-native applications inside your datacenter  without changing their development and deployment processes or tools.  , this new capability is worth checking out.

💡 If this is the first time you've heard about Azure Arc , check out my [previous introduction](https://www.seifbassem.com/blogs/unboxing/introducing-azure-arc/) of the service.

## How does it work?
To be able to do that , you would need to have the following : 
- **A Kubernetes cluster** : this can be hosted anywhere whether on-premises on Azure stack HCI , any other platform or even in another cloud provider.
- **Arc-enabled cluster** : we need to connect this cluster with Azure arc
- **App service extension** : once connected , we need to install the app service extension on the connected cluster
- **Custom location** : this is the cool part , where you create a custom location mimicking an Azure region where your developers can deploy it. 
- **App Service Kubernetes environment** : this is the app service environment that will host our app service plan and web app.

⚠️ This feature is still in preview!!

## Showtime
Now , let's try deploying a simple web app to my kubernetes cluster and see how it works.

### Preperation
The first thing i need is a working kubernetes cluster which can be hosted anywhere , for the sake of this demo i will use Azure Kubernetes service as my private cluster.

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/18.jpg)
We can see also that it's running the normal AKS pods , nothing special here.

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/2.jpg)
Then, we need to install some extensions to Azure CLI and register some resource providers to enable this preview feature.

```PowerShell
az extension add --upgrade --yes --name connectedk8s
az extension add --upgrade --yes --name k8s-extension
az extension add --upgrade --yes --name customlocation
az provider register --namespace Microsoft.ExtendedLocation --wait
az provider register --namespace Microsoft.Web --wait
az provider register --namespace Microsoft.KubernetesConfiguration --wait
az extension remove --name appservice-kube
az extension add --yes --source "https://aka.ms/appsvc/appservice_kube-latest-py2.py3-none-any.whl"
```
Next, we need to get our cluster credentials and connect it with Azure Arc.

```PowerShell
az aks get-credentials --resource-group $aksClusterGroupName --name $aksName --admin
az connectedk8s connect --resource-group $groupName --name $clusterName
```
![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/3.1.jpg)
And we can see in the portal , that we have a new arc-enabled kubernetes cluster that is reporting as connected and we can see the kubernetes version and distribution as well.

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/3.jpg)
It's an optional step , but we it's a good practice to create a log analytics workspace for our project.

```Powershell
workspaceName="la-arc-01"
az monitor log-analytics workspace create \
    --resource-group $groupName \
    --workspace-name $workspaceName

logAnalyticsWorkspaceId=$(az monitor log-analytics workspace show \
    --resource-group $groupName \
    --workspace-name $workspaceName \
    --query customerId \
    --output tsv)
logAnalyticsWorkspaceIdEnc=$(printf %s $logAnalyticsWorkspaceId | base64)
logAnalyticsKey=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group $groupName \
    --workspace-name $workspaceName \
    --query primarySharedKey \
    --output tsv)
logAnalyticsKeyEncWithSpace=$(printf %s $logAnalyticsKey | base64)
logAnalyticsKeyEnc=$(echo -n "${logAnalyticsKeyEncWithSpace//[[:space:]]/}")
```
Next, we need to Install the App Service extension on our connected cluster

```PowerShell
extensionName="appservice-ext"
namespace="appservice-ns"
kubeEnvironmentName="azurearckubenv"

az k8s-extension create \
    --resource-group $groupName \
    --name $extensionName \
    --cluster-type connectedClusters \
    --cluster-name $clusterName \
    --extension-type 'Microsoft.Web.Appservice' \
    --release-train stable \
    --auto-upgrade-minor-version true \
    --scope cluster \
    --release-namespace $namespace \
    --configuration-settings "Microsoft.CustomLocation.ServiceAccount=default" \
    --configuration-settings "appsNamespace=${namespace}" \
    --configuration-settings "clusterName=${kubeEnvironmentName}" \
    --configuration-settings "loadBalancerIp=${staticIp}" \
    --configuration-settings "keda.enabled=true" \
    --configuration-settings "buildService.storageClassName=default" \
    --configuration-settings "buildService.storageAccessMode=ReadWriteOnce" \
    --configuration-settings "customConfigMap=${namespace}/kube-environment-config" \
    --configuration-settings "envoy.annotations.service.beta.kubernetes.io/azure-load-balancer-resource-group=${aksClusterGroupName}" \
    --configuration-settings "logProcessor.appLogs.destination=log-analytics" \
    --configuration-protected-settings "logProcessor.appLogs.logAnalyticsConfig.customerId=${logAnalyticsWorkspaceIdEnc}" \
    --configuration-protected-settings "logProcessor.appLogs.logAnalyticsConfig.sharedKey=${logAnalyticsKeyEnc}"
```

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/4.jpg)
It takes about 5 minutes to complete the installation

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/5.jpg)
Saving our extension ID for later use

```PowerShell
extensionId=$(az k8s-extension show \
    --cluster-type connectedClusters \
    --cluster-name $clusterName \
    --resource-group $groupName \
    --name $extensionName \
    --query id \
    --output tsv)
```
Now let's explore the pods running in our cluster and see if something has changed

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/6.jpg)
We can see that we have a lot of new pods for Azure arc and also the app service extension as well.

Next, we would need to create our custom location that will be visible in the Azure portal marking our connected cluster. Since i'm based in Egypt, i will name the location "egyptcentral" 😄

```PowerShell
customLocationName="egyptcentral"
connectedClusterId=$(az connectedk8s show --resource-group $groupName --name $clusterName --query id --output tsv)

az customlocation create \
    --resource-group $groupName \
    --name $customLocationName \
    --host-resource-id $connectedClusterId \
    --namespace $namespace \
    --cluster-extension-ids $extensionId
```
![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/9.jpg)

Finally, we need to create the App Service Kubernetes environment
```PowerShell
customLocationId=$(az customlocation show \
    --resource-group $groupName \
    --name $customLocationName \
    --query id \
    --output tsv)

az appservice kube create \
    --resource-group $groupName \
    --name $kubeEnvironmentName \
    --custom-location $customLocationId \
    --static-ip $staticIp
```
And we can see now, that we have everything we need to start deploying our web app in our new shiny custom location

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/11.jpg)

### Deploying the web app
Like any Azure web app , we would need to create a service plan at first (only linux plans are supported at the moment)

```PowerShell
az appservice plan create -g $groupName -n myPlan \
    --custom-location $customLocationId \
    --per-site-scaling --is-linux --sku K1
```
![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/12.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/13.jpg)
Then , we would deploy our web app and note that we specify our custom location as the deployment location 
```PowerShell
az webapp create \
    --plan myPlan \
    --resource-group $groupName \
    --name onpremApp01 \
    --custom-location $customLocationId \
    --runtime 'NODE|12-lts'
```
![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/14.jpg)
In a couple of seconds , we see our web app deployed to our local cluster in the egyptcentral location 

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/15.jpg)

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/16.jpg)
Looking back to the pods deployed in our cluster , we can see a pod for our web app

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/17.jpg)
We can see that there multiple capabilities of the web app greyed out which are not available at the time of the preview but hopefully will be added later. Let's try scaling our app and see what happens in our cluster.

![alt](https://images.seifbassem.com/images/Posts/Azure-Arc-Enabled-App-Services/18.gif)
In a matter of seconds , our app scaled to 10 pods on our cluster which is very cool 🚀

📹Feature announcement in Microsoft Build <figure class="video_container">
<iframe width="560" height="315" src="https://www.youtube.com/embed/ItZNZYOczWc" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>

