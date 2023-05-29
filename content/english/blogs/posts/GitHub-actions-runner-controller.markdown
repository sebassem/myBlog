---
title: "Run GitHub Actions on your Kubernetes cluster"
images:
  - "https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/banner.png"
date: 2023-05-28 17:08:42 +0200
tags: ["Azure","DevOps","GitHub","Kubernetes"]
categories: ["posts"]
draft: false
---

<!--more-->

If you are working with GitHub Actions, you are re probably already familiar with the concept of runners. Runners are the machines that execute jobs in a GitHub Actions workflow. For example, a runner can clone your repository locally, install testing software, and then run commands that evaluate your code.

You can have GitHub host and manage runners for you or you could choose to host your own runners "self-hosted runners". Using self-hosted runners, offers more control of hardware, operating system, and software tools where you can create custom hardware configurations that meet your needs with processing power or memory to run larger jobs, install software available on your local network, and choose an operating system not offered by GitHub-hosted runners. Self-hosted runners also helps you meet regulatory and compliance requirements. They can be physical, virtual, in a container, on-premises, or in a cloud.

In this article, we are going to explore how you can host self-hosted runners in your Kubernetes clusters using the Actions Runner Controller (ARC).

## Setup

> NOTE
> I have an AKS (Azure Kubernetes Service) cluster that I will use to demonstrate hosting self-hosted runners but you can leverage any Kubernetes cluster.

To start using the Actions Runner Controller, there are some pre-requisites we need to prepare.

Create a GitHub personal access token with _repo_ permissions on my GitHub account

  ![Screenshot showing creating a personal access token on GitHub](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/01.png)

We need to install _cert-manager_ on our cluster

  ```python
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml
  ```

  ![Screenshot showing installing cert-manager using kubectl](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/02.png)

We can now deploy the Actions Runner Controller on our cluster, I will use Helm to deploy it

  ```python
  helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller

  helm upgrade --install --namespace actions-runner-system --create-namespace\
    --set=authSecret.create=true\
    --set=authSecret.github_token="PERSONAL_ACCESS_TOKEN_HERE"\
    --wait actions-runner-controller actions-runner-controller/actions-runner-controller
  ```

  ![Screenshot showing adding helm repository](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/03.png)

  ![Screenshot showing installing actions runner controller using helm](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/04.png)

Last step is to create a new self-hosted runner and configure it to run against our GitHub repository

  ![Screenshot showing creating a github self-hosted runner configuration](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/05.png)

  In this yaml file, we are first creating a new self-hosted runner and registering it with my repository _sebassem/actions-runners_, then we are creating a horizontal runner scaler object to automatically scale our runners based on the __PercentageRunnersBusy__ metric.

Let's now apply this Kubernetes manifest to our cluster

  ![Screenshot showing applying the github self-hosted runner configuration to our cluster](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/06.png)

We can see that we have our runner deployed on the cluster

  ![Screenshot showing running status for our runner](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/07.png)

  ![Screenshot showing running pods for our runner](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/08.png)

Going back to GitHub, we can see that our runner has been successfully registered to our _sebassem/actions-runners_ repository

  ![Screenshot showing the runner registered on our repository](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/09.png)

Finally, let's put this setup to a test, I will create a very simple GitHub action to echo "Hello World". You can see that I've selected the __On__ property to be _self-hosted_ so this action uses only self-hosted runners

  ![Screenshot showing a github action](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/10.png)

After the action has run successfully, we can see navigate to its logs to see that it has actually run on our self-hosted runner which runs on our Kubernetes cluster.

  ![Screenshot showing the github action workflow steps](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/11.png)

  ![Screenshot showing the logs of the github action](https://images.seifbassem.com/images/Posts/GitHub-actions-runner-k8s/12.png)

## References

- To learn more about Actions Runner Controller (ARC), check out its [docs](https://github.com/actions/actions-runner-controller/blob/master/docs/about-arc.md)