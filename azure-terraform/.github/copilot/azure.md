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

If `AZURE_DEVOPS_ORG_URL` is not available in the current shell, pass `--organization "https://dev.azure.com/<org>"` explicitly on each command. Do not source `.env` files in automation.

## Azure DevOps Work Item Comment Formatting

When adding structured comments to Azure Boards work items, prefer the Work Item Comments API with explicit format.

- Default: use `format=markdown` for readable, lightweight structured comments.
- Fallback: use `format=html` only when markdown cannot express required formatting.
- Avoid `az boards work-item update --discussion` for structured comments, because it writes history text and may not render markdown as expected.

Recommended command pattern:

```bash
az devops invoke \
  --area wit --resource comments \
  --route-parameters project=<project> workItemId=<id> \
  --query-parameters "format=markdown" \
  --http-method POST \
  --in-file <json-body-file> \
  --organization "$AZURE_DEVOPS_ORG_URL" \
  --api-version "7.1-preview"
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

## Azure DevOps Pipeline Build Logs

There is no `az pipelines build log list` command — it does not exist and returns an error. Use `az devops invoke` instead.

### Step 1 — List log IDs for a build

```bash
az devops invoke \
  --area build --resource logs \
  --route-parameters project=<project> buildId=<buildId> \
  --organization "$AZURE_DEVOPS_ORG_URL" \
  --api-version "7.1"
```

Returns a JSON array of log objects with `id`, `lineCount`, and `url`.

### Step 2 — Find the log ID for a specific task

Build URLs encode the job and task as GUIDs: `&j=<job-guid>&t=<task-guid>`. Query the timeline to resolve `t=` to a log ID:

```bash
az devops invoke \
  --area build --resource timeline \
  --route-parameters project=<project> buildId=<buildId> \
  --organization "$AZURE_DEVOPS_ORG_URL" \
  --api-version "7.1"
```

Filter the output by the task GUID to find its `log.id` field.

### Step 3 — Fetch raw log text with curl

`az devops invoke --output tsv` returns empty output for log content. Use curl for raw text:

```bash
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" \
  "https://dev.azure.com/<org>/<project>/_apis/build/builds/<buildId>/logs/<logId>?api-version=7.1"
```

### Searching within a large log

Pipe through grep immediately — logs can be thousands of lines:

```bash
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" \
  "https://dev.azure.com/<org>/<project>/_apis/build/builds/<buildId>/logs/<logId>?api-version=7.1" \
  | grep -n "resource_name\|keyword"
```

To read a specific line range after locating a line number, and strip the timestamp prefix:

```bash
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" \
  "https://dev.azure.com/<org>/<project>/_apis/build/builds/<buildId>/logs/<logId>?api-version=7.1" \
  | sed -n '508,650p' | sed 's/^[0-9T:Z.]*Z //'
```

## Important Guardrails

- Do not use curl with AZURE_DEVOPS_EXT_PAT for Azure DevOps **wiki** endpoints — use `az devops wiki` CLI commands instead.
- For build log **content**, curl IS the correct tool — `az devops invoke` returns empty output for raw log text.
- Do not use az rest for Azure DevOps wiki operations.
- Do not source .env files in automation; rely on environment variables already provided.
- Validate organization access early with az devops project list.
