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
    file \
    dnsutils \
    python3 \
    python3-pip

# Install Playwright system dependencies and Chromium browser
echo "🎭 Installing Playwright dependencies..."
npx -y playwright@latest install-deps chromium
npx -y playwright@latest install chromium

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


# Set up Git configuration (if not already configured)
if [ -z "$(git config --global user.name)" ]; then
    echo "⚠️  Git user not configured. Please run:"
    echo "   git config --global user.name 'Your Name'"
    echo "   git config --global user.email 'your.email@example.com'"
fi

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
az config set core.login_experience_v2=off
az config set core.enable_broker_on_windows=false

# Log in to Azure using Service Principal environment variables
echo "🔐 Logging in to Azure..."
if [ -n "$ARM_CLIENT_ID" ] && [ -n "$ARM_CLIENT_SECRET" ] && [ -n "$ARM_TENANT_ID" ]; then
        az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID"
    if [ -n "$ARM_SUBSCRIPTION_ID" ]; then
        az account set --subscription "$ARM_SUBSCRIPTION_ID"
    fi
    echo "✅ Azure login successful."
else
    echo "⚠️  Azure login skipped: ARM_CLIENT_ID, ARM_CLIENT_SECRET, or ARM_TENANT_ID is not set."
fi

az config set extension.use_dynamic_install=yes_without_prompt
# or, if you prefer confirmation:
az config set extension.use_dynamic_install=yes_prompt
az extension add --name azure-devops


# Add to PowerShell profile
echo "🔧 Setting up PowerShell profile..."
mkdir -p ~/.config/powershell
cat >> ~/.config/powershell/Microsoft.PowerShell_profile.ps1 << 'EOF'

# # Load environment variables from .env file (for AI agents and MCP servers)
# $envFile = "/workspaces/Infrastructure/.env"
# if (Test-Path $envFile) {
#     Get-Content $envFile | ForEach-Object {
#         if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
#             $name = $matches[1].Trim()
#             $value = $matches[2].Trim()
#             [System.Environment]::SetEnvironmentVariable($name, $value, [System.EnvironmentVariableTarget]::Process)
#         }
#     }
# }
EOF


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
