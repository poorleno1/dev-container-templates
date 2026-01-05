# Dev Container Troubleshooting Guide

## 🚨 Common Issues and Solutions

### **1. "No space left on device" Error**

**Problem**: WSL/Docker Desktop runs out of disk space
```
tar: write error: No space left on device
```

**Solutions**:

#### **Quick Fix - Clean Docker**
```powershell
# Clean unused Docker resources
docker system prune -a --volumes -f

# Remove unused images
docker image prune -a -f

# Remove unused volumes
docker volume prune -f
```

#### **WSL Disk Management**
```powershell
# Check WSL disk usage
wsl -l -v
wsl --shutdown

# Compact WSL disk (run as Administrator)
Optimize-VHD -Path "$env:USERPROFILE\AppData\Local\Docker\wsl\data\ext4.vhdx" -Mode Full
```

#### **Docker Desktop Settings**
1. Open Docker Desktop
2. Go to **Settings** → **Resources** → **Advanced**
3. Increase **Disk image size** (default is often too small)
4. Set to at least **64GB** for dev containers
5. Click **Apply & Restart**

### **2. Legacy Features Error**

**Problem**: Using deprecated feature names
```
Legacy feature 'docker-outside-of-docker' not supported
```

**Solution**: Use updated feature names with full paths:
- ❌ `"azure-cli"` → ✅ `"ghcr.io/devcontainers/features/azure-cli:1"`
- ❌ `"terraform"` → ✅ `"ghcr.io/devcontainers/features/terraform:1"`
- ❌ `"powershell"` → ✅ `"ghcr.io/devcontainers/features/powershell:1"`

### **3. Container Build Fails**

**Problem**: Container fails to build or start

**Solutions**:

#### **Rebuild Container**
```
Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

#### **Clear All Docker Data**
```powershell
# WARNING: This removes ALL containers and images
docker system prune -a --volumes -f
docker builder prune -a -f
```

#### **Check Docker Desktop**
```powershell
# Verify Docker is running
docker version

# Check available resources
docker system df
```

### **4. VS Code Server Installation Fails**

**Problem**: Cannot install VS Code Server in container

**Solutions**:

#### **Increase Resources**
- Docker Desktop → Settings → Resources
- RAM: Minimum 8GB, Recommended 16GB
- CPUs: Minimum 4, Recommended 8

#### **Manual Server Installation**
```bash
# Inside container
curl -sSL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" -o vscode_cli.tar.gz
tar -xf vscode_cli.tar.gz
```

### **5. Feature Installation Timeout**

**Problem**: Features take too long to install

**Solutions**:

#### **Simplify Configuration**
Use minimal features first, add more later:
```json
{
    "features": {
        "ghcr.io/devcontainers/features/azure-cli:1": {},
        "ghcr.io/devcontainers/features/terraform:1": {"version": "1.7.0"}
    }
}
```

#### **Use Pre-built Images**
Switch to images with tools pre-installed:
```json
{
    "image": "mcr.microsoft.com/devcontainers/python:3.11-bullseye"
}
```

## 🔧 **Prevention Steps**

### **Regular Maintenance**
```powershell
# Weekly cleanup routine
docker system prune -f
wsl --shutdown
# Restart Docker Desktop
```

### **Resource Monitoring**
```powershell
# Check disk usage
docker system df
wsl --list --verbose

# Monitor container resource usage
docker stats
```

### **Optimal Settings**
- Docker Desktop: 64GB+ disk, 8GB+ RAM, 4+ CPUs
- WSL2: Enable in Docker Desktop settings
- Network: Stable internet for downloads

## 🆘 **Emergency Recovery**

If all else fails:

1. **Complete Reset**:
   ```powershell
   # Stop all containers
   docker kill $(docker ps -q)
   docker rm $(docker ps -aq)
   
   # Remove all images and volumes
   docker system prune -a --volumes -f
   
   # Reset WSL
   wsl --shutdown
   wsl --unregister docker-desktop-data
   ```

2. **Reinstall Docker Desktop**
3. **Start with minimal dev container configuration**

## 📞 **Get Help**

- Dev Containers documentation: https://code.visualstudio.com/docs/devcontainers
- Docker Desktop issues: https://docs.docker.com/desktop/troubleshoot/
- WSL troubleshooting: https://docs.microsoft.com/en-us/windows/wsl/troubleshooting