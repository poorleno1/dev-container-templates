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

# Install Node.js LTS (required by Cline MCP servers: filesystem + Azure MCP).
# Installed under ~/.local/nodejs to match the absolute path used in
# cline_mcp_settings.json:
#   - Azure MCP: /home/vscode/.local/nodejs/bin/npx
echo "📦 Installing Node.js (required by Cline MCP servers)..."
NODE_DIR="$HOME/.local/nodejs"
if [ ! -x "$NODE_DIR/bin/node" ]; then
    mkdir -p "$NODE_DIR"
    NODE_VERSION="$(curl -fsSL https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version' | sed 's/^v//')"
    echo "   Installing Node.js v${NODE_VERSION}..."
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
        | tar -xJ --strip-components=1 -C "$NODE_DIR"
fi
export PATH="$NODE_DIR/bin:$PATH"

# Persist Node's bin directory on PATH for future shell sessions.
NODE_PATH_LINE='export PATH="$HOME/.local/nodejs/bin:$PATH"'
grep -qxF "$NODE_PATH_LINE" ~/.bashrc || echo "$NODE_PATH_LINE" >> ~/.bashrc
grep -qxF "$NODE_PATH_LINE" ~/.zshrc || echo "$NODE_PATH_LINE" >> ~/.zshrc

# Install the Cline MCP filesystem server package at the path referenced by
# cline_mcp_settings.json:
#   - Filesystem MCP: /home/vscode/Documents/Cline/MCP/filesystem
echo "📁 Installing Cline MCP filesystem server package..."
FS_MCP_DIR="$HOME/Documents/Cline/MCP/filesystem"
if [ ! -d "$FS_MCP_DIR/node_modules/@modelcontextprotocol/server-filesystem" ]; then
    mkdir -p "$FS_MCP_DIR"
    (cd "$FS_MCP_DIR" && "$NODE_DIR/bin/npm" install @modelcontextprotocol/server-filesystem --no-fund --no-audit)
fi

# Pre-cache the Azure MCP server package globally so npx can start it instantly.
# The Azure MCP server is configured in cline_mcp_settings.json and .claude/mcp.json
# using: /home/vscode/.local/nodejs/bin/npx -y @azure/mcp@latest server start
echo "☁️  Pre-caching Azure MCP server package..."
"$NODE_DIR/bin/npm" install -g @azure/mcp@latest --no-fund --no-audit

# Install the official GitHub MCP server binary at the paths referenced by
# cline_mcp_settings.json:
#   - GitHub MCP: /home/vscode/.local/bin/github-mcp-stdio (wrapper)
#                 -> /home/vscode/.local/bin/github-mcp-server (binary)
#
# The remote endpoint (https://api.githubcopilot.com/mcp/) cannot be used from
# Cline: its OAuth server does not support dynamic client registration, so Cline
# fails with "Incompatible auth server". The local binary avoids OAuth entirely
# and reads a PAT from the environment instead.
echo "🐙 Installing GitHub MCP server..."
GH_MCP_VERSION="1.9.0"
GH_MCP_BIN="$HOME/.local/bin/github-mcp-server"
mkdir -p "$HOME/.local/bin"
if ! "$GH_MCP_BIN" --version 2>/dev/null | grep -q "Version: ${GH_MCP_VERSION}"; then
    case "$(uname -m)" in
        x86_64) GH_MCP_ARCH="x86_64" ;;
        aarch64 | arm64) GH_MCP_ARCH="arm64" ;;
        *) GH_MCP_ARCH="" ;;
    esac

    if [ -z "$GH_MCP_ARCH" ]; then
        echo "⚠️  Unsupported architecture $(uname -m); skipping GitHub MCP server install."
    else
        GH_MCP_TMP="$(mktemp -d)"
        GH_MCP_URL="https://github.com/github/github-mcp-server/releases/download/v${GH_MCP_VERSION}"
        GH_MCP_TAR="github-mcp-server_Linux_${GH_MCP_ARCH}.tar.gz"
        echo "   Installing github-mcp-server v${GH_MCP_VERSION} (${GH_MCP_ARCH})..."
        curl -fsSL -o "$GH_MCP_TMP/$GH_MCP_TAR" "$GH_MCP_URL/$GH_MCP_TAR"
        curl -fsSL -o "$GH_MCP_TMP/checksums.txt" \
            "$GH_MCP_URL/github-mcp-server_${GH_MCP_VERSION}_checksums.txt"
        (cd "$GH_MCP_TMP" && sha256sum --check --ignore-missing --status checksums.txt)
        tar -xzf "$GH_MCP_TMP/$GH_MCP_TAR" -C "$GH_MCP_TMP" github-mcp-server
        install -m 755 "$GH_MCP_TMP/github-mcp-server" "$GH_MCP_BIN"
        rm -rf "$GH_MCP_TMP"
    fi
fi

# Wrapper that supplies the token from the container environment. Cline performs
# no variable expansion in cline_mcp_settings.json, but it does spawn stdio MCP
# servers with the full parent environment - so the PAT stays in .env and never
# lands in the settings file.
cat > "$HOME/.local/bin/github-mcp-stdio" << 'GH_MCP_WRAPPER'
#!/usr/bin/env bash
# Launch the official GitHub MCP server over stdio.
# Accepts either GITHUB_PERSONAL_ACCESS_TOKEN (the server's native variable) or
# GITHUB_TOKEN (what this devcontainer's .env provides).
set -euo pipefail

TOKEN="${GITHUB_PERSONAL_ACCESS_TOKEN:-${GITHUB_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
    echo "github-mcp-stdio: no GITHUB_PERSONAL_ACCESS_TOKEN or GITHUB_TOKEN in environment" >&2
    exit 1
fi

exec env GITHUB_PERSONAL_ACCESS_TOKEN="$TOKEN" \
    "$(dirname "$(readlink -f "$0")")/github-mcp-server" stdio "$@"
GH_MCP_WRAPPER
chmod 755 "$HOME/.local/bin/github-mcp-stdio"

# Install uv/uvx — a fast Python package/tool runner. Needed to run the
# Specify CLI (spec-kit: `uvx --from git+https://github.com/github/spec-kit.git
# specify ...`) without polluting the system interpreter; also generally
# useful for any other Python-based dev tool run via `uvx`.
#
# Installs to ~/.local/bin, which .profile already puts on PATH — no extra
# PATH wiring needed. Like the GitHub MCP binary above, this is not a mounted
# volume, so a rebuild wipes it and this script re-running is what keeps it
# present.
echo "🐍 Installing uv/uvx..."
if [ ! -x "$HOME/.local/bin/uv" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "   uv already installed, skipping."
fi

# Install the sooperset/mcp-atlassian server (Jira + Confluence) at the path
# referenced by .claude/mcp.json:
#   - Atlassian MCP: /home/vscode/.local/bin/mcp-atlassian
#
# This is a --user pip install, so it lands under ~/.local like the GitHub MCP
# binary above - not a mounted/persistent volume, so a rebuild wipes it. This
# script re-running on every rebuild is what keeps it present.
# Reads CONFLUENCE_URL/CONFLUENCE_USERNAME/CONFLUENCE_API_TOKEN and
# JIRA_URL/JIRA_USERNAME/JIRA_API_TOKEN from the container environment (.env).
echo "🔗 Installing Atlassian MCP server (Jira + Confluence)..."
python3 -m pip install --user --break-system-packages --quiet "mcp-atlassian==0.23.1"

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

# Keep Azure CLI and installed extensions current in non-interactive builds.
# Set AZ_UPGRADE_ON_CREATE=false to skip this during container creation.
if [ "${AZ_UPGRADE_ON_CREATE:-true}" = "true" ]; then
    echo "⬆️  Upgrading Azure CLI and extensions..."
    az upgrade --all --yes || echo "⚠️  Azure CLI upgrade failed; continuing with current version."
    az --version
fi

az config set core.login_experience_v2=off
az config set core.enable_broker_on_windows=false

# Log in to Azure using Service Principal environment variables
echo "🔐 Logging in to Azure..."
if [ -n "${ARM_CLIENT_ID:-}" ] && [ -n "${ARM_CLIENT_SECRET:-}" ] && [ -n "${ARM_TENANT_ID:-}" ]; then
        az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID"
    if [ -n "${ARM_SUBSCRIPTION_ID:-}" ]; then
        az account set --subscription "$ARM_SUBSCRIPTION_ID"
    fi
    echo "✅ Azure login successful."
else
    echo "⚠️  Azure login skipped: ARM_CLIENT_ID, ARM_CLIENT_SECRET, or ARM_TENANT_ID is not set."
fi

az config set extension.use_dynamic_install=yes_without_prompt


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
az extension add --name azure-devops 2>/dev/null || true
az extension add --name application-insights 2>/dev/null || true
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
