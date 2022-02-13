---
title: "Azure Chaos Studio - Wreak Chaos in your Azure environment"
images:
  - "https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/banner.png"
date: 2022-02-12 17:08:42 +0200
tags: ["Azure", "Azure Chaos Studio"]
categories: ["Azure Unboxing"]
draft: false
---

Chaos Engineering is the discipline of experimenting on a system in order to build confidence in the system’s capability to withstand turbulent conditions in production. Sometimes, we think our system is perfectly architected and is highly available, but only in the midst of an actual incident where we start to see the shortcomings and re-think our architecture.

> "All great changes are preceded by chaos" - Deepak Chopra

Azure Chaos studio is new service in Azure that allows you to systematically inject failures in your system to understand how it will react in case of an actual disaster whether it's a more than usual load, service or region failure, network problem ,...etc. In this post, I will give this new solution a try to inject failures in my system, observe it's state and finally introduce some enhancements based on the results.

## Initial system Architecture

I'm running a sample e-commerce website on an AKS cluster with the following components:
  - One node pool that is backed by a Virtual Machine Scale set.
  - An nginx ingress service
  - No auto-scaling of pods is enabled

   ![A screenshot showing e-commerce shop for dot net merchandise](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/25.jpg)

## Using Azure Chaos Studio to fail my e-commerce site

The service consists of two main steps, on-boarding an Azure service and creating experiments. Some services support agent-based faults (like CPU pressure, I/O stress, kill process, ..etc) and some support service-based faults (like VMSS shutdown, Cosmos DB failover,. ..etc) and some services support both types of faults.

In this demonstration, I will attemp to fail my system by doing the following:
  1. **Inject an AKS service mesh CPU stress on my front-end Nginx service**, this should simulate having a huge number of requests on the frontend and eventually should fail my system if it's not ready to scale.
  2. **Force shutdown the Virtual Machine Scale Set (VMSS) instance running my single node pool**, this should cause my whole AKS system to be down due to having only one node pool.

### Onboarding services

The first step, is to onboard our AKS cluster and VMSS TO Azure Chaos Studio. AKS supports only service-based faults and VMSS supports both but in our experiment of shutting down the VMSS instance, we will need only the service-based fault.

   ![A screenshot showing onboarding an AKS to Azure chaos studio](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/31.jpg)

   ![A screenshot showing onboarding a VMSS instance to Azure chaos studio](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/32.jpg)

Next, we need to create an experiment to define the faults we need to inject. Experiments allow you to create multiple steps that run in sequence and within each step, you can create branches that run in-parallel within a single step.

Our first step would be injecting a CPU stress in our AKS cluster that targets our frontend Nginx service. Azure Chaos studio leverages the open source cloud-native Chaos engineering platform **Chaos Mesh** to inject it's AKS-related faults. This would require installing the service onto our AKS cluster.

  ```python
  az aks get-credentials -g eshop-learn-rg -n eshop-learn-aks
  helm repo add chaos-mesh https://charts.chaos-mesh.org
  helm repo update
  kubectl create ns chaos-testing
  helm install chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-testing --version 2.0.3 --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock
  ```
We can now see that the Chaos Mesh pods are indeed deployed and running on our AKS cluster.

   ![A screenshot showing Azure CLI with the Chaos Mesh pods showing as running](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/53.jpg)

### Creating the experiment

Now, let's create the first step of a 95% CPU stress that would run for 3 minutes and targets just one of the pods in the ingress-nginx namespace. We would need to use the syntax of the Chaos Mesh service but convert it into JSON instead of YAML. 

   ![A screenshot showing a new step in Azure chaos studio, showing the steps for an AKS stress fault](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/33.jpg)

   ![A screenshot showing an AKS cluster as the target of the chaos experiment](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/34.jpg)

This is how our firs step looks like.

   ![A screenshot showing the AKS mesh stress experiment step](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/54.jpg)

Next, we will add an additional step to shutdown our VMSS-backed node pool for 15 minutes and select the instance ID of our only instance running withing this VMSS.

   ![A screenshot showing adding a VMSS shutdown step in the experiment](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/35.jpg)

Now, we have an experiment ready with two steps.

   ![A screenshot showing the two-step experiment](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/55.jpg)

Before running our experiment, we need to grant it the necessary RBAC permission to be able to inject it's faults. For the AKS step, it needs to have **Azure Kubernetes Cluster Admin** role on the AKS cluster and for the VMSS step, it needs to have **Virtual Machine Contributor** role on the VMSS instance.

   ![A screenshot showing assigning the Azure Kubernetes Cluster Admin role on the cluster](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/36.jpg)

   ![A screenshot showing assigning the Virtual Machine Contributor on the VMSS instance](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/37.jpg)

### Testing our system

After having everything ready , let's start to run the experiment and see how our system holds up.

   ![A screenshot showing starting the Azure Chaos studio experiment](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/13.jpg)

The first step would cause 95% CPU stress on our frontend. Looking at the AKS insights, we can see that our nginx pods are under so much CPU stress and since we haven't setup any scaling, eventually our website goes down.

   ![A screenshot showing the frontend pods not running](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/16.jpg)

   ![A screenshot showing 96% CPU stress on the frontend pod](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/17.jpg)

   ![A screenshot showing 96% CPU stress on the frontend pod](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/19.jpg)

   ![A screenshot showing the website not repsonding](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/15.jpg)

After 3 minutes have passed, it is time for our VMSS shutdown step.

   ![A screenshot showing starting the Azure Chaos studio VMSS shutdown step](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/28.jpg)

Our main and only node pool has been indeed shutdown and all pods are not running and of course, our website goes down.

   ![A screenshot showing node pool not running](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/29.jpg)

   ![A screenshot showing all pods not running](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/30.jpg)

### Learning from the experiment

This experiment has shown us that our system is not resilient and more work needs to be done to have it production-ready. In this next attempt, I will add an additional node pool and enabled the horizontal pod scaler and re-run the experiment again.

Adding an additional node pool.

   ![A screenshot showing two node pools running](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/40.jpg)

Enabling the horizontal pod scaler for our frontend nginx service to scale up between 3-10 pods on 50% CPU stress.

   ![A screenshot showing scaling our nginx pod](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/38.jpg)

   ![A screenshot showing the frontend pod scaling to 3 pods](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/39.jpg)

Re-running the experiment, we first see our frontend pods under the same pressure, but this time they scale up to 10 pods instead of failing immediately.
   
   ![A screenshot showing frontend pods under high CPU stress](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/43.jpg)
   
   ![A screenshot showing frontend pods scaling to 10](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/42.jpg)

   ![A screenshot showing frontend pods scaling to 10 on a graph](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/49.jpg)

Our website keeps running instead of going down in this case.

   ![A screenshot showing the website running](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/48.jpg)

After 3 minutes when it's time for our VMSS shutdown step, we can see that the first node pool shutdowns down but we now have an additional one for more resiliency. After some time, the pods start restarting on this node pool and our website continues to run even when one of the node pools goes down.

   ![A screenshot showing one of the two node pools going down](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/45.jpg)

We can see the pods are now restaring and shorly re-scheduled on the new node pool. Our website comes back up in a matter of minutes.

   ![A screenshot showing one of the two node pools going down](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/46.jpg)

   ![A screenshot showing one of the two node pools going down](https://images.seifbassem.com/images/Unboxing/Azure-Chaos-Studio/47.jpg)

## Summary

Azure Chaos studio is a great tool to help you test your architecture against your high availability and resiliency claims, this form of chaos engineering helps your systems become more fault-proof in cases of real disasters and failures. You can also use it to do performance testing, business continuity drills, understanding the capacity needs of your applications and much more.

## Resources

- [Azure Chaos Sudio documentation](https://docs.microsoft.com/azure/chaos-studio/chaos-studio-overview)
- [Azure Chaos Studio on Azure Friday](https://www.youtube.com/watch?v=pSEDDiWfnVY&t=674s)