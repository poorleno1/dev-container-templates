# Azure Access Rules

Use these rules when working with Azure CLI, Terraform AzureRM authentication, and Azure DevOps CLI.

## Azure CLI Authentication

Use Service Principal environment variables:

- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_TENANT_ID
- ARM_SUBSCRIPTION_ID

The Azure CLI and AzureRM provider both read these variables automatically.

Verification command:

```bash
az account show
```

## Azure DevOps Authentication

Use Azure DevOps extension environment variables:

- AZURE_DEVOPS_EXT_PAT
- AZURE_DEVOPS_ORG_URL

No interactive login or static configuration should be required.

Verification command:

```bash
az devops project list --organization "$AZURE_DEVOPS_ORG_URL"
```

## Azure DevOps Wiki Path Rules

Browser URLs often use hyphenated page names, but CLI/API calls require the exact wiki path with spaces.

Correct example:

```bash
az devops wiki page show --wiki "ipos.wiki" --path "/Infrastructure/Infrastructure landscape"
```

Common mistake to avoid:

```bash
az devops wiki page show --wiki "ipos.wiki" --path "/Infrastructure/Infrastructure-landscape"
```

If the path is unknown, list the wiki tree first:

```bash
az devops invoke \
  --area wiki --resource pages \
  --route-parameters project=<project> wikiIdentifier=<wiki-name> \
  --query-parameters "path=/&recursionLevel=full&includeContent=false" \
  --organization "$AZURE_DEVOPS_ORG_URL" \
  --api-version "7.1"
```

## Important Guardrails

- Do not use curl with AZURE_DEVOPS_EXT_PAT for Azure DevOps wiki endpoints.
- Do not use az rest for Azure DevOps wiki operations.
- Do not source .env files in automation; rely on environment variables already provided.
- Validate organization access early with az devops project list.
