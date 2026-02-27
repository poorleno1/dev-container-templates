# Azure Access — Project Rules

## Azure CLI Authentication

Use a service principal via environment variables. These are set in `.env` and loaded automatically:

```
ARM_CLIENT_ID       # Service principal app ID
ARM_CLIENT_SECRET   # Service principal secret
ARM_TENANT_ID       # Azure AD tenant ID
ARM_SUBSCRIPTION_ID # Default subscription
```

The `az` CLI and AzureRM Terraform provider both read these automatically. No `az login` required.

To verify access:
```bash
az account show
```

## Azure DevOps Access

Use the `az devops` CLI extension. Authentication and org URL are set via environment variables:

```
AZURE_DEVOPS_EXT_PAT   # PAT token (read by az devops automatically)
AZURE_DEVOPS_ORG_URL   # e.g. https://dev.azure.com/digitalattorney
```

No `az devops configure` needed — the extension reads these variables directly.

To verify access:
```bash
az devops project list --organization "$AZURE_DEVOPS_ORG_URL"
```
