#!/bin/bash

# Post-start script for Azure Infrastructure Dev Container
# Runs every time the container starts (not just on creation)

# Link tfenv binaries
for f in ~/.tfenv/bin/*; do
    [ -f /usr/local/bin/$(basename $f) ] || sudo ln -s $f /usr/local/bin/$(basename $f)
done

# Fix SSH permissions
chmod 700 ~/.ssh && chmod 600 ~/.ssh/* && chmod 644 ~/.ssh/*.pub 2>/dev/null || true

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
    az devops configure --defaults organization="$AZURE_DEVOPS_ORG_URL" \
        && echo "Configured Azure DevOps organization: $AZURE_DEVOPS_ORG_URL" \
        || echo "Failed to configure Azure DevOps organization"
else
    echo "No Azure DevOps credentials found - skipping configuration"
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
