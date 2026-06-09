#!/bin/bash

# Post-start script for Azure Infrastructure Dev Container
# Runs every time the container starts (not just on creation)

# Link tfenv binaries
for f in ~/.tfenv/bin/*; do
    [ -f /usr/local/bin/$(basename $f) ] || sudo ln -s $f /usr/local/bin/$(basename $f)
done

# Fix SSH permissions
chmod 700 ~/.ssh && chmod 600 ~/.ssh/* && chmod 644 ~/.ssh/*.pub 2>/dev/null || true

# Load environment variables from .env if present
ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/.env"
if [ -f "$ENV_FILE" ]; then
    # .env is often edited on Windows; normalize CRLF to avoid bash parsing errors.
    if grep -q $'\r' "$ENV_FILE"; then
        sed -i 's/\r$//' "$ENV_FILE"
    fi
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
    echo "Loaded environment from $ENV_FILE"
fi

# Trim accidental CR and wrapping quotes from env values commonly used in CLI auth.
ARM_CLIENT_ID="${ARM_CLIENT_ID:-}"
ARM_CLIENT_SECRET="${ARM_CLIENT_SECRET:-}"
ARM_TENANT_ID="${ARM_TENANT_ID:-}"
ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-}"
AZURE_DEVOPS_EXT_PAT="${AZURE_DEVOPS_EXT_PAT:-}"
AZURE_DEVOPS_ORG_URL="${AZURE_DEVOPS_ORG_URL:-}"

for _var in ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_TENANT_ID ARM_SUBSCRIPTION_ID AZURE_DEVOPS_EXT_PAT AZURE_DEVOPS_ORG_URL; do
    _val="${!_var}"
    _val="${_val%$'\r'}"
    _val="${_val#\"}"
    _val="${_val%\"}"
    _val="${_val#\'}"
    _val="${_val%\'}"
    printf -v "$_var" '%s' "$_val"
    export "$_var"
done

# Authenticate with Azure service principal
if [ -n "$ARM_CLIENT_ID" ] && [ -n "$ARM_CLIENT_SECRET" ] && [ -n "$ARM_TENANT_ID" ]; then
    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" \
        && echo "Logged in to Azure with service principal" \
        && if [ -n "$ARM_SUBSCRIPTION_ID" ]; then az account set --subscription "$ARM_SUBSCRIPTION_ID"; fi
else
    echo "No Azure SP credentials found - use az login manually"
fi

# Configure Azure DevOps
if [ -n "$AZURE_DEVOPS_EXT_PAT" ] && [ -n "$AZURE_DEVOPS_ORG_URL" ]; then
    if [[ "$AZURE_DEVOPS_ORG_URL" =~ ^https://dev\.azure\.com/ ]]; then
        echo "Azure DevOps environment variables detected"
    else
        echo "AZURE_DEVOPS_ORG_URL is set but does not look valid: expected https://dev.azure.com/<org>"
    fi
else
    echo "No Azure DevOps credentials found - skipping configuration"
fi

# Wire shared Copilot prompts into VS Code Server user directory via symlink.
# We cannot bind-mount directly into .vscode-server/ at container creation time because
# Docker would create intermediate directories (data/, User/) owned by root before VS Code
# Server installs itself, breaking the vscode user's write access and crashing the container.
# By mounting to a neutral path (~/.copilot-prompts) and symlinking here (after VS Code Server
# is already installed and owns .vscode-server/data/User/), we avoid that race entirely.
COPILOT_PROMPTS_DIR="$HOME/.vscode-server/data/User/prompts"
COPILOT_MOUNT="$HOME/.copilot-prompts"
if [ -d "$COPILOT_MOUNT" ]; then
    mkdir -p "$HOME/.vscode-server/data/User"
    # Remove existing dir (not symlink) so ln -sfn can create the link cleanly
    [ -d "$COPILOT_PROMPTS_DIR" ] && [ ! -L "$COPILOT_PROMPTS_DIR" ] && rm -rf "$COPILOT_PROMPTS_DIR"
    ln -sfn "$COPILOT_MOUNT" "$COPILOT_PROMPTS_DIR"
    echo "Copilot prompts symlinked: $COPILOT_PROMPTS_DIR -> $COPILOT_MOUNT"
else
    mkdir -p "$COPILOT_PROMPTS_DIR"
    echo "COPILOT_PROMPTS_HOME not mounted; prompts are container-local at: $COPILOT_PROMPTS_DIR"
fi

# Apply MCP server configuration from persisted file in mounted ~/.claude directory
if [ -f ~/.claude/mcp-servers.json ]; then
    python3 -c "
import json, os
config_path = os.path.expanduser('~/.claude.json')
mcp_path = os.path.expanduser('~/.claude/mcp-servers.json')
config = json.load(open(config_path)) if os.path.exists(config_path) else {}
config['mcpServers'] = json.load(open(mcp_path))
json.dump(config, open(config_path, 'w'), indent=2)
"
    echo "MCP servers config applied from ~/.claude/mcp-servers.json"
fi
