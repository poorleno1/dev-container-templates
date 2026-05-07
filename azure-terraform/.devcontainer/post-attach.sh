#!/bin/bash
set -euo pipefail

line='export PATH="$HOME/.tfenv/bin:$PATH"'

grep -qxF "$line" ~/.bashrc || echo "$line" >> ~/.bashrc
grep -qxF "$line" ~/.zshrc || echo "$line" >> ~/.zshrc
