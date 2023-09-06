---
title: "Continuous deployment using GitOps and Flux V2"
images:
  - "https://images.seifbassem.com/images/Posts/GitOps-Fluxv2/banner.png"
date: 2023-09-05 17:08:42 +0200
tags: ["Azure","GitOps","DevOps"]
categories: ["posts"]
draft: false
---

<!--more-->

I recently got involved into a project that involved using GitOps and Flux v2 to deploy applications and configuration to Kubernetes clusters (AKS and Azure Arc-enabled Kubernetes clusters) and also configuration flux notifications to trigger a GitHub Action based on some Flux statuses. I was totally new to this world, so in this blog post I will share my experience and learnings on how this technology can help you streamline your Kubernetes operations.

## What is GitOps and Flux v2

Flux v2 is a Kubernetes-native continuous delivery (CD) tool that automates the deployment and lifecycle management of Kubernetes resources. It enables teams to define and manage their application delivery workflows declaratively, using Git as the source of truth. GitOps, on the other hand, is a set of practices that use Git as a single source of truth for cluster configuration and application deployment. This approach improves collaboration, increases visibility, and reduces the risk of configuration drift.

When used together, Flux v2 and GitOps provide a powerful solution for managing Kubernetes clusters, including those running on Azure Kubernetes Service (AKS) and any Arc-enabled Kubernetes cluster. In this blog post, we’ll explore why you should use Flux v2 and GitOps for AKS  and Arc-enabled clusters.

  ![Screenshot showing GitOps and Flux v2 flow](https://learn.microsoft.com/azure/architecture/example-scenario/gitops-aks/media/gitops-flux.png)

## Demo setup

The demo setup looks like the following:

- An application defined in a GitHub repository using a Helm Chart. The application yaml looks like this, note by the end of the yaml file the **value: "{{ .Values.message}}"** value which provides a dynamic message based on whats provided to this Helm Chart.

In our GitHub repository we need to have the following structure:

```
root/
├── Charts/
│   ├── Chart.yaml
│   ├── Templates/
|       ├── deployment.yaml
|       └── flux-alert.yaml
├── Releases/
│   ├── App/
│       ├── hello-flux.yaml
```

- **Charts** directory with the Helm Chart and a **Templates** folder containing the application and the flux alert yaml files.
- **Releases** directory with the Helm Release referencing the Helm Chart and defining the values passed to it.

### **Charts/Templates** directory content

1. The yaml for the application

```yml
apiVersion: v1
kind: Service
metadata:
  name: hello-flux
  namespace: hello-flux
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: hello-flux
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-flux
  namespace: hello-flux
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-flux
  template:
    metadata:
      labels:
        app: hello-flux
    spec:
      containers:
      - name: hello-flux
        image: azurearcjumpstart.azurecr.io/hello-arc-gitops:latest
        ports:
        - containerPort: 8080
        env:
        - name: MESSAGE
          value: "{{ .Values.message}}"
```

2. A Flux GitHub notification provider (there are multiple ones including Slack, GitHub,...etc) and then add a GitHub dispatch notification alert to trigger a GitHub Action.

```yml
apiVersion: notification.toolkit.fluxcd.io/v1beta2
kind: Provider
metadata:
  name: github
  namespace: hello-flux
spec:
  type: githubdispatch
  address: https://github.com/sebassem/azure-arc-jumpstart-apps
  secretRef:
    name: github-token
---
apiVersion: notification.toolkit.fluxcd.io/v1beta2
kind: Alert
metadata:
  name: deployment-succeeded
  namespace: hello-flux
spec:
  providerRef:
    name: github
  summary: env=prod
  eventSeverity: info
  eventSources:
    - kind: Kustomization
      name: config-hello-flux-app
  exclusionList:
    - ".*upgrade.*has.*started"
    - ".*is.*not.*ready"
    - "^Dependencies.*"
    - "*configured*"
    - "\\bconfigured\\b"
    - "\\bfailed\\b"
    - "*failed*"
```

We first define the GitHub provider, point to the GitHub repository and the GitHub Personal access token used to authenticate with our repository

```yml
apiVersion: notification.toolkit.fluxcd.io/v1beta2
kind: Provider
metadata:
  name: github
  namespace: hello-flux
spec:
  type: githubdispatch
  address: https://github.com/sebassem/azure-arc-jumpstart-apps
  secretRef:
    name: github-token
```

Then we define an alert with a Kustomization source pointing to the Kustomization we will use to deploy this application. We will also add some events to the exclusion list so we can limit the noise we get from Flux events.

```yml
apiVersion: notification.toolkit.fluxcd.io/v1beta2
kind: Alert
metadata:
  name: deployment-succeeded
  namespace: hello-flux
spec:
  providerRef:
    name: github
  summary: env=prod
  eventSeverity: info
  eventSources:
    - kind: Kustomization
      name: config-hello-flux-app
  exclusionList:
    - ".*upgrade.*has.*started"
    - ".*is.*not.*ready"
    - "^Dependencies.*"
    - "*configured*"
    - "\\bconfigured\\b"
    - "\\bfailed\\b"
    - "*failed*"
```

And lastly, create the GitHub action to be triggered, echoing the deployment status exposed in this event property **github.event.client_payload.message**

```yml
name: Deployment-Succeeded
on:
  repository_dispatch:
    types:
      - Kustomization/config-hello-flux-app.hello-flux

jobs:
  Trigger-alert:
    runs-on: ubuntu-latest

    steps:
    - name: 'Checkout repository'
      uses: actions/checkout@v3

    - name: Display message
      env:
        message: ${{ github.event.client_payload.message }}
      run: |
        echo $message
```

### **Releases/app** directory content

- A Helm Release that provides the values passed to the Helm Chart. Notice here the **message** value defined as _Welcome to the AKS demo!_. This is the initial value of the application message variable

```yml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: hello-flux
  namespace: hello-flux
  annotations:
    clusterconfig.azure.com/use-managed-source: "true"
spec:
  interval: 1m
  releaseName: hello-flux
  chart:
    spec:
      chart: ./hello-flux/charts/hello-flux
  values:
    message: "Welcome to the AKS demo!"
```

- This is how the application looks like after being deployed to the cluster.

![Screenshot showing the application before changing the message](https://images.seifbassem.com/images/Posts/GitOps-Fluxv2/01.png)

- An AKS cluster (this works also on Arc-enabled clusters) where I want to continuously deploy this application and update it automatically once a change has been pushed to the repository. The cluster initially doesn't have any GitOps configuration defined.

![Screenshot showing the AKS cluster GitOps configuration before any deployment](https://images.seifbassem.com/images/Posts/GitOps-Fluxv2/02.png)

- To deploy all of this, we need to prepare the AKS cluster to be able to use Flux V2 with Helm Charts. We need to make sure that our AKS cluster is using managed identity for this to work

```powershell
clusterName="aks001"
rg="flux-rg"
az aks update -n $clusterName -g $rg --enable-managed-identity
```

Once this is done, we need to deploy the GitOps configuration to our cluster. We will use Azure CLI to do this.

- First we will create a namespace for the application

```powershell
kubectl create namespace hello-flux
```

- Create a Kubernetes secret for the GitHub Personal access token to be used to trigger the GitHub Action.

```powershell
githubPat="<GitHub Personal access token>"
kubectl create secret generic github-token --from-literal=token=$githubPat --namespace hello-flux
```

- Deploy the GitOps configuration

```powershell
appClonedRepo="https://github.com/sebassem/azure-arc-jumpstart-apps"

az k8s-configuration flux create \
    --cluster-name $clusterName \
    --resource-group $rg \
    --name config-hello-flux \
    --namespace hello-flux \
    --cluster-type managedClusters \
    --scope namespace \
    --url $appClonedRepo \
    --branch main --sync-interval 3s \
    --kustomization name=app path=./hello-flux/releases/app prune=true
```

>NOTE
> Note that the Kustomization is pointing to the Helm Release we created earlier

- Once this is deployed, we can see our new GitOps configuration showing as compliant.

![Screenshot showing the GitOps configuration after being deployed](https://images.seifbassem.com/images/Posts/GitOps-Fluxv2/03.png)

- Let's now make a change to our application using the Helm Release. On GitHub, I will change the value of the message to "Welcome to the Flux v2 demo!"

```yml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: hello-flux
  namespace: hello-flux
  annotations:
    clusterconfig.azure.com/use-managed-source: "true"
spec:
  interval: 1m
  releaseName: hello-flux
  chart:
    spec:
      chart: ./hello-flux/charts/hello-flux
  values:
    message: "Welcome to the Flux v2 demo!"
```

- Once the change is pushed to _main_, Flux immediately detects the new commit and start redeploying the application to the cluster with the new message.

![Screenshot showing flux updating the application pods](https://images.seifbassem.com/images/Posts/GitOps-Fluxv2/04.png)

![Screenshot showing the application after changing the message](https://images.seifbassem.com/images/Posts/GitOps-Fluxv2/05.png)

- Since we have deployed a Flux alert into our namespace, we should see the action being triggered.

![Screenshot showing the flux alert in the kubernetes cluster](https://images.seifbassem.com/images/Posts/GitOps-Fluxv2/06.png)

![Screenshot showing the GitHub action run](https://images.seifbassem.com/images/Posts/GitOps-Fluxv2/07.png)

## References

- https://fluxcd.io/flux/
- https://fluxcd.io/flux/guides/notifications/
- https://learn.microsoft.com/azure/azure-arc/kubernetes/conceptual-gitops-flux2
- https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2?tabs=azure-cli
- https://www.youtube.com/playlist?list=PLG9qZAczREKmCq6on_LG8D0uiHMx1h3yn