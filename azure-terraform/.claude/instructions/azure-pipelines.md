# Azure Pipelines Instructions

Apply these rules when working with Azure DevOps pipeline files (`azure-pipelines.yml`, `*.yml` in `.azure-pipelines/`).

## File Conventions

- Main pipeline: `azure-pipelines.yml` in repository root.
- Templates: `.azure-pipelines/templates/` (organized into `stages/`, `jobs/`, `steps/`).
- Variable files: `.azure-pipelines/variables/` (one per environment).
- Use 2-space indentation.

```
project/
├── azure-pipelines.yml
├── .azure-pipelines/
│   ├── templates/
│   │   ├── stages/
│   │   │   └── terraform-deploy.yml
│   │   ├── jobs/
│   │   │   └── terraform-plan.yml
│   │   └── steps/
│   │       └── terraform-init.yml
│   └── variables/
│       ├── dev.yml
│       ├── uat.yml
│       └── prod.yml
└── terraform/
```

## Template Strategy

- Use `extends` templates for security enforcement.
- Use `template` includes for reusability.
- Parameterize templates with typed parameters and `values` constraints.

## Terraform Tasks

- Install Terraform 1.5.7 using `TerraformInstaller@1`.
- Use `TerraformTaskV4@4` for init, plan, validate, and apply.
- Save plan output as a pipeline artifact (`tfplan-$(environment)`).
- Apply from the saved plan artifact, never directly.

## Environment Deployments

- Use Azure DevOps Environments for approval gates (configured in UI, not YAML).
- Create environments: `dev`, `uat`, `prod`.
- Add approval checks on `uat` and `prod`.
- Use exclusive lock to prevent concurrent deployments.
- Pipeline progression: `dev` → `uat` → `prod` with `dependsOn`.

## Variable Management

- Use variable templates per environment (`.azure-pipelines/variables/{env}.yml`).
- Store secrets in Key Vault-linked variable groups, never in YAML.
- Pass Key Vault secrets to Terraform via `TF_VAR_` environment variables.

## Service Connections

- Naming convention: `Azure-<Environment>-<Purpose>` (e.g., `Azure-Prod-Terraform`).
- Create separate service connections per environment.
- Use Workload Identity Federation (OIDC) instead of client secrets.
- Never use a single connection for all environments.

## Path Triggers

- Only trigger on relevant file changes:

```yaml
trigger:
  branches:
    include: [main]
  paths:
    include: [terraform/**]
```

## Validation Steps

Include `terraform validate` and `terraform fmt -check -recursive` before plan/apply.

## Anti-Patterns — Do Not

- Inline secrets in YAML (use Key Vault-linked variable groups).
- Apply without reviewing a saved plan artifact.
- Use a single service connection for dev/uat/prod.
- Deploy to prod without approval checks.
- Hardcode environment names or subscription IDs in the main pipeline.
- Run the pipeline on every commit (use path triggers).
- Generate classic release definitions (use YAML pipelines).
- Reference templates from other repos without pinned refs.
