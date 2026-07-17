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
    set -a
    # shellcheck source=/dev/null
    source <(sed 's/\r$//' "$ENV_FILE")
    set +a
    echo "Loaded environment from $ENV_FILE"
fi

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
    if [ -n "$AZURE_DEVOPS_PROJECT" ]; then
        az devops configure --defaults organization="$AZURE_DEVOPS_ORG_URL" project="$AZURE_DEVOPS_PROJECT" \
            && echo "Configured Azure DevOps organization: $AZURE_DEVOPS_ORG_URL, project: $AZURE_DEVOPS_PROJECT" \
            || echo "Failed to configure Azure DevOps organization/project"
    else
        az devops configure --defaults organization="$AZURE_DEVOPS_ORG_URL" \
            && echo "Configured Azure DevOps organization: $AZURE_DEVOPS_ORG_URL" \
            || echo "Failed to configure Azure DevOps organization"
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
