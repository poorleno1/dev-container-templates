#!/bin/bash

# Post-creation script for Azure Infrastructure Dev Container
echo "🚀 Setting up Azure Infrastructure Development Environment..."

# Update package lists
sudo apt-get update

# Install additional useful tools
sudo apt-get install -y \
    curl \
    wget \
    unzip \
    jq \
    tree \
    htop \
    nano \
    vim

# Set up PowerShell modules for Azure
echo "📦 Installing PowerShell modules..."
pwsh -c "Install-Module -Name Az -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name AzureAD -Force -AllowClobber -Scope CurrentUser"

# Install Terraform providers cache (speeds up terraform init)
echo "🏗️ Pre-downloading common Terraform providers..."
mkdir -p ~/.terraform.d/plugin-cache
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# Create a temporary terraform configuration to download common providers
cat > /tmp/providers.tf << 'EOF'
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}
EOF

cd /tmp && terraform init && cd - && rm -rf /tmp/.terraform /tmp/providers.tf

# Set up Git configuration (if not already configured)
echo "📝 Setting up Git configuration..."
if [ -z "$(git config --global user.name)" ]; then
    echo "⚠️  Git user not configured. Please run:"
    echo "   git config --global user.name 'Your Name'"
    echo "   git config --global user.email 'your.email@example.com'"
fi

# Configure git for better dev container experience
git config --global credential.helper 'cache --timeout=3600'
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global safe.directory '*'

# Create SSH config for Azure DevOps if it doesn't exist
if [ ! -f "/home/vscode/.ssh/config" ]; then
    cat > /home/vscode/.ssh/config << 'EOF'
# Azure DevOps SSH configuration
Host ssh.dev.azure.com
  HostName ssh.dev.azure.com
  User git
  Port 22
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_rsa
  PubkeyAcceptedAlgorithms +ssh-rsa
  HostkeyAlgorithms +ssh-rsa

# GitHub SSH configuration (if needed)
Host github.com
  HostName github.com
  User git
  Port 22
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_rsa
EOF
    chmod 600 /home/vscode/.ssh/config
    echo "✅ SSH config created"
fi

# Create useful aliases
echo "🔧 Setting up aliases..."
cat >> ~/.bashrc << 'EOF'

# Azure and Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'
alias tff='terraform fmt'

alias az-login='az login --use-device-code'
alias az-accounts='az account list --output table'
alias az-set='az account set --subscription'

# Useful shortcuts
alias ll='ls -la'
alias la='ls -la'
alias ..='cd ..'
alias ...='cd ../..'
EOF

# Set up Terraform CLI configuration
echo "🔧 Setting up Terraform configuration..."
mkdir -p ~/.terraform.d
cat > ~/.terraform.d/terraform.rc << 'EOF'
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
disable_checkpoint = true
EOF

# Set up SSH agent and configuration
echo "🔐 Setting up SSH configuration..."

# Ensure SSH directory exists with correct permissions
if [ ! -d "/home/vscode/.ssh" ]; then
    mkdir -p /home/vscode/.ssh
    chmod 700 /home/vscode/.ssh
fi

# Set correct permissions for SSH files if they exist
if [ -d "/home/vscode/.ssh" ]; then
    # Set directory permissions
    chmod 700 /home/vscode/.ssh
    
    # Set permissions for private keys
    find /home/vscode/.ssh -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
    
    # Set permissions for public keys
    find /home/vscode/.ssh -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
    
    # Set permissions for config file
    if [ -f "/home/vscode/.ssh/config" ]; then
        chmod 600 /home/vscode/.ssh/config
    fi
    
    # Set permissions for known_hosts
    if [ -f "/home/vscode/.ssh/known_hosts" ]; then
        chmod 644 /home/vscode/.ssh/known_hosts
    fi
    
    echo "✅ SSH permissions set correctly"
fi

# Add Azure DevOps to known hosts if not already there
echo "🔐 Adding Azure DevOps to known hosts..."
ssh-keyscan -t rsa ssh.dev.azure.com >> /home/vscode/.ssh/known_hosts 2>/dev/null || true

# Set up Azure CLI extensions
echo "🔧 Installing Azure CLI extensions..."
az extension add --name azure-devops --system 2>/dev/null || true
az extension add --name application-insights --system 2>/dev/null || true

# Create workspace directories
echo "📁 Creating workspace structure..."
mkdir -p /workspaces/scripts
mkdir -p /workspaces/docs
mkdir -p /workspaces/.terraform.d

echo "✅ Post-creation setup completed!"
echo ""
echo "🔧 Next steps:"
echo "   1. Run 'az login' to authenticate with Azure"
echo "   2. Configure git: git config --global user.name 'Your Name'"
echo "   3. Configure git: git config --global user.email 'your.email@example.com'"
echo "   4. Test SSH to Azure DevOps: ssh -T git@ssh.dev.azure.com"
echo "   5. Test Terraform: 'terraform --version'"
echo "   6. Test PowerShell: 'pwsh' then 'Get-Module -ListAvailable Az'"
echo ""
echo "🔐 SSH Keys:"
echo "   - Your host SSH keys are automatically mounted"
echo "   - If you need new keys: ssh-keygen -t rsa -b 4096 -C 'your.email@example.com'"
echo "   - Add public key to Azure DevOps: Settings > SSH public keys"
echo ""