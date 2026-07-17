#!/bin/bash
set -euo pipefail

line='export PATH="$HOME/.tfenv/bin:$PATH"'

grep -qxF "$line" ~/.bashrc || echo "$line" >> ~/.bashrc
grep -qxF "$line" ~/.zshrc || echo "$line" >> ~/.zshrc



# Add to PowerShell profile
PROFILE_PATH=~/.config/powershell/Microsoft.PowerShell_profile.ps1
mkdir -p ~/.config/powershell
grep -qF '$envFile = "/workspaces/Infrastructure/.env"' "$PROFILE_PATH" 2>/dev/null || cat >> "$PROFILE_PATH" << 'EOF'

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
