# Azure Pipelines — Project Rules

## File Structure

```
azure-pipelines.yml (root)
.azure-pipelines/
  templates/{stages,jobs,steps}/
  variables/{dev,uat,prod}.yml
```

## Terraform Integration

- Install: `TerraformInstaller@1` with version 1.5.7
- Task: `TerraformTaskV4@4`
- **Always save plan as artifact, apply from artifact**

## Environments & Deployment

- Environments: `dev`, `uat`, `prod`
- Progression: dev → uat → prod (use `dependsOn`)
- Approval gates on uat/prod (configured in UI)
- Exclusive lock to prevent concurrent deploys

## Service Connections

- Naming: `Azure-<Environment>-<Purpose>`
- **Separate connection per environment**
- Use Workload Identity Federation (OIDC), not client secrets

## Variables & Secrets

- Variable templates: `.azure-pipelines/variables/{env}.yml`
- **Secrets via Key Vault-linked variable groups only**
- Pass to Terraform as `TF_VAR_` environment variables

## Path Triggers

```yaml
trigger:
  branches: [main]
  paths:
    include: [terraform/**]
```

## Validation

Include `terraform validate` and `terraform fmt -check -recursive` before plan/apply
