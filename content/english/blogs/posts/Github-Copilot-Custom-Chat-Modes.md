---
title: "Level Up your workflows with GitHub Copilot’s custom chat modes"
images:
  - "https://images.seifbassem.com/images/Posts/Github-Copilot-Custom-Chat-Modes/banner.png"
date: 2025-08-09 17:08:42 +0200
tags: ["Azure","AI","IaaC","Bicep","Security","OpenAI","AI Foundry"]
categories: ["posts"]
draft: false
---

<!--more-->

GitHub Copilot has evolved far beyond just completing lines of code — it’s now your AI teammate, ready to adapt to your unique workflow. With Custom Chat Modes, you can shape Copilot’s personality, focus, and expertise to fit your exact needs. In this post, we’ll explore what custom chat modes are, how they work, and walk through a couple of examples on how I use it to help me research and author blog posts.

## Overview

Custom chat modes are preset configurations that let you customize how the AI chat behaves in Visual Studio Code for different tasks like asking questions, editing code, or automating coding workflows. You can switch chat modes anytime in the Chat view to match your current objective.

Visual Studio Code already includes three default chat modes that most of us use on daily basis: Ask, Edit, and Agent. Additionally, you can create your own custom chat modes for specialized needs, such as feature planning or technical research. In this post, I will create the following custom chat modes:

| Chat mode   | Description  |
|---|---|
| Blog research  | Conduct deep technical research and provide comprehensive citations and references to help users understand a certain topic before writing a blog post about it, provide ideas, suggestions and recommendations on how the blog post should like look  |
| Blog authoring  | Conduct analysis of a markdown blog post and help the user turn it into a clean, well-organized post using correct grammar, logical structure, clarity and polished formatting  |

### How to create a new custom chat mode

1. Click on the available chat mode and select 'Configure Modes'

![Screenshot showing vscode with configure modes button clicked](https://images.seifbassem.com/images/Posts/Github-Copilot-Custom-Chat-Modes/01.png)

2. Create a new custom chat mode file

![Screenshot showing vscode with creating a new file for custom chat mode](https://images.seifbassem.com/images/Posts/Github-Copilot-Custom-Chat-Modes/02.png)

3. Type a name for the custom chat mode

![Screenshot showing vscode with selecting a name for the custom chat mode](https://images.seifbassem.com/images/Posts/Github-Copilot-Custom-Chat-Modes/03.png)

4. Then you will be presented with a template markdown file for the custom chat mode.

![Screenshot showing vscode with an empty chat mode template](https://images.seifbassem.com/images/Posts/Github-Copilot-Custom-Chat-Modes/04.png)

5. Since, I will need the custom mode to browse the internet then I will need to install an extension in VSCode to allow that

![Screenshot showing vscode extension installation](https://images.seifbassem.com/images/Posts/Github-Copilot-Custom-Chat-Modes/05.png)

### Blog research mode

I will then provide the details of how my **Blog research** mode should respond and what tools will be available to it:

```Markdown
---
description: 'Conduct deep technical research and provide comprehensive citations and references to help users understand a certain topic before writing a blog post about it, provide ideas, suggestions and recommendations on how the blog post should like look.'
tools: ['codebase', 'fetch', 'search', 'githubrepo', 'microsoft_docs_Search', 'websearch']
---

# Blog research mode instructions

You are in blog research mode. Your task is to help the user research blog ideas by looking at the topic provided by the user and making a research using the tools provided.

Your goal is to provide a detailed and accurate report on the value proposition of this topic including problems it solves and features that are useful to the user. The report should empower the user to come up with one or more blog ideas for this topic.

The response should include the following sections:

- **Overview**: Provide a clear, objective and informative summary on the topic provided by the user through official documentation and other resources like youTube, blogs, forums, GitHub and others.
- **Report**: Provide deep insights on the topic breaking it down by value proposition, pain points it solves, common use cases, tradeoffs and limitations, and how it compares to alternatives.
- **Resources**: provide citations to official documentation and trusted resources
- **Next steps**: come up with one to five blog post ideas for that topic based on the report. This should be one to two paragraphs of the main points that should be covered in the posts.

## Tool usage
- **`codebase`**: use to reference other markdown files in this repository for consistency and reuse
- **`microsoft_docs_Search`**: Use to verify facts, provide citations and enhance clarity if the topic is related to Microsoft technologies
- **`websearch`**: Use to verify facts, provide citations, find use cases, blog posts on same topic if the topic is related or not related to Microsoft technologies
```

>**NOTE: You can see I provide detailed instructions on what the custom mode should do, structure and format the response, and how to use some of the tools provided**

#### Testing the new mode

Prompt: **`I want to write a blog post on Azure AKS fleet manager`**

![Screenshot showing vscode custom chat mode response](https://images.seifbassem.com/images/Posts/Github-Copilot-Custom-Chat-Modes/06.png)

```Markdown
Here’s a focused research brief to help you shape a strong blog post on Azure Kubernetes Fleet Manager (AKS Fleet); I’ll synthesize what matters most and give you concrete angles to write about next.

## Checklist

- Overview of AKS Fleet
- Report: value proposition, pain points solved, common use cases, tradeoffs/limitations, comparisons
- Resources: official docs and trusted links
- Next steps: 1–5 blog ideas with key talking points


## Overview
Azure Kubernetes Fleet Manager (AKS Fleet) is a control-plane service for operating many AKS clusters as a single estate. It groups clusters into a “fleet” (across regions and subscriptions) and provides:

- Update orchestration: staged, policy-driven upgrades across clusters with health checks and rollback.
- Resource propagation: centrally push Kubernetes resources (namespaces, policies, apps) to selected member clusters with rollout controls.
- Multi-cluster services and traffic: consistent service discovery and cross-cluster routing for active/active or failover scenarios.
- Central inventory and grouping: select clusters by labels/properties to target waves/rings and policies.
- CLI/ARM/Bicep/Portal support and Azure RBAC/managed identity integration.

In short, AKS Fleet makes multi-cluster AKS operations repeatable and safer, reducing toil for platform teams that manage many clusters globally.

## Report

### Value proposition

- One-to-many operations: treat many AKS clusters as a single deploy/upgrade target with rings, waves, and automated health gates.
- Consistency at scale: propagate baseline config (RBAC, quotas, network policies, admission controllers), and apps to the right clusters reliably.
- Safer global rollouts: progressive updates with canaries and automatic rollback reduce blast radius.
- Multi-cluster resiliency & routing: unify service discovery and enable active/active or regional failover without bespoke plumbing.
- Native Azure integration: ARM, Azure RBAC, Managed Identities, CLI, and policy work the same way across fleets.

### Pain points it solves
- Upgrade coordination across dozens/hundreds of clusters is error-prone and slow.
- Drift and inconsistency of cluster policy/config across environments and regions.
- Ad-hoc global traffic/routing patterns for multi-region services.
- Manual cluster targeting for compliance and environment segmentation.
- Fragmented tooling between cluster lifecycle and app/config delivery.

### Common use cases
- Global SaaS platform: orchestrate monthly patch updates across regions with waves; canary a subset before broad rollout.
- Regulated enterprise: propagate mandatory namespaces/quotas/OPA/Kyverno policies to all production clusters; keep nonprod isolated via labels.
- Multi-region apps: use multi-cluster services for active/active and planned failovers; reduce DNS sprawl and custom glue.
- M&A or multi-subscription orgs: consistently manage clusters spread across subscriptions under one control plane.
- Blue/green region rotations: push a new version to a small ring, validate SLOs, then progressively expand.

### How it works (mental model)
- Fleet resource: defines the fleet and its member clusters (across subscriptions/regions in the same tenant).
- Targeting: select clusters by membership, labels, or groups for operations.
- Update runs: define waves, pre/post checks, health gates, and rollback behavior to upgrade control planes and node pools.
- Resource propagation: define which K8s resources to distribute, rollout policy (canary/batch), and health checks.
- Multi-cluster services: implement shared service discovery and routing across clusters, aligning with Kubernetes MCS concepts.

### Tradeoffs and limitations
- AKS-first scope: designed for AKS; for non-Azure clusters you’ll likely pair with Azure Arc, but Arc clusters aren’t managed by Fleet as first-class members today.
- Feature maturity: some capabilities (e.g., certain placement/scheduling features) may be in preview; verify GA status before relying on them for production gates.
- Complexity: multi-cluster abstractions add moving parts (identities, policies, rollout rules)—platform teams still need guardrails and observability.
- Version and quota boundaries: ensure supported AKS versions, regional quotas, and network prerequisites for MCS/propagation.
- Vendor lock-in: contrasts with fully portable open-source stacks (e.g., Karmada) if multi-cloud portability is a top requirement.

### Comparisons and adjacent approaches
- Versus GitOps-only (Flux/ArgoCD ApplicationSets): GitOps handles desired state per cluster well, but Fleet adds fleet-aware targeting, update orchestration, health-gated waves, and multi-cluster service primitives out of the box.
- Versus Karmada/KubeFed (OSS): rich multi-cluster scheduling/propagation across any K8s; more DIY ops, less native Azure integration. Fleet is simpler to adopt if you’re all-in on AKS.
- Versus GKE Fleet/Anthos and EKS ecosystem: conceptually similar “fleet” management in GKE; AWS relies on a mix of EKS/Cloud Map/App - Mesh plus blueprints. If you’re primarily on Azure, AKS Fleet offers deeper native control with simpler identity/RBAC and billing alignment.
- Versus Azure Arc-enabled Kubernetes: Arc brings non-AKS clusters into Azure for policy/monitoring. Use Arc for hybrid; use Fleet to operate many AKS clusters as one estate.

## Resources

### Official documentation and references

- AKS documentation home: https://learn.microsoft.com/azure/aks/
- Azure CLI reference for Fleet (az fleet): https://learn.microsoft.com/cli/azure/fleet
- ARM/Bicep resource reference (Microsoft.ContainerService/fleets): https://learn.microsoft.com/azure/templates/microsoft.containerservice/fleets
- Kubernetes Multi-Cluster Services (MCS) API (spec/overview): https://github.com/kubernetes-sigs/mcs-api
- Karmada (multi-cluster Kubernetes): https://karmada.io/
- GKE multi-cluster services (concepts): https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-services
- Rancher Fleet (GitOps at scale): https://fleet.rancher.io/

Note: If you’d like, I can fetch and quote specific AKS Fleet pages (overview, update orchestration, resource propagation, and multi-cluster services) once web access is enabled.

## Next steps: blog post ideas
1. From many clusters to one estate: a practical guide to AKS Fleet
    - Explain fleet primitives (members, labels, groups), and walk through creating a fleet, adding clusters, and organizing with labels.
    - Show how to think in waves/rings for safe rollouts, and how targeting by label unlocks environment/region strategies.
2. Safer global upgrades with AKS Fleet update orchestration
    - Define an update run with health checks, canaries, and rollback.
    - Include guardrail examples (pre-flight checks, SLO probes), and a real sequence for control plane + node pool upgrades across three regions.
3. Policy and app consistency at scale: resource propagation with AKS Fleet
    - Demonstrate pushing common namespaces, NetworkPolicies, and admission policies; then roll out an application with canary batches.
    - Cover drift detection, observability, and how this complements GitOps.
4. Designing multi-region resiliency using multi-cluster services on AKS
    - Explain service discovery patterns, active/active vs failover topologies, and how to wire traffic policies.
    - Include caveats (DNS, health probing, latency) and testing failover drills.
5. AKS Fleet vs alternatives: when to choose Fleet, Arc, or OSS (Karmada/ArgoCD)
    - Provide decision guardrails: Azure-only vs hybrid, portability needs, current toolchain, and team maturity.
    - Map common org scenarios to recommended stacks with pros/cons.

If you want, I can turn any of these into a full outline with code/CLI snippets (PowerShell/az), diagrams, and a short demo scenario.
```

GitHub Copilot did a great job adhering to my instructions providing the response in the same format I provided and with the exact sections I needed to look at before authoring my blog post.

### Blog authoring mode

I will follow the same steps to create another mode for helping me author and format a blog post.

```Markdown
---
description: 'Conduct analysis of a markdown blog post and help the user turn it into clean, well-organized post using correct grammar, logical structure, clarity and polished formatting'
tools: ['codebase', 'fetch', 'search', 'githubrepo', 'microsoft_docs_Search', 'websearch']
---
# Blog authoring mode instructions

You are in blog authoring mode. Your task is to go through a blog post markdown draft and help the user turn it into clean, well-organized post using correct grammar, logical structure, clarity and polished formatting.

Follow the following instructions for optimizing the markdown:

## Step 1: Grammar and spelling corrections
- correct grammar, spelling and punctuation errors throughout the markdown
- At the start of your response, add a **Changes made** section listing all of the changes you made
  Example: "Corrected spelling mistake: 'Azure **Potral**' to 'Azure **Portal**'"

## Step 2: Logical structure and clarity
- Provide suggestions if there are any logical structure changes you need to make.
- Keep paragraphs concise where possible. Provide suggestions before making any changes
-  Example: One paragraph should be before another one to maintain the logical flow of the blog post and making the reading experience smooth and clear
- Example: Use different words with the same meaning to simplify sentences and avoid verbose text

## Step 3: Polished formatting
- Add suitable emojis to the blog post's headers when necessary that match the content
- Use markdown headings for each section

## Tool usage
- **`codebase`**: use to reference other markdown files in this repository for consistency and reuse
- **`microsoft_docs_Search`**: Use to verify facts, provide citations and enhance clarity if the topic is related to microsoft technologies
- **`websearch`**: Use to verify facts, provide citations, find use cases, blog posts on same topic if the topic is related or not related to Microsoft technologies
```

#### Testing the new mode

I've created a draft of a blog post using the results of my initial research using the `blog research mode` and intentionally added a couple of typos.

Prompt: `review this blog post`

![Screenshot showing vscode custom chat mode response](https://images.seifbassem.com/images/Posts/Github-Copilot-Custom-Chat-Modes/07.png)

```Markdown
Here’s a quick plan: I’ll fix grammar/typos, tighten and reorganize the structure, and polish the markdown (headings, emojis, front matter) while preserving your voice and intent.

- Checklist
    - Grammar, spelling, and punctuation corrections
    - Suggest (then apply) logical structure improvements for clarity and flow
    - Polish formatting: valid headings (no H1), emojis where helpful, YAML front matter
    - Keep line length reasonable and add brief notes where external validation is needed (e.g., categories)

## Changes made
- Corrected spelling: “Prerquistes” → “Prerequisites”, “cluters” → “clusters”
- Standardized terminology and casing: “arm/Bicep” → “ARM/Bicep”, “rbac” → “RBAC”
- Clarified phrasing and removed ambiguity; tightened several bullets
- Split long sections into clearer subsections (Create fleet, Add members, Labels & rings, Waves, Propagation, Observability)
- Replaced top-level H1 with H2 per markdown rules; added YAML front matter with required fields
- Added concise headers and emojis to improve scannability
- Improved list formatting and consistency; added brief “Notes”, “Tips”, and “Practice” callouts with clearer language
- Fixed minor stylistic issues (e.g., consistent hyphenation, parallel bullet structure)
- Added guidance notes where org-specific validation (categories) is required

## Structure suggestions (applied below)
- Move “When to use AKS Fleet” before “Prerequisites” so readers can qualify fit early.
- Split “Create a fleet” into “Create a fleet” and “Add member clusters” for clearer mental model.
- Group rollout concepts into “Organize with labels and rings” and “Safer rollouts with waves” to distinguish targeting vs. execution.
- Keep “Propagation” and “Observability & rollback” as their own sections to reflect ongoing ops concerns.
- End with “Tips and pitfalls” as a quick-reference wrap-up.

## Revised post

## Why AKS Fleet matters 🚢
Operating a single AKS cluster is straightforward. Operating 10, 50, or 200 across regions and subscriptions is not. Azure Kubernetes Fleet Manager (AKS Fleet) helps platform teams treat many clusters as one estate: organize members, push shared configuration, and run safe, staged updates with health checks and rollback.

## References 🔗
- AKS documentation: https://learn.microsoft.com/azure/aks/
- Azure CLI (Fleet): https://learn.microsoft.com/cli/azure/fleet

## What this guide covers ✅
- Creating a fleet and adding AKS clusters as members
- Organizing clusters with labels and rings for targeted rollouts
- Rolling out changes safely in waves
- Propagating baseline configuration and applications consistently
- When to use AKS Fleet

## When to use AKS Fleet 🧭

Use Fleet when you need:

- Consistent policy and configuration across many AKS clusters
- Safer, progressive rollouts (waves/rings) with health gates
- Multi‑region/global operations and simplified targeting
- Native Azure RBAC, identities, and ARM/Bicep/CLI integration
- For non‑Azure clusters, pair Azure Arc for inventory/policy with AKS Fleet for your AKS estate

## Prerequisites 🧰
- Azure subscription and Owner/Contributor on the resource groups in scope
- Existing AKS clusters you’ll add as members
- Azure CLI v2.56+ (or latest) and the Fleet extension

Tip: Use separate resource groups per environment (for example, rg-aks-prod, rg-aks-stg) to keep access and lifecycle tidy.
```

## Recap

This feature is extremely useful if you need to create a customized mode for any workflow you have, couple this with custom instructions and you are really getting the most out of GitHub Copilot to 10X your productivity.