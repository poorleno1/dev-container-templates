# Terraform Instructions

When working with Terraform files (.tf, .tfvars, .hcl), follow these specific guidelines:

## Version Requirements

- **Use Terraform version 1.5.7 exactly** - This is the last open source version under MPL 2.0 license
- Versions 1.6.0 and later use BSL 1.1 (Business Source License) which may require a license for commercial use
- Alternative: Consider [OpenTofu](https://opentofu.org/) as an open source fork if newer features are required

```hcl
# versions.tf
terraform {
  required_version = "= 1.5.7"
}
```

## Code Style and Formatting

- Use 2 spaces for indentation (configured in .editorconfig)
- Run `terraform fmt` before committing
- Use snake_case for resource names and variables
- Group related resources together logically

## Resource Management

- Use descriptive resource names that indicate their purpose
- Include tags on all taggable resources with at minimum:
  - Name
  - Environment (DEV/UAT/PROD)
  - Project/Application
  - Owner/Team
- Use data sources instead of hardcoded values when possible

### Azure Region Selection

All Azure resources should be deployed to one of the following regions:

- **Primary:** `westeurope` (Netherlands)
- **Secondary/DR:** `northeurope` (Ireland)

```hcl
# Define location as a variable with validation
variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "westeurope"

  validation {
    condition     = contains(["westeurope", "northeurope"], var.location)
    error_message = "Location must be westeurope or northeurope."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], lower(var.environment))
    error_message = "Environment must be DEV, UAT, or PROD."
  }
}
```

### Resource Naming Convention

Use consistent naming pattern: `<project>-<environment>-<resource>-<instance>`

```hcl
# Examples
resource "azurerm_resource_group" "main" {
  name     = "myapp-dev-rg-001"
  location = var.location
}

resource "azurerm_storage_account" "data" {
  name     = "myappdevsa001"  # Storage accounts: no hyphens, max 24 chars
  location = var.location
}
```

## Anti-Patterns to Avoid

Do NOT generate code that:

- Uses placeholder values from examples without prompting user for actual values
- Hardcodes secrets, passwords, or API keys
- Uses `latest` or unpinned provider/module versions
- Creates resources without required tags
- Uses deprecated syntax or APIs
- Skips variable descriptions or types
- Commits `.tfstate`, `.tfvars` (with secrets), or `.terraform/` directories
- Uses `count` when `for_each` with a map would be clearer
- Creates overly broad IAM/RBAC permissions

> **Note:** All example values in this document (e.g., `tfstateaccount`, `3.85.0`) are placeholders. Always prompt the user for project-specific values.

## Variables and Outputs

- Define all variables with descriptions and types
- Use validation rules for variables when appropriate
- Set default values for optional variables
- Export useful information as outputs with descriptions

## State Management

- Always use remote state for team projects
- Configure state locking when using remote backends
- Never commit .tfstate files to version control
- Use separate state files for different environments

### Azure Backend Configuration

Use Azure Storage Account for remote state with built-in locking:

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "project/env/terraform.tfstate"
  }
}
```

### Partial Backend Configuration (Recommended)

Keep environment-specific values out of code using CLI flags:

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

Initialize with environment-specific key:

```bash
# DEV environment
terraform init -backend-config="key=project/dev/terraform.tfstate"

# UAT environment
terraform init -backend-config="key=project/uat/terraform.tfstate"

# PROD environment
terraform init -backend-config="key=project/prod/terraform.tfstate"
```

For CI/CD pipelines, use variables:

```bash
terraform init -backend-config="key=$PROJECT_NAME/$ENVIRONMENT/terraform.tfstate"
```

### Backend Storage Requirements

- Enable storage account versioning for state recovery
- Enable soft delete on the container
- Use private endpoints where possible
- Restrict access using Azure RBAC or SAS tokens
- Enable storage account encryption (enabled by default)

## Modules

- Create reusable modules for common patterns
- Follow module best practices:
  - README.md with usage examples
  - variables.tf with all input variables
  - outputs.tf with useful outputs
  - main.tf with primary resources
- Pin module versions in production

## Security

- Use terraform-docs to generate documentation
- Store sensitive variables in .tfvars files (not committed)
- Use data sources for existing resources instead of importing
- Implement resource-level security controls

## Azure Authentication

### Current Approach: Service Principal with Client Secret

For local user execution, authenticate using a Service Principal with client secret:

```bash
# Set environment variables (never commit these values)
export ARM_CLIENT_ID="<service-principal-app-id>"
export ARM_CLIENT_SECRET="<service-principal-secret>"
export ARM_SUBSCRIPTION_ID="<azure-subscription-id>"
export ARM_TENANT_ID="<azure-tenant-id>"
```

```hcl
# No authentication block needed in provider when using environment variables
provider "azurerm" {
  features {}
}
```

### Service Principal Requirements

- Create a dedicated Service Principal per project
- Grant minimum required RBAC permissions (Contributor on target resource groups)
- Set client secret expiration (recommended: 90-180 days)
- Store credentials securely (use a password manager or Azure Key Vault)
- Rotate secrets before expiration

### Future: Azure DevOps Integration

When migrating to Azure DevOps pipelines, choose authentication based on agent type:

#### Option 1: Managed Identity (Recommended for Self-Hosted Agents)

Best practice when using self-hosted agents running on Azure infrastructure:

- Create a User-Assigned Managed Identity
- Assign the identity to the Azure VM/VMSS running the agent
- Grant RBAC permissions to the Managed Identity
- Create service connection using Managed Identity authentication

**Benefits:**

- No secrets to manage or rotate
- Azure handles credential lifecycle automatically
- Most secure option available

```hcl
# Provider configuration for Managed Identity (AzureRM 3.x+)
provider "azurerm" {
  features {}
  use_oidc                   = true
  skip_provider_registration = true
}
```

#### Option 2: Workload Identity Federation (Microsoft-Hosted Agents)

Use when running on Microsoft-hosted agents (cannot use Managed Identity):

- Create an Azure Resource Manager service connection
- Enable Workload Identity Federation (OIDC) - no secrets to manage
- Service connection scoped to specific environments

#### Service Connection Guidelines

- Create separate service connections per environment (dev/staging/prod)
- Remove local Service Principal access after pipeline is operational
- Use environment-specific RBAC scoping

```yaml
# azure-pipelines.yml example
- task: AzureCLI@2
  inputs:
    azureSubscription: "MyServiceConnection"
    scriptType: "bash"
    scriptLocation: "inlineScript"
    inlineScript: |
      terraform init -backend-config="key=$(environment)/terraform.tfstate"
      terraform plan -out=tfplan
      terraform apply tfplan
```

### Authentication Transition Checklist

- [ ] Document current Service Principal details in secure location
- [ ] Decide agent type: self-hosted (Managed Identity) or Microsoft-hosted (OIDC)
- [ ] For self-hosted: Create Managed Identity and assign to agent VM/VMSS
- [ ] For Microsoft-hosted: Create service connection with Workload Identity
- [ ] Test pipeline with non-production environment
- [ ] Migrate production deployments to pipeline
- [ ] Revoke local Service Principal client secret
- [ ] Update documentation to reflect new process

## Validation and Testing

- Run `terraform validate` before applying
- Use `terraform plan` to review changes
- Consider using tools like tflint or checkov for security scanning
- Test modules with multiple scenarios

## File Organization

```
project/
├── backend.tf              # Backend configuration
├── main.tf                 # Primary resources
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Provider requirements
├── terraform.tfvars.example # Example variables
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

## Provider Configuration

- Always specify provider versions in versions.tf
- Configure provider-specific settings appropriately
- Consider using provider aliases for multi-region deployments

### Azure RM Provider Version Pinning

- **Pin the AzureRM provider version exactly** - Once chosen for a project, do not change it
- Use exact version constraint (`=`) rather than pessimistic (`~>`) to prevent unintended upgrades
- Provider version upgrades should be a deliberate, planned activity with proper testing
- Document the chosen version and reason in the project README

> **Note:** The version `3.85.0` below is an example. Check the [AzureRM provider releases](https://registry.terraform.io/providers/hashicorp/azurerm/latest) and select the appropriate version for your project.

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

**Why pin provider versions:**

- Prevents breaking changes from automatic upgrades
- Ensures consistent behavior across all environments
- Makes deployments reproducible
- Allows controlled, tested upgrades when needed
