#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNBOOK_FILE="${SCRIPT_DIR}/Renew-Certificate.ps1"
RUNBOOK_NAME="Renew-Certificate"
SCHEDULE_NAME="Weekly-Cert-Renewal-Check"

# Configuration is read exclusively from environment variables.
# In CI these are injected from GitHub Actions secrets
# (see .github/workflows/deploy-cert-renewal.yml). No .env/config file is used.

# Validate required variables
REQUIRED_VARS=(
  "AZURE_SUBSCRIPTION_ID"
  "AZURE_RESOURCE_GROUP"
  "KEY_VAULT_RESOURCE_GROUP"
  "AUTOMATION_ACCOUNT_NAME"
  "KEY_VAULT_NAME"
  "KEY_VAULT_CERT_NAME"
  "CDN_PROFILE_NAME"
  "CERT_DOMAIN"
  "ACME_CONTACT_EMAIL"
  "ACME_SERVER"
  "RENEW_WITHIN_DAYS"
  "CLOUDFLARE_API_TOKEN"
)

for var_name in "${REQUIRED_VARS[@]}"; do
  val="${!var_name:-}"
  if [[ -z "${val}" || "${val}" == \<* ]]; then
    echo "Error: environment variable ${var_name} is not set or still contains a placeholder."
    exit 1
  fi
done

az account set --subscription "${AZURE_SUBSCRIPTION_ID}"

# Default AZURE_LOCATION to the location of the target Resource Group
if [[ -z "${AZURE_LOCATION:-}" ]]; then
  AZURE_LOCATION=$(az group show --name "${AZURE_RESOURCE_GROUP}" --query location -o tsv)
fi

echo "=================================================================="
echo "Deploying Automated Certificate Renewal to Azure Automation"
echo "=================================================================="
echo "Subscription ID     : ${AZURE_SUBSCRIPTION_ID}"
echo "Resource Group      : ${AZURE_RESOURCE_GROUP}"
echo "Automation Account  : ${AUTOMATION_ACCOUNT_NAME} (${AZURE_LOCATION})"
echo "Key Vault           : ${KEY_VAULT_NAME} (RG: ${KEY_VAULT_RESOURCE_GROUP})"
echo "CDN Profile         : ${CDN_PROFILE_NAME}"
echo "Domain              : ${CERT_DOMAIN}"
echo "=================================================================="

BASE_AA_URI="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}/providers/Microsoft.Automation/automationAccounts/${AUTOMATION_ACCOUNT_NAME}"
API_VERSION="2022-08-08"

# ------------------------------------------------------------------------------
# 1. Create / Update Azure Automation Account with System-Assigned Identity
# ------------------------------------------------------------------------------
echo -e "\n[1/7] Creating/updating Azure Automation Account '${AUTOMATION_ACCOUNT_NAME}'..."
AA_BODY=$(python3 -c '
import json, sys
print(json.dumps({
    "location": sys.argv[1],
    "identity": {"type": "SystemAssigned"},
    "properties": {"sku": {"name": "Basic"}}
}))
' "${AZURE_LOCATION}")

AA_RESPONSE=$(az rest --method PUT \
  --uri "${BASE_AA_URI}?api-version=${API_VERSION}" \
  --body "${AA_BODY}")

PRINCIPAL_ID=$(echo "${AA_RESPONSE}" | python3 -c 'import json, sys; print(json.load(sys.stdin)["identity"]["principalId"])')
echo "Automation Account ready. Managed Identity Principal ID: ${PRINCIPAL_ID}"

# ------------------------------------------------------------------------------
# 2. Import Posh-ACME Module into Automation Account
# ------------------------------------------------------------------------------
echo -e "\n[2/7] Importing Posh-ACME module from PowerShell Gallery..."
MODULE_BODY='{
  "properties": {
    "contentLink": {
      "uri": "https://www.powershellgallery.com/api/v2/package/Posh-ACME"
    }
  }
}'

az rest --method PUT \
  --uri "${BASE_AA_URI}/modules/Posh-ACME?api-version=${API_VERSION}" \
  --body "${MODULE_BODY}" >/dev/null
echo "Posh-ACME module import initiated."

# ------------------------------------------------------------------------------
# 3. Grant Permissions on Key Vault & CDN profile to Managed Identity
# ------------------------------------------------------------------------------
echo -e "\n[3/7] Configuring permissions for Managed Identity (${PRINCIPAL_ID})..."

KV_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${KEY_VAULT_RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/${KEY_VAULT_NAME}"
KV_RBAC=$(az keyvault show --name "${KEY_VAULT_NAME}" --resource-group "${KEY_VAULT_RESOURCE_GROUP}" --query "properties.enableRbacAuthorization" -o tsv 2>/dev/null || echo "false")

if [[ "${KV_RBAC}" == "true" ]]; then
  echo "  Key Vault uses Azure RBAC. Assigning 'Key Vault Certificates Officer'..."
  az role assignment create \
    --assignee-object-id "${PRINCIPAL_ID}" \
    --assignee-principal-type ServicePrincipal \
    --role "Key Vault Certificates Officer" \
    --scope "${KV_ID}" >/dev/null
else
  echo "  Key Vault uses Access Policies. Setting certificate & secret policies..."
  az keyvault set-policy \
    --name "${KEY_VAULT_NAME}" \
    --resource-group "${KEY_VAULT_RESOURCE_GROUP}" \
    --object-id "${PRINCIPAL_ID}" \
    --certificate-permissions get list import update \
    --secret-permissions get list set >/dev/null
fi

CDN_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}/providers/Microsoft.Cdn/profiles/${CDN_PROFILE_NAME}"
echo "  Assigning 'CDN Profile Contributor' on CDN profile '${CDN_PROFILE_NAME}'..."
az role assignment create \
  --assignee-object-id "${PRINCIPAL_ID}" \
  --assignee-principal-type ServicePrincipal \
  --role "CDN Profile Contributor" \
  --scope "${CDN_ID}" >/dev/null

# ------------------------------------------------------------------------------
# 4. Create / Update Automation Variables
# ------------------------------------------------------------------------------
echo -e "\n[4/7] Storing configuration variables in Automation Account..."

set_automation_variable() {
  local name="$1"
  local value="$2"
  local is_encrypted="$3"

  local body
  body=$(python3 -c '
import json, sys
name, val, enc = sys.argv[1], sys.argv[2], sys.argv[3].lower() == "true"
print(json.dumps({
    "name": name,
    "properties": {
        "value": json.dumps(val),
        "isEncrypted": enc
    }
}))
' "${name}" "${value}" "${is_encrypted}")

  az rest --method PUT \
    --uri "${BASE_AA_URI}/variables/${name}?api-version=${API_VERSION}" \
    --body "${body}" >/dev/null
}

set_automation_variable "SubscriptionId"         "${AZURE_SUBSCRIPTION_ID}"     "false"
set_automation_variable "ResourceGroup"          "${AZURE_RESOURCE_GROUP}"      "false"
set_automation_variable "KeyVaultName"           "${KEY_VAULT_NAME}"            "false"
set_automation_variable "KeyVaultResourceGroup"  "${KEY_VAULT_RESOURCE_GROUP}"  "false"
set_automation_variable "KeyVaultCertName"       "${KEY_VAULT_CERT_NAME}"       "false"
set_automation_variable "CdnProfileName"         "${CDN_PROFILE_NAME}"           "false"
set_automation_variable "CertDomain"             "${CERT_DOMAIN}"               "false"
set_automation_variable "AcmeContactEmail"       "${ACME_CONTACT_EMAIL}"        "false"
set_automation_variable "AcmeServer"             "${ACME_SERVER}"               "false"
set_automation_variable "RenewWithinDays"        "${RENEW_WITHIN_DAYS}"         "false"
set_automation_variable "CloudflareApiToken"     "${CLOUDFLARE_API_TOKEN}"      "true"

echo "All Automation Variables stored (CloudflareApiToken is encrypted)."

# ------------------------------------------------------------------------------
# 5. Create, Upload, and Publish the PowerShell Runbook
# ------------------------------------------------------------------------------
echo -e "\n[5/7] Creating and uploading runbook '${RUNBOOK_NAME}'..."

RUNBOOK_META=$(python3 -c '
import json, sys
print(json.dumps({
    "location": sys.argv[1],
    "properties": {
        "runbookType": "PowerShell",
        "logVerbose": True,
        "logProgress": False,
        "description": "Automated Let'\''s Encrypt certificate renewal via Cloudflare DNS-01, Key Vault, and Azure CDN"
    }
}))
' "${AZURE_LOCATION}")

az rest --method PUT \
  --uri "${BASE_AA_URI}/runbooks/${RUNBOOK_NAME}?api-version=${API_VERSION}" \
  --body "${RUNBOOK_META}" >/dev/null

az rest --method PUT \
  --uri "${BASE_AA_URI}/runbooks/${RUNBOOK_NAME}/draft/content?api-version=${API_VERSION}" \
  --headers "Content-Type=text/powershell" \
  --body "@${RUNBOOK_FILE}" >/dev/null

echo "Publishing runbook '${RUNBOOK_NAME}'..."
az rest --method POST \
  --uri "${BASE_AA_URI}/runbooks/${RUNBOOK_NAME}/publish?api-version=${API_VERSION}" >/dev/null

# ------------------------------------------------------------------------------
# 6. Create Weekly Schedule & Link to Runbook
# ------------------------------------------------------------------------------
echo -e "\n[6/7] Creating recurring weekly schedule '${SCHEDULE_NAME}'..."

START_TIME=$(python3 -c '
import datetime
dt = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=1)
dt = dt.replace(minute=0, second=0, microsecond=0)
print(dt.strftime("%Y-%m-%dT%H:%M:%SZ"))
')

SCHEDULE_BODY=$(python3 -c '
import json, sys
print(json.dumps({
    "name": sys.argv[1],
    "properties": {
        "description": "Weekly check for certificate expiry (renews when <= RenewWithinDays remain)",
        "startTime": sys.argv[2],
        "interval": 1,
        "frequency": "Week",
        "timeZone": "UTC"
    }
}))
' "${SCHEDULE_NAME}" "${START_TIME}")

az rest --method PUT \
  --uri "${BASE_AA_URI}/schedules/${SCHEDULE_NAME}?api-version=${API_VERSION}" \
  --body "${SCHEDULE_BODY}" >/dev/null

echo -e "\n[7/7] Linking schedule '${SCHEDULE_NAME}' to runbook '${RUNBOOK_NAME}'..."

# Remove any existing jobSchedule link for the same schedule + runbook to avoid duplicates
EXISTING_JOB_SCHEDULES=$(az rest --method GET \
  --uri "${BASE_AA_URI}/jobSchedules?api-version=${API_VERSION}" | python3 -c '
import json, sys
data = json.load(sys.stdin)
for item in data.get("value", []):
    props = item.get("properties", {})
    if props.get("runbook", {}).get("name") == sys.argv[1] and props.get("schedule", {}).get("name") == sys.argv[2]:
        print(item["properties"]["jobScheduleId"])
' "${RUNBOOK_NAME}" "${SCHEDULE_NAME}")

for js_id in ${EXISTING_JOB_SCHEDULES}; do
  az rest --method DELETE \
    --uri "${BASE_AA_URI}/jobSchedules/${js_id}?api-version=${API_VERSION}" >/dev/null || true
done

JOB_SCHEDULE_ID=$(python3 -c 'import uuid; print(str(uuid.uuid4()))')
JOB_SCHEDULE_BODY=$(python3 -c '
import json, sys
print(json.dumps({
    "properties": {
        "schedule": {"name": sys.argv[1]},
        "runbook": {"name": sys.argv[2]}
    }
}))
' "${SCHEDULE_NAME}" "${RUNBOOK_NAME}")

az rest --method PUT \
  --uri "${BASE_AA_URI}/jobSchedules/${JOB_SCHEDULE_ID}?api-version=${API_VERSION}" \
  --body "${JOB_SCHEDULE_BODY}" >/dev/null

echo ""
echo "=================================================================="
echo "Deployment Complete!"
echo "=================================================================="
echo "Next steps:"
echo "  1. Wait ~2 minutes for Azure Automation to finish importing the 'Posh-ACME' module."
echo "  2. Trigger a test run from the Azure Portal or CLI:"
echo "     az automation runbook start \\"
echo "       --automation-account-name \"${AUTOMATION_ACCOUNT_NAME}\" \\"
echo "       --resource-group \"${AZURE_RESOURCE_GROUP}\" \\"
echo "       --name \"${RUNBOOK_NAME}\""
echo "=================================================================="
