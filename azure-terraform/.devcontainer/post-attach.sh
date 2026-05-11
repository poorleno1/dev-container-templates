#!/bin/bash
set -euo pipefail

line='export PATH="$HOME/.tfenv/bin:$PATH"'
ps_line='$env:PATH = "$HOME/.tfenv/bin:$env:PATH"'
ps_profile="$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
bash_profile="$HOME/.bashrc"
zsh_profile="$HOME/.zshrc"

touch "$bash_profile" "$zsh_profile"
grep -qxF "$line" "$bash_profile" || echo "$line" >> "$bash_profile"
grep -qxF "$line" "$zsh_profile" || echo "$line" >> "$zsh_profile"

mkdir -p "$(dirname "$ps_profile")"
touch "$ps_profile"
grep -qxF "$ps_line" "$ps_profile" || printf '\n%s\n' "$ps_line" >> "$ps_profile"
