# Azure Infrastructure Dev Container

This dev container provides a complete development environment for Azure infrastructure projects using Terraform, PowerShell, and Azure CLI.

## 🚀 What's Included

### Tools & Runtimes
- **Terraform** 1.7.0 (configurable version)
- **Azure CLI** (latest)
- **PowerShell Core** (latest)
- **Git** (latest)
- **Docker** (outside of Docker - DooD)
- **Common utilities** (curl, wget, jq, tree, etc.)

### VS Code Extensions
- Complete Azure extension pack
- Terraform language support with validation
- PowerShell extension
- Git and GitHub integration
- YAML/JSON support
- Docker support

### PowerShell Modules
- **Az** module (Azure PowerShell)
- **AzureAD** module

### Pre-configured Features
- Terraform provider cache for faster `terraform init`
- Useful aliases for common commands
- Port forwarding for web development
- Azure CLI extensions
- SSH configuration mounting

## 🔧 Quick Start

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
   
   # Test PowerShell with Azure
   pwsh -c "Get-Module -ListAvailable Az"
   ```

## 🛠️ Useful Aliases

The container includes these pre-configured aliases:

```bash
# Terraform shortcuts
tf          # terraform
tfi         # terraform init
tfp         # terraform plan  
tfa         # terraform apply
tfd         # terraform destroy
tfv         # terraform validate
tff         # terraform fmt

# Azure CLI shortcuts
az-login    # az login --use-device-code
az-accounts # az account list --output table
az-set      # az account set --subscription

# General shortcuts
ll          # ls -la
..          # cd ..
...         # cd ../..
```

## 📁 Container Structure

```
/workspaces/
├── .devcontainer/
│   ├── devcontainer.json     # Main configuration
│   ├── post-create.sh        # Setup script
│   └── README.md            # This file
├── scripts/                 # Your automation scripts
├── docs/                   # Documentation
└── .terraform.d/           # Terraform configuration
```

## 🔧 Customization

### Change Terraform Version
Edit `devcontainer.json`:
```json
"terraform": {
    "version": "1.6.0"  // Specify your version
}
```

### Add More Extensions
Add to the `extensions` array in `devcontainer.json`:
```json
"extensions": [
    "your.extension.id"
]
```

### Environment Variables
Add to `containerEnv` in `devcontainer.json`:
```json
"containerEnv": {
    "YOUR_VARIABLE": "your-value"
}
```

## 🔐 Azure Authentication

The container supports multiple authentication methods:

1. **Interactive Login** (recommended for development)
   ```bash
   az login
   ```

2. **Device Code Login** (for restricted environments)
   ```bash
   az login --use-device-code
   ```

3. **Service Principal** (for CI/CD)
   ```bash
   az login --service-principal -u <app-id> -p <password> --tenant <tenant>
   ```

## 🐳 Docker Integration

The container uses Docker-outside-of-Docker (DooD), allowing you to:
- Build and run containers
- Use Docker Compose
- Deploy containerized applications to Azure

## 📊 Resource Requirements

- **Minimum**: 4GB RAM, 2 CPUs
- **Recommended**: 8GB RAM, 4 CPUs
- **Complex scenarios**: 16GB+ RAM, 8 CPUs

## 🔍 Troubleshooting

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

## 📝 Notes

- Your Azure CLI configuration is mounted from your host machine
- SSH configuration is copied from host (if available)  
- Terraform provider cache speeds up `terraform init`
- Extensions are automatically installed on container creation
- All tools are pre-configured with sensible defaults

Happy coding! 🎉