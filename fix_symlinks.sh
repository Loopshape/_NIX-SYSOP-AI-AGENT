#!/usr/bin/env bash
# WSL1/Debian: Fully automated fix for .gitmodules symlink history issue
# Backup, remove from history, recreate file, force push

set -euo pipefail

echo "[1/5] Backing up current branch..."
git branch -f backup-main

echo "[2/5] Rewriting history to remove .gitmodules symlink..."
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .gitmodules' \
  --prune-empty --tag-name-filter cat -- --all

echo "[3/5] Cleaning up old refs and optimizing repo..."
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "[4/5] Recreating proper .gitmodules file..."
cat > .gitmodules <<EOL
[submodule "some-module"]
    path = some-module
    url = git@github.com:Loopshape/some-module.git
EOL

git add .gitmodules
git commit -m "Add proper .gitmodules file"

echo "[5/5] Force pushing cleaned history to GitHub..."
git push -f origin main

echo "✅ Done! .gitmodules symlink issue fixed and repo pushed."

