# Azure Infrastructure Dev Container

This dev container provides a development environment for Azure infrastructure work using Terraform, PowerShell, Azure CLI, and GitHub CLI.

## Current Configuration

### Base Image and Features

- Base image: `mcr.microsoft.com/devcontainers/base:debian-12`
- Features:
  - `ghcr.io/devcontainers/features/common-utils:2`
  - `ghcr.io/devcontainers/features/azure-cli:1`
  - `ghcr.io/devcontainers/features/powershell:2.0.2` with runtime `latest`
  - `ghcr.io/devcontainers/features/github-cli:1`
  - `ghcr.io/devcontainers/features/git:1` with version `latest`

### Lifecycle Scripts

- `postCreateCommand`: `.devcontainer/post-create.sh`
- `postStartCommand`: `.devcontainer/post-start.sh`
- `postAttachCommand`: `.devcontainer/post-attach.sh`

### Mounted Paths

- Workspace env file is passed through `runArgs --env-file ${localWorkspaceFolder}/.env`
- Host `.ssh` is mounted to `/home/vscode/.ssh`
- Host `${localEnv:CLAUDE_HOME}` is mounted to `/home/vscode/.claude`
- Host `${localEnv:COPILOT_HOME}/globalStorage` is mounted to `/home/vscode/.copilot-globalStorage`
- Host `${localEnv:COPILOT_HOME}/workspaceStorage` is mounted to `/home/vscode/.copilot-workspaceStorage`

### VS Code Defaults (Container)

- Default terminal profile: `pwsh`
- Terraform language server enabled
- Terraform file associations for `*.tf` and `*.tfvars`
- Installed extensions:
  - `ms-vscode.powershell`
  - `HashiCorp.terraform`
  - `ms-vscode.azurecli`
  - `ms-azure-devops.azure-pipelines`
  - `GitHub.copilot-chat`
  - `ms-vscode.vscode-json`
  - `esbenp.prettier-vscode`
  - `emmanuelbeziat.vscode-great-icons`

## Quick Start

1. **Open in Dev Container**
   - Open VS Code in your project folder
   - Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
   - Wait for container to build (first time takes a few minutes)

2. **Authenticate with Azure**

   ```bash
   az login
   ```

3. **Configure Git** (if not already done)

   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

4. **Test Your Setup**

   ```bash
   # Test Terraform
   terraform --version

   # Test Azure CLI
   az account list

   # Test PowerShell modules installed by post-create
   pwsh -c "Get-Module -ListAvailable az.accounts,az.sql,sqlserver"
   ```

## Container Structure

```
/workspaces/
├── .devcontainer/
│   ├── devcontainer.json     # Main configuration
│   ├── post-create.sh        # Runs once on create
│   ├── post-start.sh         # Runs on each start
│   ├── post-attach.sh        # Runs on each attach
│   └── README.md            # This file
```

## Azure Authentication

The container supports multiple authentication methods:

1. **Interactive Login** (recommended for development)

   ```bash
   az login
   ```

2. **Device Code Login** (for restricted environments)

   ```bash
   az login --use-device-code
   ```

3. **Service Principal** (automatic during create/start when ARM variables are present)
   ```bash
   az login --service-principal -u <app-id> -p <password> --tenant <tenant>
   ```

## Resource Notes

- **Minimum**: 4GB RAM, 2 CPUs
- **Recommended**: 8GB RAM, 4 CPUs

## Notes

- `post-create.sh` installs `tfenv` and Terraform versions `1.2.9` and `1.4.0`, then sets `1.2.9` as default.
- `post-create.sh` also installs PowerShell modules `sqlserver`, `az.sql`, and two `az.accounts` versions.
- `post-start.sh` links `~/.tfenv/bin` tools into `/usr/local/bin`, fixes SSH permissions, and applies Azure/Azure DevOps login configuration when environment variables are present.
- `post-attach.sh` adds `~/.tfenv/bin` PATH lines idempotently to both `.bashrc` and `.zshrc`.

## Troubleshooting

### Container won't start

- Ensure Docker Desktop is running
- Check you have enough system resources
- Try rebuilding: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

### Azure authentication issues

- Clear Azure CLI cache: `az account clear`
- Re-authenticate: `az login`
- Check your tenant/subscription: `az account show`

### Terraform provider issues

- Clear provider cache: `rm -rf ~/.terraform.d/plugin-cache/*`
- Reinitialize: `terraform init -upgrade`

Happy coding.
