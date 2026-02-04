# Terraform — Project Constraints

## Critical Versions

- Terraform: **1.5.7 exactly** (last MPL 2.0 version)
- AzureRM provider: Pin exactly with `=`, document in README
- `required_version = "= 1.5.7"` in versions.tf

## Project-Specific Rules

**Regions (with validation):**

- Primary: `westeurope`
- Secondary: `northeurope`

**Environments (with validation):**

- `dev`, `uat`, `prod` only

**Naming:** `<project>-<environment>-<resource>-<instance>`
Storage accounts: no hyphens, max 24 chars

**Required Tags:** Name, Environment (DEV/UAT/PROD), Project, Owner

## State Backend

- Azure Storage with built-in locking
- Separate state per environment
- Init: `terraform init -backend-config="key=project/<env>/terraform.tfstate"`

## Authentication

- Service Principal via env vars (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID)
- Pipelines: prefer Managed Identity or Workload Identity Federation
- No auth block in provider config

## File Structure

```
backend.tf, main.tf, variables.tf, outputs.tf, versions.tf
terraform.tfvars.example
modules/<module-name>/
environments/{dev,uat,prod}/terraform.tfvars
```
