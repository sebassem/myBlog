---
title: "Self-Hosting LLMs on Kubernetes: GPU optimization"
images:
  - "https://images.seifbassem.com/images/Posts/Hosting-LLMs-K8s-GPUs/banner.png"
date: 2025-10-11 17:08:42 +0200
tags: ["AI Infrastructure","Azure","AI","LLMs","Kubernetes"]
categories: ["posts"]
draft: false
---
<!--more-->


#### Series map

1. [**Introduction**](https://www.seifbassem.com/blogs/posts/hosting-llms-k8s-intro/)
2. [**How LLMs and GPUs work?**](https://www.seifbassem.com/blogs/posts/hosting-llms-k8s-intro/)
3. **GPU optimization**

------------

## Why GPU Optimization Matters?

GPUs are now the most expensive and scarce resources in the AI world, therefore optimizing GPU utilization ensures that each dollar spent on compute translates to tangible model performance.Before we delve into the techniques, let's understand why this is so important:

- **Cost efficiency**: GPUs are expensive. Maximizing their utilization directly translates to lower operational costs.
- **Throughput**: Serving more inference requests per second means a better user experience and higher capacity.
- **Latency**: Reducing the time it takes for an LLM to generate a response is crucial for interactive applications.
- **Scalability**: Efficient GPU usage allows you to serve more models to more users with the same hardware, making your deployment more scalable.

## GPU Optimization Techniques for Hosting Large Language Models on Kubernetes

As large language models (LLMs) continue to grow in size and complexity, the ability to efficiently utilize GPUs becomes a central challenge for any AI infrastructure team. When hosting these models on Kubernetes, GPU optimization is not just about cost savings, it's about maximizing throughput, reducing latency, and ensuring high availability across clusters.

This post explores some of the GPU optimization techniques used in production environments, including multi-Instance GPU (MIG), GPU time slicing, batching, quantization, and others.

### Batching

Batching is perhaps the most fundamental GPU optimization. Instead of processing individual inference requests one by one, batching groups multiple requests together into a single, larger input. The GPU then processes this batch in parallel, leveraging its architecture for parallel computation.

#### How it helps:

- **Reduces overhead**: GPUs have a fixed overhead per kernel launch. Processing a batch significantly reduces this overhead.
- **Increases utilization**: GPUs are designed to handle large amounts of data in parallel. Batching keeps their computational units busy and utilized.

#### Considerations:

- **Latency vs. Throughput**: Larger batches generally increase throughput but can also increase the perceived latency for individual requests if a request has to wait for others to form a batch.
- **Dynamic batching**: For varying workloads, dynamic batching (where the batch size is adjusted based on incoming requests) can provide a good balance.

You'll typically implement batching or have it automatically implemented within your LLM serving framework (e.g. vLLM) rather than at the Kubernetes level.

### Multi-Instance GPU (MIG)

In many workloads, the full capacity of powerful GPUs is not usually needed and the GPU is underutilized. MIG is an Nvidia technology that allows a single physical GPU to be partitioned into up to seven fully isolated smaller GPU instances, each with dedicated memory, cache and compute cores. It is supported on certain models, like Nvidia A100, H100 and newer models.

You will usually create multiple profiles to partition your GPU, let's say we want to partition one GPU:

- **Profile: 1g.5gb**: This provides one instance with 1 compute slice and 5GB of memory.
- **Profile: 2g.10gb**: This provides one instance with 2 compute slice and 10GB of memory.
- **Profile: 3g.20gb**: This provides one instance with 3 compute slice and 20GB of memory.
- **Profile: 7g.40gb**: This provides one instance with 7 compute slice and 40GB of memory.

> You can partition it in multiple ways based on your workloads needs

Now, in Kubernetes you can simply allocate the profiles to your pods as follows:

```yaml
resources:
  limits:
    nvidia.com/mig-1g.5gb: 1
```

#### How it helps

- **Guaranteed QoS**: Prevents workloads from interfering with each other, eliminating "noisy neighbor" problems.
- **Improved Utilization for Varied Workloads**: Ideal for scenarios where you have many smaller models or multiple workloads with varying resource demands.
- **Enhanced Security**: Isolation at the hardware level.

### Quantization

Quantization reduces the precision of the model's weights, typically from 32-bit floating point (FP32) to lower precision formats like 16-bit floating point (FP16), 8-bit integer (INT8), or even 4-bit integer (INT4), this leads to cutting memory footprint and speeding up compute.

#### How it helps:

- **Reduced Memory Footprint**: Lower precision means the model occupies less GPU memory, allowing you to fit larger models or more instances on a single GPU.
- **Faster inference**: GPUs can often perform operations on lower-precision data much faster, leading to increased inference speed.
- **Reduced Bandwidth**: Less data needs to be moved between GPU memory and computational units. This allows also to use smaller GPU partitions.

#### Considerations:

- **Accuracy Trade-off**: Quantization can sometimes lead to a slight degradation in model accuracy. The key is to find the right balance between performance and accuracy.

Usually, LLM serving frameworks like vLLM handle quantization transparently.

###  GPU Time-Slicing (Fractional GPU)

For GPUs that don't support MIG, or when you need more flexible sharing than MIG's static partitioning, GPU time-slicing can be used. This allows multiple pods to share a single GPU by scheduling their execution in a time-sliced manner.

In Kubernetes you would usually create a configMap to define how many time-sliced shares each GPU should advertise. In this example it will be 4 shared GPU slices.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: time-slicing-config
  namespace: gpu-operator
data:
  any: |-
    version: v1
    sharing:
      timeSlicing:
        resources:
          - name: nvidia.com/gpu
            replicas: 4
```
Then in your pod mainfest, you would allocate one or more of those slices

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: time-sliced-inference
spec:
  containers:
    - name: llm-server
      image: my-llm:latest
      resources:
        limits:
          nvidia.com/gpu: 1
        requests:
          nvidia.com/gpu: 1
```

#### How it helps:

- **Increased Density**: Multiple smaller workloads can share a single GPU, improving overall utilization. It enables also oversubscription of GPU.
- **Flexibility**: Not restricted by hardware partitioning.

#### Considerations:

- **No Hard Isolation**: Workloads are not isolated at the hardware level; a busy workload can still impact others on the same GPU.
- **Context Switching Overhead**: Frequent context switching between workloads can introduce some overhead.
- **Fair Scheduling**: Requires a robust scheduler to ensure fair resource allocation.

## References

- https://www.nvidia.com/technologies/multi-instance-gpu/
- https://huggingface.co/docs/optimum/en/concept_guides/quantization
- https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html

