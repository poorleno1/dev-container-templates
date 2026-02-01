# Claude Code Setup for Dev Container Templates

## Overview

This guide explains how to configure Claude Code AI assistant for dev containers. The settings persist across container rebuilds and provide a consistent experience for all team members.

## Why Configure Claude Code?

### The Problem
Without configuration, dev containers require manual Claude Code permission setup each time the container rebuilds. This is time-consuming and inconsistent across team members.

### The Solution
Workspace-level settings stored in `.claude/settings.local.json`:
- ✅ Persist across dev container rebuilds
- ✅ Shared with entire team via Git
- ✅ No manual reconfiguration needed
- ✅ Consistent AI assistant behavior

---

## Quick Setup

### Method 1: Use Template Settings

When you use a dev container template from this repository, Claude Code settings are included automatically:

```bash
# Copy template (includes Claude settings)
gh repo clone poorleno1/dev-container-templates temp-templates
cp -r temp-templates/azure-terraform/.devcontainer ./
mkdir -p .claude
cp temp-templates/.claude/settings.local.json ./.claude/

# Cleanup and rebuild
rm -rf temp-templates
code .
# Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

### Method 2: Manual Download

Add Claude settings to an existing dev container:

```bash
# Create .claude directory
mkdir -p .claude

# Download template settings
curl -o .claude/settings.local.json \
  https://raw.githubusercontent.com/poorleno1/dev-container-templates/main/.claude/settings.local.json

# Commit to your repository
git add .claude/settings.local.json
git commit -m "Add: Claude Code settings"
```

---

## What's Configured

### Auto-Approve Patterns (Safe Commands)

These commands run without asking for permission:

**File Operations:**
```bash
ls, pwd, cat, head, tail, find, grep, tree
```

**Git (Read-Only):**
```bash
git status, git log, git diff, git branch, git show
```

**Azure CLI (Read-Only):**
```bash
az account show/list, az group list, az resource list
az <anything> show/list
```

**Terraform (Safe Operations):**
```bash
terraform init, terraform plan, terraform fmt, terraform validate
terraform output, terraform show, terraform version
```

**Docker (Read-Only):**
```bash
docker ps, docker images, docker logs, docker info
```

**PowerShell (Read Cmdlets):**
```powershell
Get-*, Select-*, Where-*, Format-*, Out-*, Test-Path
```

### Block Patterns (Safety)

These commands are blocked or always require confirmation:

```bash
rm -rf              # File deletion
terraform destroy   # Infrastructure destruction
terraform apply     # Infrastructure changes
git push --force    # Force push
git reset --hard    # Hard reset
az delete/create    # Azure changes
docker rm/rmi       # Container removal
DROP, DELETE FROM   # Database operations
```

### Tool-Specific Settings

**Terraform:**
- Auto-approve: `plan`, `init`, `fmt`, `validate`
- Confirm: `apply`, `destroy`
- Auto-format on save: enabled

**Git:**
- Auto-approve: `add`, `checkout`, `status`, `log`, `diff`
- Confirm: `push`
- Default branch: `main`

**Azure:**
- Auto-approve: login, read operations
- Confirm: destructive operations

---

## Testing the Setup

After container rebuild, test by asking Claude to:

### Should Auto-Approve ✅
- "run git status"
- "run terraform plan"
- "run az account list"
- "run docker ps"

### Should Ask for Confirmation ⚠️
- "run terraform apply"
- "run git push"
- "run az group create"
- "run docker rm container_name"

---

## Customization

### Add New Auto-Approve Command

Edit `.claude/settings.local.json`:

```json
{
  "permissions": {
    "autoApprove": {
      "Bash": {
        "allowPatterns": [
          // ... existing patterns ...
          "^kubectl get"     // Add this
        ]
      }
    }
  }
}
```

### Block a New Command

```json
{
  "permissions": {
    "autoApprove": {
      "Bash": {
        "blockPatterns": [
          // ... existing blocks ...
          "kubectl delete"   // Add this
        ]
      }
    }
  }
}
```

### Change Tool Behavior

```json
{
  "git": {
    "confirmCommit": true,    // Now ask before commits
    "confirmPush": true,      // Keep asking before push
    "defaultBranch": "master" // Change default branch
  }
}
```

---

## For Team Collaboration

### Sharing Settings

1. **Commit `.claude/settings.local.json`** to your repository
2. **Team members pull** the changes
3. **Rebuild containers** to apply settings
4. **Everyone has the same** AI assistant behavior

### Version Control

The `.claude/settings.local.json` file is:
- ✅ Tracked in Git (not in `.gitignore`)
- ✅ Shared across team
- ✅ Versioned with your project
- ✅ Part of your dev container setup

### Updating Settings

When you update settings:
```bash
# Edit settings
code .claude/settings.local.json

# Commit changes
git add .claude/settings.local.json
git commit -m "Update: Claude Code permissions"
git push

# Team members:
git pull
# Rebuild container to apply
```

---

## Troubleshooting

### Settings Not Working

1. **Verify file exists:**
   ```bash
   ls -la .claude/settings.local.json
   ```

2. **Check JSON syntax:**
   ```bash
   cat .claude/settings.local.json | jq .
   ```

3. **Restart VS Code:**
   - Close all windows
   - Reopen in container

4. **Rebuild container:**
   - `Ctrl+Shift+P`
   - "Dev Containers: Rebuild Container"

### Different Behavior Across Team

- Ensure everyone has latest: `git pull`
- Rebuild containers: Sometimes needed after pull
- Check for user-level overrides: `cat ~/.claude/settings.json`

---

## Advanced Configuration

### Project-Specific Settings

Different projects can have different settings:

**Project A** (Infrastructure):
```json
{
  "terraform": { "confirmApply": true },
  "azure": { "confirmDestructive": true }
}
```

**Project B** (Development):
```json
{
  "git": { "confirmCommit": false },
  "docker": { "confirmDestructive": false }
}
```

### Minimal Settings

For simple projects, use minimal settings:

```json
{
  "permissions": {
    "autoApprove": {
      "Read": true,
      "Glob": true,
      "Grep": true,
      "Bash": {
        "enabled": true,
        "allowPatterns": [
          "^git status$",
          "^terraform plan"
        ],
        "blockPatterns": [
          "terraform apply",
          "git push"
        ]
      }
    }
  }
}
```

### Maximum Security

For production/sensitive projects:

```json
{
  "permissions": {
    "autoApprove": {
      "Read": true,
      "Glob": true,
      "Grep": true,
      "Bash": {
        "enabled": false  // Disable all auto-approve
      }
    }
  }
}
```

---

## Migration from GitHub Copilot

If you have GitHub Copilot `chat.tools.terminal.autoApprove` settings:

1. **Extract patterns** from your VS Code settings
2. **Convert to Claude format**:
   - `"command": true` → `"^command"`
   - `"command*": true` → `"^command"`
   - `/^pattern/i` → `"^pattern"`

3. **Add safety blocks** (Copilot doesn't have these)
4. **Commit to repository**

Example conversion:
```json
// GitHub Copilot
"git log": true

// Claude Code
"allowPatterns": ["^git log"]
```

---

## Best Practices

### DO ✅
- Keep settings in `.claude/settings.local.json` (workspace-level)
- Commit settings to repository
- Test before pushing to team
- Document changes in commits
- Review and update periodically

### DON'T ❌
- Use user-level settings in dev containers (they're ephemeral)
- Add `.claude/` to `.gitignore`
- Make breaking changes without team discussion
- Add overly permissive patterns without blocks
- Forget to test destructive operation blocks

---

## MCP Servers (Model Context Protocol)

### What are MCP Servers?

MCP servers extend Claude Code's capabilities with specialized tools and integrations. The dev container templates include pre-configured MCP servers.

### Configured MCP Servers

**1. HashiCorp Terraform MCP Server**
- Terraform operations and state management
- HCP Terraform (Terraform Cloud) integration
- Workspace querying and inspection

**2. Microsoft Playwright MCP**
- Browser automation and testing
- Web page screenshots and DOM inspection
- Useful for validating deployed applications

**3. Microsoft Learn MCP**
- Access to Microsoft documentation
- Azure, PowerShell, and .NET reference
- Best practices and tutorials

### MCP Configuration Files

When you copy the template, you get:
- **`.claude/mcp.json`** - MCP servers configuration
- **`.env.template`** - Environment variables template

### Setting Up MCP Servers

**Step 1: Copy environment template**

```bash
# Copy template to .env
cp .env.template .env
```

**Step 2: Add your credentials (if using Terraform MCP)**

```bash
# Edit .env and add your HCP Terraform token
# TFE_TOKEN=your-terraform-cloud-token
```

**Step 3: Rebuild dev container**

MCP servers will be loaded automatically when the container starts.

### Testing MCP Servers

Ask Claude to use MCP servers:
- "Use Terraform MCP to show me workspaces"
- "Use Playwright to take a screenshot of https://terraform.io"
- "Search Microsoft Learn for Azure Terraform documentation"

### MCP Security

**Important:**
- `.env` is in `.gitignore` - never commit it
- `ENABLE_TF_OPERATIONS=false` by default (prevents accidental infrastructure changes)
- Only enable Terraform operations when explicitly needed

---

## Resources

- **Template Repository**: [poorleno1/dev-container-templates](https://github.com/poorleno1/dev-container-templates)
- **Claude Code Documentation**: [Claude Code Official Docs](https://docs.anthropic.com/claude/docs/claude-code)
- **Dev Containers Guide**: [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- **MCP Specification**: [Model Context Protocol](https://spec.modelcontextprotocol.io/)

---

## Support

For issues or questions:
1. Check this documentation
2. Review `.claude/settings.local.json` syntax
3. Check `.claude/mcp.json` for MCP configuration
4. Try rebuilding dev container
5. Open an issue in the templates repository

---

**Last Updated**: 2026-02-01
**Scope**: Dev Container Templates
**Purpose**: Persistent Claude Code configuration with MCP servers
