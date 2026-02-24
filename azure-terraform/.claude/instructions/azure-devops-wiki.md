# Azure DevOps Wiki Instructions

## Core Workflow (MANDATORY)

When asked to create/update a wiki page:

1. **Auth**: Assume `AZURE_DEVOPS_EXT_PAT` env var is set (valid PAT). Verify with `az devops configure --list`.
2. **Local MD first**: Create/update file in `docs/wiki/<section>/<slug>.md` (e.g., `docs/wiki/runbooks/aks.md`).
3. **CLI only**: Use `az devops` CLI or helper script. No REST APIs directly.
4. **Publish**: Push to wiki repo or use `az devops wiki page create/update`.

## Assumptions Check

Before starting:
