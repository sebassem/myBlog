# Let's Encrypt Certificate Renewal for images.seifbassem.com

## Automated Renewal (Azure Automation + Cloudflare DNS-01)

This repository automates the entire renewal pipeline inside Azure using an **Azure Automation PowerShell Runbook** (`Renew-Certificate.ps1`) on a recurring schedule—requiring **zero manual intervention**.

### How It Works

1. **Scheduled Check**: Runs weekly in Azure Automation (Free tier).
2. **Expiration Check**: Authenticates via System-Assigned Managed Identity and checks the expiration date of `images-seifbassem-cert` in Azure Key Vault. If more than `RENEW_WITHIN_DAYS` (default `30` days) remain, it exits early.
3. **Cloudflare DNS-01 Challenge**: Uses `Posh-ACME` with the Cloudflare DNS plugin to automatically create and clean up `_acme-challenge.images.seifbassem.com` TXT records and obtain a new RSA 2048 certificate and `.pfx` bundle.
4. **Key Vault Import**: Imports the new `.pfx` directly into Azure Key Vault (`Import-AzKeyVaultCertificate`).
5. **CDN Update**: Enables custom HTTPS on the Azure CDN (classic) custom domain with the new Key Vault certificate version.

### One-Time Setup & Deployment

1. **Create a Cloudflare API Token**:
   - Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens) → **Create Token** → **Edit zone DNS** template.
   - **Permissions**:
     - `Zone` → `DNS` → `Edit`
     - `Zone` → `Zone` → `Read`
   - **Zone Resources**: `Include` → `Specific zone` → `seifbassem.com`
2. **Configure GitHub secrets**:
   - Add the secrets listed in `README.md` (Azure OIDC identity, resource names, contact email, and `CLOUDFLARE_API_TOKEN`) under repo Settings → Secrets and variables → Actions.
3. **Deploy to Azure**:
   - Run the **Deploy Certificate Renewal Automation** workflow from the Actions tab (it also runs on pushes to `main` that change the scripts).
   `deploy.sh` provisions the Automation Account, enables Managed Identity, installs `Posh-ACME`, assigns Key Vault and CDN permissions, stores encrypted Automation Variables, publishes the runbook, and creates the weekly schedule.
4. **Trigger an On-Demand Run (Optional)**:
   Wait ~2 minutes after deployment for the `Posh-ACME` module import to finish, then run:
   ```bash
   # Normal check (only renews if expiring within RENEW_WITHIN_DAYS):
   az automation runbook start \
     --automation-account-name "<your-automation-account>" \
     --resource-group "<your-resource-group>" \
     --name "Renew-Certificate"

   # Force an immediate renewal:
   az automation runbook start \
     --automation-account-name "<your-automation-account>" \
     --resource-group "<your-resource-group>" \
     --name "Renew-Certificate" \
     --parameters ForceRenewal=true
   ```

---

## Manual Fallback Instructions

### Prerequisites

- Certbot installed (`winget install EFF.Certbot`)  
- OpenSSL installed  
- Azure CLI logged in (`az login`)  
- Admin PowerShell terminal

### Step 1: Request a New Certificate

Run in an **elevated (admin) PowerShell**:

```powershell
certbot certonly --manual --preferred-challenges dns -d images.seifbassem.com --key-type rsa --rsa-key-size 2048
```

&nbsp;

Certbot will ask you to create a DNS TXT record:

- **Name**: `_acme-challenge.images.seifbassem.com`  
- **Value**: (provided by certbot)

Add the TXT record in your DNS provider, wait a minute for propagation, then press Enter.

### Step 2: Convert to PFX

```powershell
openssl pkcs12 -export -out cert.pfx `
  -inkey "C:\Certbot\live\images.seifbassem.com\privkey.pem" `
  -in "C:\Certbot\live\images.seifbassem.com\fullchain.pem"
```

&nbsp;

Enter and confirm an export password when prompted.

### Step 3: Copy PFX to User Directory (if needed)

```powershell
Copy-Item "C:\Certbot\live\images.seifbassem.com\cert.pfx" -Destination "$env:USERPROFILE\cert.pfx"
icacls "$env:USERPROFILE\cert.pfx" /grant "${env:USERNAME}:F"
```

&nbsp;

### Step 4: Import to Azure Key Vault

```powershell
az keyvault certificate import `
  --vault-name <your-vault-name> `
  --name images-seifbassem-cert `
  --file "$env:USERPROFILE\cert.pfx" `
  --password <the-password-you-set>
```

&nbsp;

### Step 5: Update the CDN custom domain to the new certificate version

```powershell
az cdn custom-domain enable-https `
  --resource-group <rg> `
  --profile-name <cdn-profile-name> `
  --endpoint-name <cdn-endpoint-name> `
  --name <custom-domain-name> `
  --user-cert-subscription-id <kv-subscription-id> `
  --user-cert-group-name <kv-resource-group> `
  --user-cert-vault-name <vault> `
  --user-cert-secret-name images-seifbassem-cert `
  --user-cert-secret-version <new-version> `
  --user-cert-protocol-type sni
```

&nbsp;

### Renewal Schedule

- Let's Encrypt certificates are valid for **90 days**  
- Renew **at least 2 weeks before expiry** to avoid disruption  
- Set a calendar reminder for every **75 days**
