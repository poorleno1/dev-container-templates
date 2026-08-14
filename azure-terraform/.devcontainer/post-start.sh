#!/bin/bash

# Post-start script for Azure Infrastructure Dev Container
# Runs every time the container starts (not just on creation)

# Link tfenv binaries
for f in ~/.tfenv/bin/*; do
    [ -f /usr/local/bin/$(basename $f) ] || sudo ln -s $f /usr/local/bin/$(basename $f)
done

# Fix SSH permissions
chmod 700 ~/.ssh && chmod 600 ~/.ssh/* && chmod 644 ~/.ssh/*.pub 2>/dev/null || true

# Load environment variables from .env if present.
#
# devcontainer.json passes .env to "docker run" via --env-file, but that is applied
# only when the container is CREATED. Editing .env and merely restarting the
# container ("Reopen in Container" without a rebuild) keeps the stale values baked
# into the container config. So on every start we re-read .env ourselves and write
# the values into shell startup files, which is what interactive terminals read.
#
# Parse the file literally instead of sourcing it, matching docker --env-file
# semantics: everything after the first "=" is the value, with no shell expansion
# and no quote stripping. Sourcing would diverge from what docker injected for any
# value containing $, spaces, or quotes.
ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/.env"
BASH_ENV_FILE="$HOME/.devcontainer-env.sh"
PWSH_ENV_FILE="$HOME/.devcontainer-env.ps1"

if [ -f "$ENV_FILE" ]; then
    # These hold secrets, so create them unreadable to anyone else before writing.
    for f in "$BASH_ENV_FILE" "$PWSH_ENV_FILE"; do
        : > "$f"
        chmod 600 "$f"
    done

    env_count=0
    while IFS= read -r line; do
        # Skip comments and anything that is not a KEY=VALUE assignment.
        case "$line" in
            '#'*) continue ;;
            *=*) ;;
            *) continue ;;
        esac
        key="${line%%=*}"
        value="${line#*=}"
        value="${value%$'\r'}"  # tolerate a CRLF .env authored on the Windows host
        case "$key" in
            [A-Za-z_]*) ;;
            *) continue ;;
        esac

        printf 'export %s=%q\n' "$key" "$value" >> "$BASH_ENV_FILE"
        # PowerShell single-quoted strings escape a quote by doubling it.
        printf "\$env:%s = '%s'\n" "$key" "${value//\'/\'\'}" >> "$PWSH_ENV_FILE"
        env_count=$((env_count + 1))
    done < "$ENV_FILE"

    # Apply to this script too, so the Azure logins below use the current values.
    set -a
    # shellcheck source=/dev/null
    source "$BASH_ENV_FILE"
    set +a
    echo "Loaded $env_count environment variables from $ENV_FILE"

    # Point every interactive shell at the generated files. Both the rc files and
    # the generated files live in the container filesystem, so these guards are
    # re-applied after each rebuild.
    BASH_SOURCE_LINE='[ -f "$HOME/.devcontainer-env.sh" ] && . "$HOME/.devcontainer-env.sh"'
    for rc in ~/.bashrc ~/.zshrc; do
        grep -qxF "$BASH_SOURCE_LINE" "$rc" 2>/dev/null || echo "$BASH_SOURCE_LINE" >> "$rc"
    done

    PWSH_PROFILE="$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
    PWSH_SOURCE_LINE='if (Test-Path "$HOME/.devcontainer-env.ps1") { . "$HOME/.devcontainer-env.ps1" }'
    mkdir -p "$(dirname "$PWSH_PROFILE")"
    grep -qxF "$PWSH_SOURCE_LINE" "$PWSH_PROFILE" 2>/dev/null || echo "$PWSH_SOURCE_LINE" >> "$PWSH_PROFILE"
else
    echo "⚠️  No .env found at $ENV_FILE - skipping environment variable loading"
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
    az devops configure --defaults organization="$AZURE_DEVOPS_ORG_URL" \
        && echo "Configured Azure DevOps organization: $AZURE_DEVOPS_ORG_URL" \
        || echo "Failed to configure Azure DevOps organization"
else
    echo "No Azure DevOps credentials found - skipping configuration"
fi

# Verify the AI-assistant history mounts are actually in place.
#
# Two failure modes lose chat history silently on rebuild:
#   1. The host variable is unset, so no bind mount is created at all and the
#      target is just an empty directory in the container's own filesystem.
#   2. The variable resolves to the drive root, so the mount points at C:\.
#
# Do not try to read the host path out of /proc/mounts: under WSL2 every 9p
# drvfs mount reports "path=C:\" (the drive, not the bind source), so a source
# comparison matches every correct mount too. Check the target instead.
check_history_mount() {
    local target="$1" label="$2" var="$3" example="$4"

    if ! grep -q " ${target} " /proc/mounts; then
        echo "⚠️  WARNING: ${label} history is NOT bind-mounted (${target})."
        echo "   It will be lost on the next container rebuild."
        echo "   Fix: set ${var} on the host (e.g. setx ${var} \"${example}\")"
        echo "   then run 'Dev Containers: Rebuild Container'."
        return
    fi

    # A drive-root mount exposes the Windows system folders.
    if [ -d "${target}/Windows" ] && [ -d "${target}/Users" ]; then
        echo "⚠️  WARNING: ${label} mount resolved to the drive root instead of ${var}."
        echo "   History will NOT persist across container rebuilds."
        echo "   Fix: ensure ${var} points at a real directory (e.g. ${example})"
        echo "   then run 'Dev Containers: Rebuild Container'."
    fi
}

check_history_mount "/home/vscode/.claude" "Claude Code" "CLAUDE_HOME" "C:\\Users\\<you>\\OneDrive\\.claude"
check_history_mount "/home/vscode/.cline" "Cline/Klein" "CLINE_HOME" "C:\\Users\\<you>\\OneDrive\\.cline"

# Persist Claude Code's global config inside the mounted ~/.claude directory.
#
# Conversation transcripts already survive rebuilds (~/.claude/projects/<slug>/*.jsonl
# is inside the CLAUDE_HOME mount), but Claude Code's global config normally lives at
# ~/.claude.json — in the container's own filesystem, which is wiped on every rebuild.
# That file holds the ↑ prompt history, per-project settings, and trust state.
#
# Claude Code resolves its config to ~/.claude/.config.json when that file exists,
# falling back to ~/.claude.json otherwise. Creating it inside the mount moves the
# config onto the host. Do NOT use CLAUDE_CONFIG_DIR for this: setting it also
# changes the credentials filename (a hash of the config dir is appended), which
# would force a re-login.
CLAUDE_CONFIG=~/.claude/.config.json
if [ -d ~/.claude ] && [ ! -f "$CLAUDE_CONFIG" ]; then
    if [ -f ~/.claude.json ]; then
        cp ~/.claude.json "$CLAUDE_CONFIG"
        echo "Seeded $CLAUDE_CONFIG from ~/.claude.json — Claude Code history now persists across rebuilds"
    else
        echo '{}' > "$CLAUDE_CONFIG"
        echo "Created $CLAUDE_CONFIG — Claude Code history now persists across rebuilds"
    fi
fi

# Apply MCP server configuration from persisted file in mounted ~/.claude directory.
# Written into whichever config file Claude Code will actually read.
if [ -f ~/.claude/mcp-servers.json ]; then
    TARGET="$CLAUDE_CONFIG"
    [ -f "$TARGET" ] || TARGET=~/.claude.json
    [ -f "$TARGET" ] || echo '{}' > "$TARGET"
    if jq --slurpfile mcp ~/.claude/mcp-servers.json '.mcpServers = $mcp[0]' "$TARGET" > "$TARGET.tmp"; then
        mv "$TARGET.tmp" "$TARGET"
        echo "MCP servers config applied from ~/.claude/mcp-servers.json to $TARGET"
    else
        rm -f "$TARGET.tmp"
        echo "⚠️  Failed to apply MCP servers config from ~/.claude/mcp-servers.json"
    fi
fi
