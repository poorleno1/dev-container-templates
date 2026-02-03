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
    vim \
    file

echo "📦 Installing Claude CLI..."
curl -fsSL https://claude.ai/install.sh | bash

# Set up PowerShell modules for Azure
echo "📦 Installing PowerShell modules..."
#pwsh -c "Install-Module -Name Az -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name AzureAD -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name sqlserver -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name az.sql -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name az.accounts -RequiredVersion 4.0.2 -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name az.accounts -RequiredVersion 5.3.2 -Force -AllowClobber -Scope CurrentUser"

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
if [ -z "$(git config --global user.name)" ]; then
    echo "⚠️  Git user not configured. Please run:"
    echo "   git config --global user.name 'Your Name'"
    echo "   git config --global user.email 'your.email@example.com'"
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

# Copy SSH config if mounted
if [ -d "/home/vscode/.ssh-host" ]; then
    echo "🔐 Setting up SSH configuration..."
    cp -r /home/vscode/.ssh-host /home/vscode/.ssh
    chmod 700 /home/vscode/.ssh
    chmod 600 /home/vscode/.ssh/* 2>/dev/null || true
fi

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
echo "   4. Test Terraform: 'terraform --version'"
echo "   5. Test PowerShell: 'pwsh' then 'Get-Module -ListAvailable Az'"
echo ""
