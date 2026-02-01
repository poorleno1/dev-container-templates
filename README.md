# Dev Container Templates

> **Remember:** This repository contains reusable dev container configurations for different development environments. You can use these templates across multiple projects to maintain consistency and save time.

## 🚀 Quick Start

### For the Impatient (Using GitHub CLI)
```bash
# Navigate to your project root
cd /path/to/your/project

# Copy a template (replace 'azure-terraform' with desired template)
gh repo clone poorleno1/dev-container-templates temp-templates
cp -r temp-templates/azure-terraform/.devcontainer ./
mkdir -p .claude
cp temp-templates/.claude/settings.local.json ./.claude/  # Claude Code settings
rm -rf temp-templates

# Open in VS Code and rebuild container
code .
# Then: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

### Configure Claude Code Settings (Optional but Recommended)

If you're using Claude Code as your AI assistant, the template includes workspace-level settings that persist across container rebuilds:

**What's included:**
- ✅ Auto-approves safe commands: `git status`, `terraform plan`, `az account list`, `docker ps`
- ⚠️ Requires confirmation for: `terraform apply`, `git push`, `az group create`
- 🔒 Blocks dangerous commands: `rm -rf`, `terraform destroy`, `git push --force`
- 💾 Persists across dev container rebuilds
- 👥 Shared configuration across team members

**Testing after container rebuild:**
```bash
# Ask Claude to run these commands:
# "run git status" → should auto-approve ✓
# "run terraform apply" → should ask for confirmation ✓
```

**Customization:**
Edit `.claude/settings.local.json` to adjust auto-approve patterns for your workflow.

**Learn more:** See [docs/CLAUDE-CODE-SETUP.md](docs/CLAUDE-CODE-SETUP.md) for complete setup guide, customization options, and migration from GitHub Copilot.

---

## 📋 Available Templates

| Template | Description | Key Tools |
|----------|-------------|-----------|
| **azure-terraform** | Azure infrastructure with Terraform | Azure CLI, Terraform v1.2.9, PowerShell 7, GitHub CLI |
| **python-data-science** | Python data analysis environment | Python, Jupyter, pandas, numpy *(coming soon)* |
| **node-react** | Node.js React development | Node.js, npm, React tools *(coming soon)* |
| **basic-linux** | Minimal Linux development | Common utilities, git *(coming soon)* |

## 🎯 Detailed Usage Guide

### Method 1: Using the Setup Script (Recommended)

1. **Download the setup script:**
   ```bash
   curl -o setup-devcontainer.sh https://raw.githubusercontent.com/poorleno1/dev-container-templates/main/scripts/setup-devcontainer.sh
   chmod +x setup-devcontainer.sh
   ```

2. **Run the script:**
   ```bash
   # Basic usage
   ./setup-devcontainer.sh azure-terraform

   # Specify target directory
   ./setup-devcontainer.sh azure-terraform /path/to/project
   
   # List available templates
   ./setup-devcontainer.sh --list
   ```

### Method 2: Manual Copy (When You Need Control)

1. **Clone the templates repository:**
   ```bash
   gh repo clone poorleno1/dev-container-templates
   ```

2. **Copy the template you need:**
   ```bash
   cp -r dev-container-templates/azure-terraform/.devcontainer /your/project/
   mkdir -p /your/project/.claude
   cp dev-container-templates/.claude/settings.local.json /your/project/.claude/
   ```

3. **Customize as needed** (edit `devcontainer.json`, add scripts, etc.)

4. **Open in VS Code:**
   ```bash
   code /your/project
   ```

5. **Rebuild the container:**
   - `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

### Method 3: Using Gists (For Quick Sharing)

Create a gist of a specific configuration:
```bash
cd dev-container-templates/azure-terraform
gh gist create .devcontainer/devcontainer.json --desc "Azure Terraform Dev Container"
```

Use a gist in a new project:
```bash
gh gist clone <gist-id> temp-gist
cp temp-gist/devcontainer.json .devcontainer/
rm -rf temp-gist
```

## 🛠️ Template Details

### Azure Terraform Template (`azure-terraform/`)

**Perfect for:** Infrastructure as Code projects using Azure and Terraform

**What's included:**
- **Azure CLI** - Pre-authenticated (you'll need to run `az login`)
- **Terraform v1.2.9** - Infrastructure provisioning
- **PowerShell 7** (latest) - Azure scripting and automation
- **GitHub CLI** - Repository and gist management
- **Claude Code settings** - Pre-configured auto-approve patterns for safe commands
- **Common utilities** - git, curl, wget, jq, tree, etc.

**Base Image:** `mcr.microsoft.com/powershell:lts-debian-11`

**After container starts:**
1. Run `az login` to authenticate with Azure
2. Run `gh auth login` to authenticate with GitHub (if needed)
3. Your PowerShell modules (Az, AzureAD) are pre-installed

**File structure:**
```
azure-terraform/
├── .devcontainer/
│   ├── devcontainer.json      # Main configuration
│   ├── post-create.sh         # Setup script run after container creation
│   ├── README.md              # Template-specific documentation
│   └── TROUBLESHOOTING.md     # Common issues and solutions
```

## 🔧 Customization Guide

### Modifying Templates

1. **Clone this repository:**
   ```bash
   gh repo clone poorleno1/dev-container-templates
   cd dev-container-templates
   ```

2. **Edit the template files:**
   - Modify `devcontainer.json` for features, extensions, settings
   - Edit `post-create.sh` for additional setup steps
   - Update version numbers, add/remove tools

3. **Test your changes:**
   - Copy to a test project and rebuild container
   - Verify all tools work as expected

4. **Commit and push:**
   ```bash
   git add .
   git commit -m "Update azure-terraform template with new tools"
   git push origin main
   ```

### Creating New Templates

1. **Create directory structure:**
   ```bash
   mkdir -p new-template-name/.devcontainer
   ```

2. **Create basic files:**
   ```bash
   # Copy from existing template as starting point
   cp azure-terraform/.devcontainer/devcontainer.json new-template-name/.devcontainer/
   ```

3. **Modify for your needs:**
   - Change base image
   - Add/remove features
   - Update extensions list
   - Create custom post-create script

4. **Document your template:**
   - Add description to this README
   - Create template-specific README
   - Add to the templates table above

## 📚 Common Use Cases & Examples

### Starting a New Azure Project
```bash
# Create new project directory
mkdir my-azure-project && cd my-azure-project

# Initialize git
git init

# Set up dev container
gh repo clone poorleno1/dev-container-templates temp-templates
cp -r temp-templates/azure-terraform/.devcontainer ./
rm -rf temp-templates

# Open in VS Code
code .
# Then rebuild container when prompted
```

### Adding Dev Container to Existing Project
```bash
# In your existing project directory
./setup-devcontainer.sh azure-terraform .

# Or manually:
gh repo clone poorleno1/dev-container-templates temp-templates
cp -r temp-templates/azure-terraform/.devcontainer ./
rm -rf temp-templates
```

### Sharing Configuration with Team
```bash
# Create a gist for quick sharing
cd .devcontainer
gh gist create devcontainer.json --desc "Project XYZ Dev Container Config"

# Team members can use:
gh gist clone <gist-id>
```

### Working with Multiple Azure Subscriptions
After container starts:
```bash
# Login and select subscription
az login
az account list --output table
az account set --subscription "Your-Subscription-Name"

# Verify current subscription
az account show --query name
```

## 🐛 Troubleshooting

### Common Issues

**Container build fails:**
- Check if base image is available
- Verify feature versions in `devcontainer.json`
- Look at build logs for specific errors

**Tools not working after rebuild:**
- Check if tools are in PATH: `which terraform`
- Verify authentication: `az account show`, `gh auth status`
- Re-run post-create script manually if needed

**PowerShell version warnings:**
- Base image might have old PowerShell
- Feature should install latest version
- Check with: `pwsh --version`

**Authentication issues:**
```bash
# Re-authenticate with Azure
az login --use-device-code

# Re-authenticate with GitHub
gh auth login
```

### Getting Help

1. **Check template documentation** in `template-name/.devcontainer/README.md`
2. **Look at troubleshooting guide** in `TROUBLESHOOTING.md`
3. **Open an issue** in this repository
4. **Check VS Code dev container docs:** https://code.visualstudio.com/docs/devcontainers/containers

## 🔄 Keeping Templates Updated

### Regular Maintenance

1. **Update tool versions:**
   - Check for new Terraform releases
   - Update base images
   - Update VS Code extensions

2. **Test templates regularly:**
   - Build containers from scratch
   - Verify all tools work
   - Check for deprecation warnings

3. **Monitor dependencies:**
   - Watch for breaking changes in features
   - Update documentation
   - Test with latest VS Code versions

### Version Management

Use git tags for stable versions:
```bash
# Tag stable version
git tag -a v1.0.0 -m "Stable azure-terraform template with Terraform 1.2.9"
git push origin v1.0.0

# Use specific version
gh repo clone poorleno1/dev-container-templates@v1.0.0
```

## 📈 Advanced Topics

### Custom Features
You can create your own dev container features:
```bash
# Create custom feature repository
gh repo create my-devcontainer-features

# Reference in devcontainer.json
"features": {
    "ghcr.io/yourname/my-devcontainer-features/my-feature:1": {}
}
```

### Multi-stage Containers
For complex setups, consider using a custom Dockerfile:
```dockerfile
FROM mcr.microsoft.com/powershell:lts-debian-11
# Add your custom setup here
```

### Environment Variables
Set consistent environment variables:
```json
{
    "containerEnv": {
        "AZURE_SUBSCRIPTION_ID": "your-subscription-id",
        "TF_LOG": "INFO"
    }
}
```

## 🤝 Contributing

1. **Fork this repository**
2. **Create a feature branch:** `git checkout -b feature/new-template`
3. **Add your template** following the existing structure
4. **Update this README** with template information
5. **Test thoroughly** in real projects
6. **Submit a pull request**

## 📝 Notes for Future Me

> Since you mentioned you tend to forget things, here are key reminders:

### Quick Reference Commands
```bash
# List my repositories
gh repo list

# Create new repository
gh repo create <name> --public

# Authentication status
gh auth status
az account show

# Rebuild dev container
# Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

### File Locations
- **This templates repo:** `https://github.com/poorleno1/dev-container-templates`
- **Local clone:** `/home/vscode/dev-container-templates` (in dev container)
- **Setup script:** `scripts/setup-devcontainer.sh`

### Common Workflow
1. Need dev container for new project → Use this repository
2. Want to share configuration → Create gist: `gh gist create .devcontainer/devcontainer.json`
3. Template needs updates → Clone this repo, edit, commit, push
4. New project type needed → Add template directory, document here

### Remember These URLs
- [Dev Containers documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [Available features](https://github.com/devcontainers/features)
- [This repository](https://github.com/poorleno1/dev-container-templates)

---

## 📄 License

This project is licensed under the MIT License - feel free to use, modify, and share.

---

*Last updated: January 5, 2026*  
*Maintainer: poorleno1*  
*Repository: https://github.com/poorleno1/dev-container-templates*
