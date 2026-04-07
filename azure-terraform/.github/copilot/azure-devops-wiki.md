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

## Path Accuracy Rule

Wiki browser URLs can differ from CLI/API paths. When in doubt, query wiki pages recursively and copy exact paths (including spaces).

## Security and Auth

- Use AZURE_DEVOPS_EXT_PAT and AZURE_DEVOPS_ORG_URL from environment variables.
- Never hardcode PAT values.
- Confirm access before publishing to avoid partial runs.
