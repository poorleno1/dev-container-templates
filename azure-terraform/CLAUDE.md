# Project Instructions

This is an Azure infrastructure project using Terraform, PowerShell, and Azure DevOps Pipelines.

## Core Principles (Priority Order)

1. **KISS** — Start with the simplest solution. Do not add complexity until the simple approach fails.
2. **YAGNI** — Do not add features, abstractions, or configuration until they are actually needed.
3. **SRP** — Each component has one responsibility. Split only when it simplifies understanding.
4. **DRY** — Extract shared logic only after duplication is established and clarity is maintained.

## Security

- Never hardcode secrets, passwords, or API keys. Use environment variables or Azure Key Vault.
- Service Principal credentials must never be committed. Document expected variables, not values.
- Validate all inputs. Follow least privilege for all RBAC and IAM assignments.

## Documentation

- Every project needs a `README.md` with: Purpose, Prerequisites, Setup, Usage, Configuration.
- Store planning documents in `docs/` with timestamp naming: `docs/plan-{yyyy-MM-dd_hh-mm}.md`.

## Language-Specific Instructions

@.claude/instructions/terraform.md
@.claude/instructions/powershell.md
@.claude/instructions/azure-pipelines.md
