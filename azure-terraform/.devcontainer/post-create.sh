#!/bin/bash
set -euo pipefail

# Post-creation script for Azure Infrastructure Dev Container
echo "🚀 Setting up Azure Infrastructure Development Environment..."

# Keep PowerShell as the vscode user's login shell.
current_shell="$(getent passwd vscode | cut -d: -f7)"
pwsh_path="$(which pwsh)"
if [ "$current_shell" != "$pwsh_path" ]; then
    sudo chsh vscode -s "$pwsh_path"
fi

# Normalize Git behavior for the mounted workspace.
git config --global core.autocrlf false
git config --global core.safecrlf warn
git config --global core.filemode false

# Install tfenv once, then ensure required Terraform versions are present.
if [ ! -d "$HOME/.tfenv" ]; then
    git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
fi

"$HOME/.tfenv/bin/tfenv" install 1.2.9
"$HOME/.tfenv/bin/tfenv" install 1.4.0
"$HOME/.tfenv/bin/tfenv" use 1.2.9

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
    file \
    dnsutils \
    python3 \
    python3-pip \
    ripgrep


#echo "📦 Installing Claude CLI..."
#curl -fsSL https://claude.ai/install.sh | bash

# Set up PowerShell modules for Azure
echo "📦 Installing PowerShell modules..."
#pwsh -c "Install-Module -Name Az -Force -AllowClobber -Scope CurrentUser"
#pwsh -c "Install-Module -Name AzureAD -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name sqlserver -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name az.sql -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name az.accounts -RequiredVersion 4.0.2 -Force -AllowClobber -Scope CurrentUser"
pwsh -c "Install-Module -Name az.accounts -RequiredVersion 5.3.2 -Force -AllowClobber -Scope CurrentUser"




# # Create useful aliases and environment variable loading
# echo "🔧 Setting up aliases and environment variables..."
# cat >> ~/.bashrc << 'EOF'

# Load environment variables from .env file (for AI agents and MCP servers)
# if [ -f "/workspaces/Infrastructure/.env" ]; then
#     set -a  # Export all variables
#     source "/workspaces/Infrastructure/.env"
#     set +a  # Stop exporting
# fi

echo "🔧 Checking Azure CLI version..."
az --version

# Keep Azure CLI and installed extensions current in non-interactive builds.
# Set AZ_UPGRADE_ON_CREATE=false to skip this during container creation.
if [ "${AZ_UPGRADE_ON_CREATE:-true}" = "true" ]; then
    echo "⬆️  Upgrading Azure CLI and extensions..."
    az upgrade --all --yes || echo "⚠️  Azure CLI upgrade failed; continuing with current version."
    az --version
fi

az config set core.login_experience_v2=off
az config set core.enable_broker_on_windows=false

# Azure login is handled by postStartCommand (post-start.sh), which runs immediately
# after this script on initial creation and again on every subsequent container start.

az config set extension.use_dynamic_install=yes_without_prompt


# # Copy SSH config if mounted
# if [ -d "/home/vscode/.ssh-host" ]; then
#     echo "🔐 Setting up SSH configuration..."
#     cp -r /home/vscode/.ssh-host /home/vscode/.ssh
#     chmod 700 /home/vscode/.ssh
#     chmod 600 /home/vscode/.ssh/* 2>/dev/null || true
# fi

# Set up Azure CLI extensions
echo "🔧 Installing Azure CLI extensions..."
az extension add --name azure-devops --system 2>/dev/null || true
az extension add --name application-insights --system 2>/dev/null || true
az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.dynamic_install_allow_preview=true

# Keep the remote VS Code UI minimal by removing unwanted extensions.
echo "🧹 Removing unwanted VS Code extensions..."
if command -v code >/dev/null 2>&1; then
    for ext in \
        dbaeumer.vscode-eslint \
        ms-python.vscode-pylance \
        ms-python.autopep8 \
        ms-python.debugpy \
        ms-python.vscode-python-envs \
        Continue.continue \
        saoudrizwan.continue \
        ms-python.python
    do
        code --uninstall-extension "$ext" >/dev/null 2>&1 || true
    done
    # Retry python uninstall after dependent extensions are removed.
    code --uninstall-extension ms-python.python >/dev/null 2>&1 || true
else
    echo "⚠️  VS Code CLI not found during post-create; skipping extension cleanup."
fi

echo "✅ Post-creation setup completed!"
echo ""
echo "🔧 Next steps:"
echo "   1. Run 'az login' to authenticate with Azure"
echo "   2. Configure git: git config --global user.name 'Your Name'"
echo "   3. Configure git: git config --global user.email 'your.email@example.com'"
echo "   4. Test Terraform: 'terraform --version'"
echo "   5. Test PowerShell: 'pwsh' then 'Get-Module -ListAvailable Az'"
echo ""
