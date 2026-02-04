# GitHub Copilot Instructions

This is a **template repository** providing GitHub Copilot configuration for Terraform and PowerShell infrastructure projects. When modifying this template or using it as a base, follow these guidelines.

## Repository Structure

- [.github/copilot/terraform.md](copilot/terraform.md) - Terraform-specific instructions (Azure-focused, Terraform 1.5.7)
- [.github/copilot/powershell.md](copilot/powershell.md) - PowerShell-specific instructions
- [.github/copilot/azure-pipelines.md](copilot/azure-pipelines.md) - Azure DevOps pipeline instructions (Terraform deployments)
- [.editorconfig](../.editorconfig) - Formatting rules (2-space for Terraform/YAML, 4-space for PowerShell)
- [.vscode/settings.json](../.vscode/settings.json) - VS Code workspace settings
- [examples/](../examples/) - Example README files demonstrating the patterns

## Core Principles (Priority Order)

1. **KISS** - Start with the simplest solution; avoid premature complexity
2. **YAGNI** - Don't add features until actually needed
3. **SRP** - One responsibility per component; split only when it simplifies
4. **DRY** - Extract duplication last, after clarity is established

## When Modifying Template Files

- Keep language-specific details in `.github/copilot/{language}.md`, not here
- Example code blocks should use placeholder values with clear comments (e.g., `"tfstateaccount"  # Replace with actual value`)
- Anti-patterns sections are valuable—document what NOT to do
- Pin specific versions (Terraform 1.5.7, exact provider versions) with reasoning

## Key Patterns in This Template

### Terraform (see [terraform.md](copilot/terraform.md))

- Azure regions: `westeurope` (primary), `northeurope` (DR)
- Environments: `dev`, `uat`, `prod` with validation rules
- Naming: `<project>-<environment>-<resource>-<instance>`
- State: Azure Storage backend with partial configuration

### PowerShell (see [powershell.md](copilot/powershell.md))

- Always use `[CmdletBinding()]` for advanced functions
- Comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`
- Public/Private folder structure for modules

### Azure Pipelines (see [azure-pipelines.md](copilot/azure-pipelines.md))

- Use `extends` templates for security, `template` includes for reusability
- Separate service connections per environment (`Azure-Dev-Terraform`, `Azure-Prod-Terraform`)
- Environment-based deployments with approval gates on `uat`/`prod`
- Store secrets in Key Vault-linked variable groups, never in YAML

## Documentation Requirements

- Every project needs a README.md with: Purpose, Prerequisites, Setup, Usage, Configuration
- Store planning docs in `docs/` directory with timestamp naming: `docs/plan-{yyyy-MM-dd_hh-mm}.md`

## Security

- Never hardcode secrets—use environment variables or Key Vault
- Service Principal credentials: document but never commit actual values
- Validate all inputs; follow least privilege
