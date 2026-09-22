---
title: "Pub/Sub AI Enrichment with Gemini and Jev"
images:
  - "https://images.seifbassem.com/images/Posts/pubsub-ai-transformation/banner.png"
date: 2026-09-21 17:08:42 +0200
tags: ["GCP", "AI", "PubSub", "Gemini Enterprise Agent Platform"]
categories: ["posts"]
draft: false
---

<!--more-->

# Real-Time AI Message Enrichment with Pub/Sub Single Message Transforms (SMT)

Modern event-driven architectures rely heavily on streaming messages through message brokers like Google Cloud Pub/Sub. But as soon as you need to enrich, categorize, or sanitize messages as they arrive, you get some architectural challenges:

```
Producer ──► Raw Topic ──► Cloud Function / Cloud Run ──► AI Model ──► Enriched Topic ──► Subscribers
```

This multi-hop design introduces real operational friction:
- **Cold starts & compute overhead:** Managing containers, autoscaling triggers, concurrency limits, and IAM boundaries.
- **Latency accumulation:** Multiple network serialization and deserialization hops between services.
- **Infrastructure sprawl:** Extra intermediary topics, dead-letter queues, and operational monitoring just to transform/process a message.

With **Cloud Pub/Sub Single Message Transforms (SMTs)**, you get the ability to execute transformation pipelines directly inside the messaging broker **in-flight** before messages are stored and delivered to subscribers.

## What is Cloud Pub/Sub AI Inference SMT?

While standard Single Message Transforms (SMTs) handle lightweight data transformation (like JavaScript UDFs), AI Inference SMT enables Pub/Sub to invoke machine learning and GenAI model endpoints directly from the messaging broker, completely serverless, in-flight, and without intermediate microservices.

```
Publisher ──► Pub/Sub Topic [ JavaScript UDF (Prep) ──► AI Inference SMT ──► JavaScript UDF (Unpack) ] ──► Subscriptions
```

### Why AI Inference SMT is a Paradigm Shift

Traditionally, calling an AI model on a streaming event required deploying an external compute consumer (like Cloud Run or Cloud Functions) to read from a raw queue, call the model API, and publish to an enriched queue.

The AI Inference SMT turns Pub/Sub itself into the orchestration layer:

- **Zero Intermediary Compute:** Pub/Sub handles the model invocation, serialization, authentication, and retries natively.
- **Eliminates Serialization Hops:** Messages are enriched before storage and subscriber delivery, cutting end-to-end event latency.

--- 

In this post, we will explore:

- **How Pub/Sub SMTs work under the hood.**
- **Implementing a real-world scenario:** In-flight customer review triage and intelligent routing.
- **Evaluating model choices for stream processing:** Generative LLMs (Google Gemini Flash) vs. deterministic classifiers (like TypeSafe's Jev).

## Deeper Dive into AI SMT

Single Message Transforms allow you to chain lightweight, sequential processing stages directly onto a Pub/Sub topic/subscription. When a producer publishes an event, Pub/Sub executes the transform chain in the broker:

A complete SMT pipeline typically consists of three stages:

1. **Stage 1 (Pre-Inference JavaScript UDF):** Restructures incoming raw JSON into the payload format expected by the model endpoint.
2. **Stage 2 (AI Inference SMT):** Calls an AI model synchronously inside the broker. This natively supports Google Model Garden models (e.g., Gemini) as well as custom Gemini Enterprise Agent Platform AI Endpoints.
3. **Stage 3 (Post-Inference JavaScript UDF):** Unpacks model predictions, stitches enrichment data back into the payload, and stamps **Pub/Sub message attributes** for downstream filtering.

The beauty of this pattern is that subscribers pull fully enriched, categorized messages directly from filtered subscriptions without writing a single line of intermediary pipeline code.

![Screenshot showing the high-level architecture](https://images.seifbassem.com/images/Posts/pubsub-ai-transformation/01.gif)

> NOTE 💡 Architectural Note: Topic vs. Subscription SMTs
Google’s official documentation recommends configuring AI Inference SMTs on subscriptions rather than topics. When using traditional generative LLMs (which take 2 to 5+ seconds), putting the transform on a subscription avoids blocking the producer’s publish call and isolates failure handling. In our scenario, Jev changes the game: with sub-second inference latencies (~40–250 ms), the producer's publish call remains fast and broker-friendly


## What is TypeSafe's Jev, and Why the Hype?

The simplest way to understand the buzz is this: Jev is a **"foundation model for classification."**

For the past three years, the industry has relied on generative LLMs to make software decisions: routing tickets, scoring sentiment, and flagging spam. But LLMs are fundamentally not really suited for that task.

- **Indecisiveness:** LLMs are trained to predict the next word, not make a decision. Forcing an LLM to decide between true and false adds non-deterministic fuzziness and sometimes hallucinated JSON schemas to systems that demand deterministic contracts.
- **The latency tax:** Generating text token-by-token takes seconds. Software decision paths and message brokers have latency budgets of milliseconds.
- **High cost:** Decision-making requires concise classifications, yet LLMs if not using structured output, can generate lots of unnecessary text resulting in high cost.

### Enter Jev: System 1 AI for Software

Instead of conversational text generation, Jev operates as a classifier:

- **Decisions via probabilities:** Jev evaluates your data against typed questions (choice, score, bool) in a single forward pass, returning calibrated probabilities and confidence scores.
- **Zero Output Generation:** Because it never generates text, output tokens are free.
- **Blazing fast execution:** Evaluates in ~40–250 ms—making in-flight streaming decisions viable at scale.

>NOTE Jev doesn't try to be a creative chatbot; it’s the deterministic decision layer software pipelines have been missing.


## The Business Scenario: Real-Time Customer Review Triage

To see this in action, let’s take an e-commerce platform processing thousands of inbound customer reviews. As reviews land on Pub/Sub, the system needs to immediately determine:

1. **Root cause category:** `hardware_defect`, `software_firmware`, `delivery_shipping`, `customer_support`, `general_feedback`, or `spam_promotional`.
2. **Customer frustration score:** A calibrated score from `0.0` (calm) to `3.0` (furious).
3. **Legal or chargeback threat:** Does the review threaten legal action, regulatory complaints, or a bank chargeback?
4. **Recommended action:** Instant warranty replacement, supervisor escalation, standard support ticket, or spam quarantine.

Here is what an inbound customer review looks like when published to the raw topic:

```json
{
  "review_id": "rev-8091",
  "customer_id": "cust-enterprise-99",
  "customer_tier": "enterprise",
  "order_id": "ord-7712",
  "product_id": "headphones-anc-pro",
  "product_category": "audio",
  "star_rating": 1,
  "title": "Headband snapped on day 2 and support hung up!",
  "text": "The sound quality is good, but the plastic headband literally snapped in half on day two of normal use. When I called your support hotline, the representative refused to honor the warranty and hung up on me. I want an immediate replacement or full refund, otherwise I am disputing the charge with my bank and filing an FTC consumer complaint."
}
```

---

## Pipeline Walkthrough: Transforming Messages In-Flight

Let's look at how the 3-stage SMT pipeline processes this review.

### Stage 1: Pre-Inference Formatting (JavaScript UDF)
Before calling the model, our first JavaScript UDF (`prepareJevRequest`) extracts the relevant context and shapes it into a typed evaluation schema (`state` + `questions`):

```javascript
function prepareJevRequest(message, metadata) {
  const review = JSON.parse(message.data);
  const originalReview = { ...review };

  // 1. Structure context state
  const state = {
    stars: review.star_rating,
    title: review.title || "",
    text: review.text || "",
  };

  // 2. Define parallel evaluation rubrics
  const questions = {
    category: {
      type: "choice",
      instructions: "Primary issue?",
      criteria: {
        hardware_defect: "Broken or damaged hardware",
        software_firmware: "Bug, crash, or connectivity",
        delivery_shipping: "Late or damaged shipping",
        customer_support: "Rude or unhelpful support",
        general_feedback: "General praise or feedback",
        spam_promotional: "Spam, promo, or scam link"
      }
    },
    frustration: {
      type: "score",
      instructions: "Frustration (0-3)",
      criteria: ["Calm", "Mild annoyance", "Angry", "Furious"]
    },
    legal_threat: {
      type: "noul",
      instructions: "Threatens lawsuit, FTC report, or chargeback?",
      criteria: {
        true: "Lawsuit, FTC, or chargeback threat",
        false: "No threat"
      }
    }
  };

  message.data = JSON.stringify({
    model: "jev-latest",
    state: state,
    questions: questions,
    _original_review: originalReview // Preserved for final stitch
  });

  return message;
}
```

---

### Stage 2: AI Inference at the Messaging Layer

> NOTE The Cloud Pub/Sub AI Inference SMT doesn't support external HTTP calls. It exclusively invokes models hosted on the Agent Platform (either native Model Garden models or custom models hosted on Gemini Enterprise Agent Platform AI Endpoints).

> NOTE Because Jev is hosted externally by TypeSafe, we deployed a lightweight FastAPI proxy adapter container to a Gemini Enterprise Agent Platform endpoint. The Pub/Sub AI Inference SMT calls this internal Gemini Enterprise Agent Platform endpoint (/predict or /rawPredict), and the adapter securely proxies the evaluation to the TypeSafe API, returning the structured predictions back to Pub/Sub.

Pub/Sub AI Inference SMT synchronously calls the configured model endpoint. In our implementation, we tested two distinct approaches:

1. **Google Gemini Flash (LLM via Model Garden):** Using standard chat completions.
2. **TypeSafe Jev (AI classifier via Gemini Enterprise Agent Platform AI Endpoint):** A lightweight classifier engine designed specifically for structured evaluations.

#### Why Model Selection Matters for In-Flight SMTs
When evaluating models inside a streaming broker, traditional generative LLMs introduce trade-offs:
- **Broker Latency Budget:** Generative LLMs typically take **1,500 ms – 4,500 ms** to stream tokens. If broker execution takes several seconds, producer publish latencies climb.
- **Output Token Charges:** LLMs charge a premium for generated output text (often more than the input price). Emitting structured JSON token-by-token can accumulate significant costs at scale.

This is where deterministic classifiers like **TypeSafe Jev** stand out. Because Jev evaluates classifications directly via probabilities rather than generating text:
- **Broker Latency:** Completes in **~200 ms – 370 ms** (~12x faster broker turnaround).
- **Zero Output Tokens:** You are billed strictly for input context, with **0 output tokens**.

Here is what we get back from the model:

```json
{
  "model": "jev-latest",
  "answers": {
    "category": {
      "choice": "hardware_defect",
      "confidence": 0.94,
      "probabilities": {
        "hardware_defect": 0.9421,
        "customer_support": 0.0512
      }
    },
    "frustration": {
      "score": 3.0,
      "confidence": 0.98
    },
    "legal_threat": {
      "noul": 0.96
    }
  },
  "metrics": {
    "latency_ms": 288.51,
    "input_tokens": 850,
    "output_tokens": 0
  }
}
```

---

### Stage 3: Post-Inference Unpacking & Attribute Injection (JavaScript UDF)

Once the model responds, our unpacking UDF (`unpackJevResponse`) stitches the enrichment block back into the customer review and promotes critical signals into **Pub/Sub Message Attributes**:

```javascript
function unpackJevResponse(message, metadata) {
  const rawPayload = JSON.parse(message.data);
  const inferenceOutput = rawPayload.model_output || rawPayload;
  const originalReview = rawPayload.original_message?._original_review || {};
  const answers = inferenceOutput.answers || {};

  const categoryChoice = answers.category?.choice || "general_feedback";
  const frustrationScore = answers.frustration?.score || 0.0;
  const legalProbability = answers.legal_threat?.noul || 0.0;

  const isLegalThreat = legalProbability >= 0.70;
  const isCritical = isLegalThreat || frustrationScore >= 2.0;
  const actionChoice = isCritical ? "supervisor_escalation" : "standard_support_ticket";

  // 1. Stitch enrichment into message body
  originalReview.enrichment = {
    category: { label: categoryChoice, confidence: answers.category?.confidence },
    frustration: { score: frustrationScore, tier: frustrationScore >= 2.5 ? "critical" : "moderate" },
    legal_threat: isLegalThreat,
    recommended_action: actionChoice
  };
  message.data = JSON.stringify(originalReview);

  // 2. Inject attributes for serverless subscription routing
  message.attributes = message.attributes || {};
  message.attributes["category"] = categoryChoice;
  message.attributes["is_critical"] = isCritical ? "true" : "false";
  message.attributes["legal_threat"] = isLegalThreat ? "true" : "false";
  message.attributes["action"] = actionChoice;

  return message;
}
```

#### The Resulting Enriched Message Body:
```json
{
  "review_id": "rev-8091",
  "customer_id": "cust-enterprise-99",
  "star_rating": 1,
  "title": "Headband snapped on day 2 and support hung up!",
  "text": "The sound quality is good, but the plastic headband literally snapped...",
  "enrichment": {
    "category": { "label": "hardware_defect", "confidence": 0.94 },
    "frustration": { "score": 3.0, "tier": "critical" },
    "legal_threat": true,
    "recommended_action": "supervisor_escalation"
  }
}
```

#### Injected Pub/Sub Attributes:
```json
{
  "category": "hardware_defect",
  "frustration_tier": "critical",
  "legal_threat": "true",
  "is_critical": "true",
  "action": "supervisor_escalation"
}
```

---

## Serverless SQL Subscription Filtering

Because our UDF stamps classifications directly into `message.attributes`, subscribers can use Pub/Sub native SQL-like filter syntax to receive only the events they care about:

```sql
-- 1. Legal Team (Instant alerts for litigation threats or chargebacks)
attributes.legal_threat = "true" OR attributes.is_critical = "true"

-- 2. Hardware Team (Defects, cracked components, and warranty dispatches)
attributes.category = "hardware_defect" AND attributes.action = "instant_warranty_replacement"

-- 3. Customer Support Team (High frustration tickets & supervisor escalations)
attributes.action = "supervisor_escalation" OR attributes.frustration_tier = "critical"

-- 4. Analytics (Full stream ingestion, dropping quarantined spam)
attributes.is_spam != "true"
```

No consumer needs to pull, parse, or evaluate message bodies to determine whether to act. Downstream services remain decoupled and lean.

---

## Live Performance Comparison: Jev vs. Gemini Flash

Running both pipelines live on Pub/Sub shows clear differences in streaming dynamics:

| Metric | TypeSafe Jev (System 1) | Gemini 3.7 Flash (LLM) | Why It Matters |
| :--- | :--- | :--- | :--- |
| **In-Flight Broker Latency** | **~370 ms** | **~4,755 ms** | **~12.8x faster.** Keeps publisher roundtrips low. |
| **Output Tokens Charged** | **0 tokens (FREE)** | **~37 – 128 tokens** | Jev produces classifications not text ; LLMs must generate text token-by-token. |
| **Cost per 1M Events** | **~$35** | **~$64 – $130** | Zero output generation yields substantial savings at streaming scale. |

Generative LLMs remain the gold standard when you need rich natural language generation, reasoning chains, or free-form summarization. But for structured classification, sentiment detection, and event routing directly inside a messaging broker, specialized classification models provide the low-latency predictability that streaming systems demand.

---

## Conclusion

Google Cloud Pub/Sub Single Message Transforms fundamentally streamline event-driven architectures. By moving enrichment and classification into the messaging broker itself:
- You eliminate intermediate microservices, extra compute queues, and cold starts.
- Downstream services consume clean, pre-classified messages filtered natively by Pub/Sub subscriptions.
- Pairing SMTs with low-latency classification engines keeps broker latencies well under sub-second thresholds while slashing per-event operational costs.

If your streaming pipelines currently rely on extra compute hops just to classify incoming data, Cloud Pub/Sub SMTs offer a significantly simpler, more maintainable pattern.

---

### Resources
- [Google Cloud Pub/Sub Single Message Transforms Documentation](https://cloud.google.com/pubsub/docs/single-message-transforms)
- [AI Inference SMT](https://docs.cloud.google.com/pubsub/docs/smts/ai-inference-smt)
- [TypeSafe Jev Documentation](https://api.typesafe.ai)
