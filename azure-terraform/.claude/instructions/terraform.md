# Terraform Instructions

Apply these rules when working with Terraform files (`.tf`, `.tfvars`, `.hcl`).

## Version Requirements

- Use **Terraform 1.5.7 exactly**. This is the last MPL 2.0 licensed version. Versions 1.6.0+ use BSL 1.1.
- Pin the version constraint as `required_version = "= 1.5.7"` in `versions.tf`.

## Code Style

- Use 2-space indentation.
- Run `terraform fmt` before committing.
- Use `snake_case` for all resource names and variables.
- Group related resources logically within files.

## Azure Regions

- Primary: `westeurope` (Netherlands)
- Secondary/DR: `northeurope` (Ireland)
- Always add a validation block on the `location` variable restricting to these two regions.

## Environments

- Valid environments: `dev`, `uat`, `prod`.
- Add a validation block on the `environment` variable restricting to these values.

## Resource Naming

Use the pattern: `<project>-<environment>-<resource>-<instance>`

Storage accounts: no hyphens, max 24 characters (e.g., `myappdevsa001`).

## Tags

Include these tags on all taggable resources:
- `Name`
- `Environment` (DEV/UAT/PROD)
- `Project` / `Application`
- `Owner` / `Team`

## Provider Version Pinning

- Pin the AzureRM provider version exactly using `=` (not `~>`).
- Document the chosen version and reason in the project README.
- Provider upgrades must be deliberate and tested.

```hcl
# versions.tf
terraform {
  required_version = "= 1.5.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.85.0"  # Pinned - do not change without project review
    }
  }
}
```

> **Note:** The version `3.85.0` is an example. Select the appropriate version for your project.

## State Management

- Always use remote state with Azure Storage backend and built-in locking.
- Never commit `.tfstate` files.
- Use separate state files per environment.
- Use partial backend configuration with environment-specific keys via CLI flags.

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
  }
}
```

Initialize per environment:
```bash
terraform init -backend-config="key=project/dev/terraform.tfstate"
```

## Variables and Outputs

- Define all variables with `description` and `type`.
- Add `validation` blocks where appropriate.
- Set `default` values for optional variables.
- Export useful information as outputs with descriptions.

## Modules

- Follow the standard structure: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`.
- Pin module versions in production.

## Authentication

- Use Service Principal with environment variables (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`).
- No authentication block in the provider when using environment variables.
- For Azure DevOps pipelines: prefer Managed Identity (self-hosted agents) or Workload Identity Federation (Microsoft-hosted agents).

## File Organization

```
project/
├── backend.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── terraform.tfvars.example
├── modules/
│   └── [module-name]/
└── environments/
    ├── dev/
    │   └── terraform.tfvars
    ├── uat/
    │   └── terraform.tfvars
    └── prod/
        └── terraform.tfvars
```

## Anti-Patterns — Do Not

- Use placeholder values from examples without prompting for actual values.
- Hardcode secrets, passwords, or API keys.
- Use `latest` or unpinned provider/module versions.
- Create resources without required tags.
- Use deprecated syntax or APIs.
- Skip variable descriptions or types.
- Commit `.tfstate`, `.tfvars` (with secrets), or `.terraform/` directories.
- Use `count` when `for_each` with a map would be clearer.
- Create overly broad IAM/RBAC permissions.

## Validation

- Run `terraform validate` before applying.
- Use `terraform plan` to review changes.
- Consider `tflint` or `checkov` for security scanning.
