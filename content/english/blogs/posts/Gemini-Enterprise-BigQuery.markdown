---
title: "Measuring Gemini Enterprise Adoption with BigQuery"
images:
  - "https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/banner.png"
date: 2026-08-02 17:08:42 +0200
tags: ["GCP", "AI", "BigQuery", "Gemini Enterprise", "Terraform", "Governance"]
categories: ["posts"]
draft: false
---

<!--more-->

Generative AI is transforming enterprise operations at an unprecedented pace. With **Gemini Enterprise**, organizations are equipping their workforce with AI assistance and agents deeply integrated across Google Workspace, Google Cloud, and enterprise data repositories. From summarizing complex documents and drafting emails to taking actions and querying multi-source enterprise data, Gemini Enterprise delivers significant productivity gains.

However, rolling out Gemini Enterprise across thousands of employees introduces some common challenges:

- **How do organizations gain deep, actionable insights into how Gemini Enterprise is actually being used?**
- **How to ensure governance and security for such a powerful tool?**
- **How to make it even more valuable?**
- **How to identify opportunities to build custom AI Agents that maximize organizational productivity?**

Without robust telemetry, organizations face critical blind spots:

- **Adoption Visibility**: Which departments actively leverage Gemini Enterprise, and where are licenses sitting idle?
- **Feature & Intent Patterns**: What daily tasks (e.g., document summarization, code generation, data analysis) are driving employee prompts?
- **Security & Compliance Governance**: How do enterprise security teams audit user actions and access patterns without violating privacy?
- **Agent Opportunity Identification**: How can IT leaders identify high-frequency, repetitive user tasks that should be automated by custom-built AI Agents?

In this post, I will demonstrate the following:

1. **Deploying Gemini Enterprise app using Terraform, including various configurations and controls**
2. **Deploying data stores to ground Gemini Enterprise answers against a database and documents**
3. **Configuring telemetry import into BigQuery for insights, governance and analytics**
4. **Configuring Model Armor** to protect against various attacks like jailbreaking, prompt injection and more.

---

## Why Use Infrastructure-as-Code (Terraform) for Gemini Enterprise Logging?

When rolling out Gemini Enterprise across an enterprise Google Cloud environment, like any other GCP service, using Infrastructure-as-Code (IaC) approach helps avoid configuration drift, compliance risks, and operational overhead and introduces versioning and tracking for the infrastructure changes.

> NOTE: Currently not all configurations and capabilities are supported via Terraform or other IaC tools, and some may need to be configured via the Cloud Console. However, Google is continuously adding support for more configurations and capabilities.

## Demo Overview

In this demo, we have a fictional company called Cymbal who would like to deploy Gemini Enterprise and ground it against their Cloud SQL database and a Google Storage bucket containing various documents for their HR policies and employee information. They would like to enable Gemini Enterprise for all their employees and control the usage. They would also like to monitor the usage and identify opportunities to build custom AI Agents that maximize organizational productivity. All to be done while maintaining responsible AI principles, user privacy and security against various AI threats and attacks.

```
+---------------------+      +---------------------+      +---------------------+      +-----------------------+
|  Gemini Enterprise  | ---> |  Cloud Log Router   | ---> |  BigQuery Dataset   | ---> |  Insights & Visibility|
|   +Model Armor      |      |                     |      |                     |      |                       |
+---------------------+      +---------------------+      +---------------------+      +----------------------+|
          |
          |
          V
+-----------------+
|  Data Stores    |
|  - Cloud SQL DB |
|  - GCS Bucket   |
+-----------------+
```

### Data sources

First, we have a PostgreSQL database hosted on Cloud SQL with various HR information distributed across 3 tables for skills, peer feedback and performance reviews. Here is a schema of the database:

  ![Screenshot showing the cloud sql database](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/data-postgresql-tables.png)

Then, we have a Google Storage bucket with various HR policies and employee information documents, such as employee handbook, the company's policies and earnings information.

## Deploying Gemini Enterprise Infrastructure with Terraform

Let's walk through the key Terraform resources to set up for this demo.

### 1. Provider Configuration & API Enablement

First, set up your Terraform provider and enable the required Google Cloud APIs.

```hcl
resource "google_project_service" "required_apis" {
  for_each                   = var.required_apis
  service                    = each.value
  project                    = var.project_id
  disable_on_destroy         = false
  disable_dependent_services = false
}

# Add a delay after enabling APIs to ensure they propagate
resource "time_sleep" "api_propagation" {
  depends_on      = [google_project_service.required_apis]
  create_duration = "30s"
}
```

In the `terraform.tfvars` we provide a set of required APIs as follows

```hcl
required_apis = [
  "storage.googleapis.com",
  "eventarc.googleapis.com",
  "logging.googleapis.com",
  "aiplatform.googleapis.com",
  "discoveryengine.googleapis.com"
]
```

### 2. Creating the Gemini Enterprise App and data stores

Create a `google_discovery_engine_search_engine` resource for the app and a `google_discovery_engine_data_store` resource for the main data store.
Let's first create our data stores.

> NOTE: Gemini Enterprise provides lots of connectors to 3rd party systems like Jira, Salesforce, Sharepoint, and more. However, for this demo, we are using Cloud SQL and Google Storage.

> Note: In an enterprise deployment, you would want to set a scheduled import for your data sources. At the moment, the only way to do that periodic import is using the console. In this demo, we will use the API within Terraform to do a one-time import.

#### Cloud Storage data store

We already have a bucket with all the documents we need so we will create a data store first and set the `content_config` as **CONTENT_REQUIRED** to indicate unstructured data.

```hcl
resource "google_discovery_engine_data_store" "gemini_search_store" {
  location                    = lower(var.ge_region)
  project                     = var.project_id
  data_store_id               = "storage-${random_id.ge_suffix.hex}"
  display_name                = "Cymbal Storage Data Store"
  industry_vertical           = var.ge_industry_vertical
  content_config              = "CONTENT_REQUIRED"
  solution_types              = [local.solution_type]
  create_advanced_site_search = false
  depends_on                  = [time_sleep.api_propagation]
  timeouts {
    create = "20m"
    update = "15m"
    delete = "20m"
  }
}
```

Then, we will trigger the import using an API call with the bucket URL.

```hcl
resource "null_resource" "import_gcs_data" {
  depends_on = [google_discovery_engine_data_store.gemini_search_store]

  provisioner "local-exec" {
    command = <<EOT
      curl -X POST \
      -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      -H "Content-Type: application/json" \
      "https://discoveryengine.googleapis.com/v1/projects/${var.project_id}/locations/${var.ge_region}/collections/default_collection/dataStores/${google_discovery_engine_data_store.gemini_search_store.data_store_id}/branches/0/documents:import" \
      -d '{
        "gcsSource": {
          "inputUris": ["gs://cloud-samples-data/gen-app-builder/search/alphabet-investor-pdfs/*.pdf"],
          "dataSchema": "content"
        },
        "reconciliationMode": "INCREMENTAL"
      }'
    EOT
  }
}
```

#### Cloud SQL data store

We also have the Cloud SQL database, so we will create a data store for it and an import job for each table we want to import.

```hcl
resource "google_discovery_engine_data_store" "gemini_sql_store" {
  for_each                    = var.cloud_sql_config != null ? var.cloud_sql_config : {}
  location                    = lower(var.ge_region)
  project                     = var.project_id
  data_store_id               = "sql-${replace(lower(coalesce(each.value.cloud_sql_table, each.key)), "_", "-")}-${random_id.ge_suffix.hex}"
  display_name                = "Cymbal SQL Data Store - ${coalesce(each.value.cloud_sql_table, each.key)}"
  industry_vertical           = var.ge_industry_vertical
  content_config              = "NO_CONTENT"
  solution_types              = [local.solution_type]
  create_advanced_site_search = false
  depends_on                  = [time_sleep.api_propagation]
  timeouts {
    create = "20m"
    update = "15m"
    delete = "20m"
  }
}
```

Next, we need to create an import job for each table we want to import.

> NOTE: For this demo, we are using a `null_resource` to trigger the import using an API call. In a production environment, you would want to use a scheduled import to keep your data in sync.

```hcl
resource "null_resource" "import_sql_data" {
  for_each   = var.cloud_sql_config != null ? var.cloud_sql_config : {}
  depends_on = [google_discovery_engine_data_store.gemini_sql_store, time_sleep.iam_propagation]

  provisioner "local-exec" {
    command = <<EOT
      curl -X POST \
      -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      -H "Content-Type: application/json" \
      "https://discoveryengine.googleapis.com/v1/projects/${var.project_id}/locations/${var.ge_region}/collections/default_collection/dataStores/${google_discovery_engine_data_store.gemini_sql_store[each.key].data_store_id}/branches/0/documents:import" \
      -d '{
      "cloudSqlSource": {
        "projectId": "${var.project_id}",
        "instanceId": "${coalesce(each.value.cloud_sql_instance, each.key)}",
        "databaseId": "${each.value.cloud_sql_database}",
        "tableId": "${each.value.cloud_sql_table}",
        "gcsStagingDir": "gs://${google_storage_bucket.ge_staging_bucket.name}/staging/"
      },
      "reconciliationMode": "INCREMENTAL",
      "autoGenerateIds": true
    }'
  EOT
  }
}
```

### Create the Gemini Enterprise App

The next step is to create the Gemini Enterprise app and link it to the data stores we created above.

```hcl
resource "google_discovery_engine_search_engine" "gemini_search_engine" {
  engine_id         = "${local.name_prefix}-engine-${random_id.ge_suffix.hex}"
  collection_id     = "default_collection"
  project           = var.project_id
  location          = var.ge_region
  display_name      = "Gemini Enterprise App ${local.name_prefix}"
  industry_vertical = var.ge_industry_vertical
  data_store_ids    = concat([google_discovery_engine_data_store.gemini_search_store.data_store_id], values(google_discovery_engine_data_store.gemini_sql_store)[*].data_store_id)
  app_type          = var.ge_app_type
  common_config {
    company_name = var.company_name
  }

  features = {
    for k, v in var.ge_search_features :
    replace(k, "_", "-") => (v ? "FEATURE_STATE_ON" : "FEATURE_STATE_OFF")
    if v != null
  }


  search_engine_config {
    search_tier                = var.ge_search_tier
    search_add_ons             = var.ge_search_addons
    required_subscription_tier = var.ge_subscription_tier
  }

  knowledge_graph_config {}

  depends_on = [time_sleep.api_propagation]
}
```

These are the variables that we will provide to this resource. You can see we are configuring the various options in Gemini Enterprise, for example we enabled image generation but disabled video generation (we will see this in the console once deployed).

```hcl
ge_app_type          = "APP_TYPE_INTRANET"
company_name         = "Cymbal"
ge_region            = "global"
ge_subscription_tier = "SUBSCRIPTION_TIER_SEARCH_AND_ASSISTANT"
ge_search_features = {
  agent_sharing_without_admin_approval = false
  disable_agent_sharing                = true
  disable_image_generation             = false
  disable_onedrive_upload              = true
  disable_video_generation             = true
  model_selector                       = true
  notebook_lm                          = true
  no_code_agent_builder                = true
  agent_gallery                        = true
  personalization_memory               = true
  prompt_gallery                       = true

}
```

### 3. BigQuery deployment and log routing

Next, we need to create a BigQuery dataset to store the logs and a log sink to route the logs from Cloud Logging to BigQuery. We can do this using the following Terraform resources. This will create a BigQuery dataset and two log sinks. The first sink will route the streaming user activity and gen ai logs to BigQuery and the second sink will route the audit logs to BigQuery.

```hcl
resource "google_bigquery_dataset" "ge_telemetry" {
  project                    = var.project_id
  dataset_id                 = "ge_telemetry_${random_id.ge_suffix.hex}"
  location                   = var.bq_region
  description                = "This dataset will be used to analyze Gemini Enterprise usage and adoption"
  delete_contents_on_destroy = true

}

resource "google_logging_project_sink" "ge_streaming_logs" {
  name                   = "ge-enterprise-streaming-logs-sink"
  project                = var.project_id
  destination            = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.ge_telemetry.dataset_id}"
  unique_writer_identity = true

  filter = <<-EOT
    logName="projects/${var.project_id}/logs/discoveryengine.googleapis.com%2Fgemini_enterprise_user_activity" OR
    logName="projects/${var.project_id}/logs/discoveryengine.googleapis.com%2Fgen_ai.user.message" OR
    logName="projects/${var.project_id}/logs/discoveryengine.googleapis.com%2Fgen_ai.choice"
  EOT
}

resource "google_logging_project_sink" "ge_audit_logs" {
  name                   = "ge-enterprise-audit-logs-sink"
  project                = var.project_id
  destination            = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.ge_telemetry.dataset_id}"
  unique_writer_identity = true

  filter = <<-EOT
    logName:"projects/${var.project_id}/logs/cloudaudit.googleapis.com" AND 
    protoPayload.serviceName="discoveryengine.googleapis.com"
  EOT
}
```

### 4. Configuring IAM Permissions to allow all resources to securely talk to each other

```hcl
resource "google_project_iam_member" "ge_user" {
  project = var.project_id
  role    = "roles/discoveryengine.agentspaceUser"
  member  = "user:${var.admin_email}"
}

resource "google_bigquery_dataset_iam_member" "streaming_sink_bq_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.ge_telemetry.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.ge_streaming_logs.writer_identity
}

resource "google_bigquery_dataset_iam_member" "audit_sink_bq_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.ge_telemetry.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.ge_audit_logs.writer_identity
}

resource "google_storage_bucket_iam_member" "cloudsql_sa_storage_admin" {
  count  = var.cloud_sql_config != null ? 1 : 0
  bucket = google_storage_bucket.ge_staging_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.cloud_sql_sa}"
}

resource "google_project_service_identity" "discovery_engine_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "discoveryengine.googleapis.com"
}

resource "google_project_iam_member" "discovery_engine_cloudsql_viewer" {
  project = var.project_id
  role    = "roles/cloudsql.viewer"
  member  = google_project_service_identity.discovery_engine_sa.member
}

resource "google_storage_bucket_iam_member" "discovery_engine_storage_admin" {
  bucket = google_storage_bucket.ge_staging_bucket.name
  role   = "roles/storage.admin"
  member = google_project_service_identity.discovery_engine_sa.member
}

resource "time_sleep" "iam_propagation" {
  count = var.cloud_sql_config != null ? 1 : 0
  depends_on = [
    google_storage_bucket_iam_member.cloudsql_sa_storage_admin,
    google_project_iam_member.discovery_engine_cloudsql_viewer,
    google_storage_bucket_iam_member.discovery_engine_storage_admin
  ]
  create_duration = "60s"
}
```

### 5. Deployment time

```hcl
terraform init
terraform plan
terraform apply
```

Now, let's look at the console and see what got deployed:

The Gemini enterprise App got deployed successfully

  ![Screenshot showing the gemini enterprise deployment](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-ge-success.png)

We can see indeed the video generation is disabled as intended

  ![Screenshot showing the gemini enterprise features control](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-feature-management.png)

The data stores as well have been created

  ![Screenshot showing the gemini enterprise data stores](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-connected-data-sources.png)

An import job starts immediately for both the bucket and SQL database

  ![Screenshot showing the gemini enterprise import job](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-import-in-progress.png)

After a few minutes the import jobs are completed and we can start querying the data.

  ![Screenshot showing the gemini enterprise import job completed](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-import-complete.png)

We can also see the BigQuery datasets have been created.

  ![Screenshot showing the bigquery datasets](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-bq-datasets.png)

## Generating some sample responses

Let's try a couple of prompts to start generating some telemetry

  ![Screenshot showing a query to gemini1](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-query-feedback.png)

  ![Screenshot showing a query to gemini2](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-earnings-response.png)

  ![Screenshot showing a query to gemini3](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-feedback-response.png)

## Using BigQuery to analyze the telemetry

In this demo, we will interact with BigQuery using two methods; chatting with gemini inside bigquery or writing SQL queries directly.

### Scenario 1: Understanding the usage of the currently deployed agents

We will write a SQL query to get that information

```SQL
SELECT COALESCE(jsonPayload.request.userevent.agentspaceinfo.agentspacepagetype, 'Core Assistant / General') AS agent_space,
       COUNT(*) AS total_interactions,
       COUNT(DISTINCT jsonPayload.useriamprincipal) AS unique_users,
       MIN(timestamp) AS first_interaction,
       MAX(timestamp) AS last_interaction
FROM `possible-bolt-503515-e1.ge_telemetry_032280a7.discoveryengine_googleapis_com_gemini_enterprise_user_activity_20260803`
WHERE COALESCE(jsonPayload.request.userevent.agentspaceinfo.agentspacepagetype, '') != 'home'
GROUP BY 1
ORDER BY total_interactions DESC;
```

  ![Screenshot showing the bigquery query results](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-bg-query.png)

We can see that currently we only have a couple of built-in agents and we can see their current usage based on the sample prompts I ran.

### Scenario 2: Understanding the types of queries users are asking

In this example, I have asked Gemini inside BigQuery to classify the queries users are asking and clarify the intent of the query. 

  ![Screenshot showing the bigquery query results](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-bq-query-intent.png)

We can see that BigQuery has nicely categorized the prompts into different categories and we can see the most common categories based on the sample prompts I ran. This is very helpful for us to understand what are the gaps we have in our data and how we can make everyone more productive by enriching that data or create agents to automate those tasks.

### Scenario 3: What are the opportunities for new Agents?

After sending lots of prompts and after we have a good understanding of the current usage and the types of queries users are asking, we can start looking for opportunities to create new agents that can automate those tasks. I have asked BigQuery to analyze the current usage and find opportunities where we can create agents based on the asks.

  ![Screenshot showing the bigquery query results](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-agent-opps-1.png)

  ![Screenshot showing the bigquery query results](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-agent-opps-2.png)


### Scenario 4: Security insights using Model Armor

I have enabled Model Armor for Gemini Enterprise which is a Google Cloud service that enhances the security and safety of your AI applications by proactively screening the prompts and responses given by the Gemini Enterprise assistant. This helps protect against various risks and ensures responsible AI practices.

  ![Screenshot showing Model Armor blocking a response](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-model-armor-prompt.png)

  ![Screenshot showing Model Armor blocking a response](https://images.seifbassem.com/images/Posts/gemini-enterprise-bq/ge-bq-chat-interface.png)

## Conclusion

Deploying Gemini Enterprise gives employees powerful generative AI assistance, enterprise-ready agents and productivity gains, but capitalizing on its full potential requires enterprise-grade observability, security and strategic optimization. Diving deeper into your current implementation can provide deep insights into active users, department usage trends, license ROI and identify opportunities to create new agents that can automate specific tasks.

### Resources

- [Gemini Enterprise docs](https://docs.cloud.google.com/gemini/enterprise/docs)
- [Terraform resources for data sources](https://docs.cloud.google.com/gemini/enterprise/docs/connectors/connect-terraform)
- [Terraform deployment for Gemini Enterprise blog post](https://medium.com/google-cloud/deploying-gemini-enterprise-using-terraform-79677d97c574)
- [Gemini Enterprise and BigQuery](https://cloud.google.com/blog/products/data-analytics/analyze-and-govern-gemini-enterprise-at-scale-with-bigquery?e=48754805)
- [Model armor docs](https://docs.cloud.google.com/model-armor/manage-templates?authuser=1&_gl=1*1e40o09*_ga*MTkyMTA3NzAzMS4xNzgzNjkwMTcz*_ga_WH2QY8WWF5*czE3ODU3ODE4NDEkbzY3JGcxJHQxNzg1NzgzMTI0JGo1NyRsMCRoMA..)
