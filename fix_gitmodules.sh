#!/usr/bin/env bash
# Fully automated fix for .gitmodules symlink history issue
# WSL1 / Debian ready

set -euo pipefail

echo "[1/6] Backing up current branch..."
git branch -f backup-main

echo "[2/6] Removing .gitmodules symlink from all commits..."
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .gitmodules' \
  --prune-empty --tag-name-filter cat -- --all

echo "[3/6] Cleaning up old refs and garbage..."
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "[4/6] Recreating proper .gitmodules file..."
cat > .gitmodules <<EOL
[submodule "some-module"]
    path = some-module
    url = git@github.com:Loopshape/some-module.git
EOL

git add .gitmodules
git commit -m "Add proper .gitmodules file"

echo "[5/6] Ready to force push cleaned repo"
echo "This will rewrite GitHub history. Make sure you really want to do this."
read -p "Proceed with git push -f origin main? (y/N): " yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    git push -f origin main
    echo "[6/6] Push complete. History fixed!"
else
    echo "Aborted. You can manually push later with 'git push -f origin main'"
fi

