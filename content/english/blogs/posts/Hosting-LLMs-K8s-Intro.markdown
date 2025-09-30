---
title: "AI Infrastructure Deep Dive: Self-Hosting LLMs on Kubernetes - Intro"
images:
  - "https://images.seifbassem.com/images/Posts/Hosting-LLMs-K8s-Intro/banner.png"
date: 2025-09-28 17:08:42 +0200
tags: ["Azure","AI","LLMs","Kubernetes"]
categories: ["posts"]
draft: false
---

<!--more-->

The AI infrastructure landscape is evolving rapidly. While managed platforms like Azure AI Foundry, Amazon Bedrock and Google Vertex AI have democratized access to powerful models, a growing number of enterprises are exploring a complementary approach: self-hosting LLMs on Kubernetes. Why? The reasons range from cost optimization at scale to meeting stringent compliance requirements, achieving ultra-low latency, and gaining control over cutting-edge open-source models. In this series, I'll share practical insights from my journey into this ecosystem—covering the architecture decisions, technical trade-offs, operational patterns, and of-course lots of demos that make Kubernetes-based LLM hosting a viable option for specific use cases.

> This initial post is an introduction to the series, discussing at a high-level the motivation behind hosting LLMs on Kubernetes. Throughout this post there will be some new and unfamiliar terms and technologies, I will go through most of them in more details in the future posts of the series.

## The Managed-LLM landscape

Platforms like Azure AI Foundry, Google Vertex AI and others provide fully managed environments for running and integrating large language models (LLMs) into applications. These services abstract away the heavy lifting of infrastructure management allowing teams to focus on building features rather than provisioning GPUs, setting up distributed inference, or dealing with complex scaling requirements. Azure AI Foundry, for example, provides seamless access to Azure OpenAI models, while Vertex AI offers access to Gemini models. They also provide access to a set of open-source models like Llama, DeepSeek, Grok and others. Both platforms are designed to simplify the process of experimenting with and operationalizing LLMs at scale.

A key advantage of these managed services is their feature-rich ecosystem. They typically include built-in capabilities such as prompt engineering tools, observability, evaluation, AI-safety, and integrated APIs for easy deployment. Security and compliance are also strong points, as these platforms inherit their cloud provider’s certifications and data protection mechanisms.

Pricing is usage-based, which enables quick proof-of-concept deployments without heavy upfront investment in hardware. For many businesses, this means faster time to market, predictable performance, and lower risk when experimenting with rapidly evolving AI models.

## When Self-Hosting Becomes Attractive

While managed LLM platforms provide excellent value for many use cases, certain scenarios may benefit from exploring self-hosted alternatives. Understanding these scenarios can help organizations make informed decisions about their AI infrastructure strategy.

**Cost optimization for high-volume workloads**: For organizations with consistently high inference volumes, the economics may favor investing in dedicated GPU infrastructure. Usage-based pricing models excel for variable workloads and experimentation, but predictable high-volume usage patterns might achieve better cost efficiency through reserved capacity or owned infrastructure.

**Open-source models choice**: Another consideration is flexibility if the models you seek are not available in the managed service's model catalogue. Managed services often offer a catalogue of models you can deploy or fine-tune. For example, organizations may be constrained to the provider’s approved models, making it difficult to integrate cutting-edge open-source models. Even when bring-your-own-model options exist, the deployment process may involve proprietary tooling, limiting portability and creating migration challenges if the organization wishes to change providers.

**Data privacy and compliance requirements**: Data privacy and regulatory requirements may also lead some organizations to consider alternatives to managed services. Sensitive industries such as healthcare, finance, or government may have strict data residency rules that conflict with the provider’s infrastructure or require more granular control over encryption and data flow than a managed service can guarantee. These constraints make it difficult to comply with internal security policies while using a fully managed platform.

**Performance optimization and experimentation**: Organizations focused on research or requiring highly specialized inference optimizations may benefit from direct hardware control. This includes scenarios where teams need to experiment with custom inference runtimes, implement novel scaling patterns, or leverage specific GPU features for maximum efficiency. These requirements complement rather than replace the use of managed services for production workloads.

**Latency and geographic proximity**: For applications requiring ultra-low latency or serving users in regions with limited managed service availability, self-hosting can provide better control over geographic placement and network optimization. While managed services offer global distribution, some use cases may benefit from deploying models closer to specific user bases or integrating more tightly with existing on-premises infrastructure to minimize network hops and reduce response times.

**Rate limits and throughput control**: Applications with unpredictable or bursty traffic patterns may encounter rate limiting constraints in managed services, which are designed to ensure fair usage across all customers. While these limits are reasonable for most use cases, can be gracefully handled using specific techniques and can often be increased through support requests, organizations with highly variable workloads or specific throughput requirements may prefer the predictable capacity and unlimited request rates that come with dedicated infrastructure.

**Rate limits and throughput control**: Applications with unpredictable or bursty traffic patterns may encounter rate limiting constraints in managed services, which are designed to ensure fair usage across all customers. While these limits are reasonable for most use cases, can be gracefully handled using specific techniques and can often be increased through support requests, organizations with highly variable workloads or specific throughput requirements may prefer the predictable capacity and unlimited request rates that come with dedicated infrastructure.

**Edge AI and distributed deployments**: Industries requiring AI capabilities in distributed edge locations—such as retail stores, manufacturing plants, warehouses, or remote facilities—often face connectivity constraints that make cloud-based managed services impractical. Self-hosting on Kubernetes enables organizations to deploy lightweight, optimized models directly at edge locations, ensuring consistent AI functionality even with intermittent internet connectivity. While managed services excel in cloud-connected environments, edge scenarios benefit from local inference capabilities that can operate independently.

These considerations have led many enterprises to consider hybrid approaches, using managed services for most workloads while exploring Kubernetes-based hosting for specific use cases that require additional control, cost optimization, or special security, privacy and compliance requirements.

These considerations have led many enterprises to consider hybrid approaches, using managed services for most workloads while exploring Kubernetes-based hosting for specific use cases that require additional control, cost optimization, or special security, privacy and compliance requirements.

### What does it take to self-host LLMs on Kubernetes?

Hosting LLMs on Kubernetes is not as easy as using managed services, it requires lots of stitching pieces together, proper architecture, integrating different open-source components and skillful operation. Below is a high-level checklist of what it takes to pull it off:

#### Infrastructure & Cluster Setup

- **GPU Nodes**: Provision GPU-enabled nodes (e.g., NVIDIA A100/H100, L40S) with adequate memory and compute based on the size of the models to deploy and expected workload volume.
- **Cluster Sizing**: Plan node pools and autoscaling policies for different workloads (inference, fine-tuning, background tasks, dev/test/prod).
- **Networking**: Configure secure networks, load balancers, global optimized routing and AI gateways for secure, low-latency and high-throughput access to LLMs.
- **Storage**: Attach persistent volumes for models, caching, and logs.

#### GPU Resource Management

- **Drivers & runtime**: NVIDIA provides drivers and container runtimes for different GPU models.
- **Device plugins**: NVIDIA provides a Kubernetes device plugin to expose GPUs to pods.
- **Scheduling & allocation**: Use techniques and technologies like Kubernetes Device Resource Assignment (DRA), Multi-Instance GPU (MIG), Multi-Process Service (MPS), time-slicing and others for optimized GPU sharing.

#### Model Deployment

- **Containerization**: Packaging, consuming, versioning and storing open-source LLMs in container registries. Most open-source LLMs are hosted on public registries like Hugging Face.
- **Deployment patterns**: Using Deployments, DaemonSets and other Kubernetes API objects for deploying different components.
- **Scaling**: Implement Horizontal Pod Autoscaler (HPA) or KEDA for scaling based on CPU/GPU utilization or request load.

#### Inference Optimization

- **Serving frameworks**: Use optimized inference engines like vLLM, TensorRT-LLM, Hugging Face's TGI or DeepSpeed-MII for throughput and low latency.

> We will only explore vLLM in this series

- **Serving optimization**: Quantization, paged attention, continuous batching, speculative decoding,OpenAI compatible API server,...etc

#### CI/CD & Model Ops

- **GitOps**: Manage manifests and updates with tools like Flux or ArgoCD.
- **Model registry**: Track versions and rollouts.
- **Automated rollouts**: Use Canary or Blue/Green deployments to safely update models.

#### Networking & API Gateway

- **Ingress controller**: Deploy NGINX, Istio, or Azure Application Gateway for traffic routing.
- **API gateway**: Add rate limiting, token counting, and authentication (e.g., Azure API Management, Kong, Envoy).
- **Content safety**: Integrate moderation or content filtering where needed.

#### Monitoring & Observability

- **Metrics**: Track GPU/CPU/memory utilization (Prometheus, Grafana).
- **Tracing & logs**: Enable distributed tracing (OpenTelemetry, Jaeger) to troubleshoot latency.
- **Alerting**: Set alerts on GPU saturation, queue lengths, and response times.

#### Security & Compliance

- **Identity & access**: Use RBAC, workload identities and other techniques for pod-level security.
- **Secrets management**: Store API keys, model credentials in key management services like Azure Key Vault.
- **Network policies**: Restrict traffic between namespaces and services.

#### Cost & Performance Management

- **Spot/Preemptible nodes**: Use cheaper GPU instances where tolerable.
- **Autoscaling**: Scale down idle GPUs during low demand.
- **Profiling**: Continuously profile GPU usage and latency to tune configurations.

## What to expect from the upcoming posts

I will try to tackle most of the topics in the above checklist to demonstrate and demo how to host, manage, operate, monitor and scale a large language model on Kubernetes. I will use Azure Kubernetes Service (AKS) as my Kubernetes platform but the concepts should be the same across different platforms or self-hosted Kubernetes.

> **Stay tuned for Part 1**

## Resources

- https://www.youtube.com/watch?v=thCZDKZ1cAM
- https://www.youtube.com/watch?v=JD8ZD3pNij0
- https://www.youtube.com/watch?v=wYzsPNfMF7A
- https://www.youtube.com/watch?v=KIRUbaUjEKw