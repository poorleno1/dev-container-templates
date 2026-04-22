# Azure DevOps Wiki Workflow

Use these rules when creating or updating Markdown content that will be published to Azure DevOps Wiki.

## Required Workflow

1. Verify Azure DevOps access through the CLI and environment variables.
2. Update local markdown first under docs/wiki.
3. Use Azure DevOps CLI commands or repo-based wiki sync for publishing.
4. Avoid direct REST/curl approaches for wiki writes.

## Local-First Authoring

- Keep source pages in docs/wiki/<section>/<slug>.md.
- Prefer clear, stable paths that map to wiki sections.
- Validate markdown structure before publish.

## Publish Methods

Use one of these:

- az devops wiki page create
- az devops wiki page update
- Push to the mapped wiki Git repository

## Mermaid Diagrams in Azure DevOps Wiki

- Use Azure DevOps wiki mermaid block syntax with triple-colon blocks.
- Do not use fenced mermaid code blocks for published wiki pages.
- Prefer conservative Mermaid features that are known to render in Azure DevOps.
- For reliability, prefer `sequenceDiagram`. If a flow diagram is needed, use `graph` syntax.

Example:

```md
::: mermaid
sequenceDiagram
	participant EG as Event Grid
	participant FN as Azure Function
	participant KV as Key Vault
	participant GR as Microsoft Graph

	EG->>FN: SecretNearExpiry event
	FN->>KV: Read secret metadata
	FN->>GR: sendMail
:::
```

## Post-Publish Verification

- Verify both source and render state after publishing.
- First confirm page content via CLI.
- Then verify visual rendering in the browser for diagrams.

Recommended checks:

```bash
# Confirm page source was updated
az devops wiki page show \
	--wiki "<wiki-name>" \
	--path "/Exact Path With Spaces" \
	--organization "$AZURE_DEVOPS_ORG_URL" \
	--project "<project>" \
	--include-content
```

If Mermaid does not render:

- Convert diagram blocks to `::: mermaid` format.
- Simplify syntax to Azure DevOps-compatible Mermaid subset.
- Re-publish and re-check in browser.

## Path Accuracy Rule

Wiki browser URLs can differ from CLI/API paths. When in doubt, query wiki pages recursively and copy exact paths (including spaces).

## Security and Auth

- Use AZURE_DEVOPS_EXT_PAT and AZURE_DEVOPS_ORG_URL from environment variables.
- Never hardcode PAT values.
- Confirm access before publishing to avoid partial runs.
