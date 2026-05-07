# SSH Keys Setup for Dev Container

This dev container mounts your host `.ssh` directory into the container path `/home/vscode/.ssh`.

No key copy step is required.

## How It Works

1. **Automatic Mounting**: host `.ssh` is bind-mounted into container `.ssh`
2. **Permission Fixup**: `post-start.sh` enforces `700` on `.ssh`, `600` on private keys, and `644` on public keys
3. **No automatic SSH config generation**: add `~/.ssh/config` entries yourself if needed
4. **No automatic known-host bootstrap**: run `ssh` once or use `ssh-keyscan` as needed

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

If your host key requires an agent and auth fails:

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

# Check SSH config (if present)
test -f ~/.ssh/config && cat ~/.ssh/config
```

## Security Benefits

✅ **Keys stay on host**: Private keys are not copied by scripts
✅ **Host control**: You manage key lifecycle in one place
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
