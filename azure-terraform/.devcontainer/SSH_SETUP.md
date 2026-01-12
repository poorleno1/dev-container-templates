# SSH Keys Setup for Dev Container

## Recommended Approach: SSH Agent Forwarding

This dev container is configured to automatically mount your host SSH keys, which is the **most secure approach**. No need to copy keys into the container.

## How It Works

1. **Automatic Mounting**: Your host `~/.ssh` directory is automatically mounted into the container
2. **Correct Permissions**: The post-create script sets proper permissions (700 for directory, 600 for private keys)
3. **SSH Config**: Automatically creates SSH configuration for Azure DevOps and GitHub
4. **Known Hosts**: Adds Azure DevOps to known hosts automatically

## Setup Steps

### 1. Ensure SSH Keys Exist on Host

On your **host machine** (not in container):

```bash
# Check if you have SSH keys
ls -la ~/.ssh/

# If no keys exist, create them
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"
```

### 2. Add Public Key to Azure DevOps

1. Copy your public key:
   ```bash
   cat ~/.ssh/id_rsa.pub
   ```

2. In Azure DevOps:
   - Go to User Settings → SSH public keys
   - Click "Add" and paste your public key
   - Give it a descriptive name

### 3. Test SSH Connection

In the dev container:

```bash
# Test Azure DevOps connection
ssh -T git@ssh.dev.azure.com

# Should return: "remote: Shell access is not supported."
```

### 4. Set Git Remote to SSH

```bash
# Change remote from HTTPS to SSH
git remote set-url origin git@ssh.dev.azure.com:v3/Wingmandevs/Wingman/Infrastructure

# Verify
git remote -v
```

## Troubleshooting

### Permission Issues
If you get permission errors:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/config
```

### SSH Agent Issues
If SSH agent forwarding isn't working:
```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add your key
ssh-add ~/.ssh/id_rsa

# Test
ssh-add -l
```

### Connection Issues
```bash
# Test with verbose output
ssh -vT git@ssh.dev.azure.com

# Check SSH config
cat ~/.ssh/config
```

## Security Benefits

✅ **Keys stay on host**: Private keys never copied to container
✅ **Automatic cleanup**: When container is deleted, no keys remain
✅ **Host control**: You control key lifecycle on your host machine
✅ **No key duplication**: Single source of truth for your SSH keys

## Alternative: HTTPS with PAT

If SSH is not working, you can use HTTPS with Personal Access Token:

```bash
# Set remote to HTTPS
git remote set-url origin https://Wingmandevs@dev.azure.com/Wingmandevs/Wingman/_git/Infrastructure

# Configure credential helper
git config --global credential.helper cache
```

Then use your Azure DevOps username and Personal Access Token when prompted.