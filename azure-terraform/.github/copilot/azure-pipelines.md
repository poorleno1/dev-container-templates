# Azure Pipelines Instructions

When working with Azure DevOps pipeline files (`azure-pipelines.yml`, `*.yml` in `.azure-pipelines/`), follow these guidelines for Terraform infrastructure deployments.

## File Conventions

- **Main pipeline**: `azure-pipelines.yml` in repository root
- **Templates**: Store in `.azure-pipelines/templates/` directory
- **Variable files**: Store in `.azure-pipelines/variables/` directory
- Use 2-space indentation (consistent with Terraform files)

```
project/
├── azure-pipelines.yml           # Main pipeline definition
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
    └── ...
```

## Template Strategy

Use **extends templates** for security enforcement and **includes templates** for reusability:

```yaml
# azure-pipelines.yml - Entry point extends a controlled template
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - terraform/**

extends:
  template: .azure-pipelines/templates/terraform-pipeline.yml
  parameters:
    terraformVersion: "1.5.7"
    workingDirectory: "terraform"
```

### Parameterized Stage Template

```yaml
# .azure-pipelines/templates/stages/terraform-deploy.yml
parameters:
  - name: environment
    type: string
    values: ["dev", "uat", "prod"]
  - name: azureSubscription
    type: string
  - name: dependsOn
    type: object
    default: []

stages:
  - stage: Deploy_${{ parameters.environment }}
    displayName: "Deploy to ${{ upper(parameters.environment) }}"
    dependsOn: ${{ parameters.dependsOn }}
    variables:
      - template: ../variables/${{ parameters.environment }}.yml
    jobs:
      - deployment: TerraformApply
        environment: ${{ parameters.environment }}
        strategy:
          runOnce:
            deploy:
              steps:
                - template: ../steps/terraform-init.yml
                  parameters:
                    azureSubscription: ${{ parameters.azureSubscription }}
                - template: ../steps/terraform-apply.yml
```

## Terraform Task Patterns

### Initialization with Backend Configuration

```yaml
# .azure-pipelines/templates/steps/terraform-init.yml
parameters:
  - name: azureSubscription
    type: string
  - name: backendResourceGroup
    type: string
    default: "tfstate-rg"
  - name: backendStorageAccount
    type: string
  - name: backendContainer
    type: string
    default: "tfstate"

steps:
  - task: TerraformInstaller@1
    displayName: "Install Terraform 1.5.7"
    inputs:
      terraformVersion: "1.5.7"

  - task: TerraformTaskV4@4
    displayName: "Terraform Init"
    inputs:
      provider: "azurerm"
      command: "init"
      workingDirectory: "$(Build.SourcesDirectory)/terraform"
      backendServiceArm: "${{ parameters.azureSubscription }}"
      backendAzureRmResourceGroupName: "${{ parameters.backendResourceGroup }}"
      backendAzureRmStorageAccountName: "${{ parameters.backendStorageAccount }}"
      backendAzureRmContainerName: "${{ parameters.backendContainer }}"
      backendAzureRmKey: "$(System.TeamProject)/$(Build.Repository.Name)/$(environment).tfstate"
```

### Plan with Output Artifact

```yaml
steps:
  - task: TerraformTaskV4@4
    displayName: "Terraform Plan"
    inputs:
      provider: "azurerm"
      command: "plan"
      workingDirectory: "$(Build.SourcesDirectory)/terraform"
      environmentServiceNameAzureRM: "${{ parameters.azureSubscription }}"
      commandOptions: "-out=$(Build.ArtifactStagingDirectory)/tfplan -input=false"

  - task: PublishPipelineArtifact@1
    displayName: "Publish Plan Artifact"
    inputs:
      targetPath: "$(Build.ArtifactStagingDirectory)/tfplan"
      artifact: "tfplan-$(environment)"
```

### Apply from Saved Plan

```yaml
steps:
  - task: DownloadPipelineArtifact@2
    displayName: "Download Plan Artifact"
    inputs:
      artifact: "tfplan-$(environment)"
      path: "$(Build.ArtifactStagingDirectory)"

  - task: TerraformTaskV4@4
    displayName: "Terraform Apply"
    inputs:
      provider: "azurerm"
      command: "apply"
      workingDirectory: "$(Build.SourcesDirectory)/terraform"
      environmentServiceNameAzureRM: "${{ parameters.azureSubscription }}"
      commandOptions: "$(Build.ArtifactStagingDirectory)/tfplan"
```

## Environment and Approval Configuration

### Environment-Based Deployments

Use Azure DevOps Environments for approval gates—configure these in Azure DevOps UI, not YAML:

```yaml
jobs:
  - deployment: Deploy
    environment: prod # Requires approval configured in Azure DevOps
    strategy:
      runOnce:
        deploy:
          steps:
            - template: ../steps/terraform-apply.yml
```

**Environment Setup (Azure DevOps UI):**

- Create environments: `dev`, `uat`, `prod`
- Add approval checks on `uat` and `prod`
- Configure exclusive lock to prevent concurrent deployments
- Add business hours check for `prod` if needed

## Variable Management

### Variable Templates per Environment

```yaml
# .azure-pipelines/variables/prod.yml
variables:
  environment: "prod"
  azureSubscription: "Azure-Prod-ServiceConnection"
  location: "westeurope"
  backendStorageAccount: "tfstateprodsa" # No secrets here
```

### Key Vault Integration for Secrets

```yaml
variables:
  - group: "terraform-secrets" # Variable group linked to Key Vault
  - template: variables/$(environment).yml

steps:
  - task: TerraformTaskV4@4
    displayName: "Terraform Apply"
    inputs:
      command: "apply"
      # Secrets from Key Vault passed as environment variables
    env:
      TF_VAR_sql_admin_password: $(sql-admin-password) # From Key Vault
```

## Service Connection Security

### Connection Naming Convention

`Azure-<Environment>-<Purpose>`: e.g., `Azure-Prod-Terraform`, `Azure-Dev-Terraform`

### Least Privilege Configuration

- Create separate service connections per environment
- Scope to specific resource groups when possible
- Use Workload Identity Federation (OIDC) instead of client secrets
- Never use a single connection for all environments

```yaml
parameters:
  - name: environment
    type: string
    values: ["dev", "uat", "prod"]

variables:
  ${{ if eq(parameters.environment, 'dev') }}:
    azureSubscription: "Azure-Dev-Terraform"
  ${{ if eq(parameters.environment, 'uat') }}:
    azureSubscription: "Azure-UAT-Terraform"
  ${{ if eq(parameters.environment, 'prod') }}:
    azureSubscription: "Azure-Prod-Terraform"
```

## Anti-Patterns to Avoid

Do NOT generate pipelines that:

- **Inline secrets**: Use `$(password)` directly without Key Vault
- **Skip plan artifacts**: Apply without reviewing saved plan
- **Single service connection**: Same connection for dev/uat/prod
- **Missing environment gates**: Deploy to prod without approval checks
- **Hardcoded values**: Environment names, subscription IDs in main pipeline
- **No path triggers**: Run pipeline on every commit, not just terraform changes
- **Classic pipelines**: Generate YAML, not classic release definitions
- **Unversioned templates**: Reference templates without pinned refs from other repos

```yaml
# BAD - Avoid this pattern
variables:
  sqlPassword: 'SuperSecret123!'  # Never hardcode secrets

# GOOD - Use Key Vault reference
variables:
  - group: 'terraform-secrets'  # Linked to Key Vault
```

## Validation Steps

Include validation before apply:

```yaml
steps:
  - task: TerraformTaskV4@4
    displayName: "Terraform Validate"
    inputs:
      command: "validate"
      workingDirectory: "$(Build.SourcesDirectory)/terraform"

  - script: |
      terraform fmt -check -recursive
    displayName: "Terraform Format Check"
    workingDirectory: "$(Build.SourcesDirectory)/terraform"
```

## Multi-Environment Pipeline Structure

```yaml
# Complete pipeline with dev → uat → prod progression
trigger:
  branches:
    include: [main]
  paths:
    include: [terraform/**]

stages:
  - template: .azure-pipelines/templates/stages/terraform-deploy.yml
    parameters:
      environment: dev
      azureSubscription: "Azure-Dev-Terraform"

  - template: .azure-pipelines/templates/stages/terraform-deploy.yml
    parameters:
      environment: uat
      azureSubscription: "Azure-UAT-Terraform"
      dependsOn: [Deploy_dev]

  - template: .azure-pipelines/templates/stages/terraform-deploy.yml
    parameters:
      environment: prod
      azureSubscription: "Azure-Prod-Terraform"
      dependsOn: [Deploy_uat]
```
