#!/usr/bin/env bash
# WSL1/Debian: Ultra-safe GitHub symlink fix
# Scans all history, removes GitHub-rejected symlinks, recreates real files, preserves local-only symlinks

set -euo pipefail

echo "[1/7] Backing up current branch..."
git branch -f backup-main

echo "[2/7] Scanning all Git-tracked symlinks..."
# Find all symlinks tracked in Git history
symlinks=$(git ls-tree -r -l --full-tree HEAD | awk '$2=="120000"{print $4}')

if [ -z "$symlinks" ]; then
    echo "No Git-tracked symlinks detected. Nothing to fix."
else
    echo "[3/7] Removing problematic symlinks from history..."
    for link in $symlinks; do
        echo "Removing $link from history..."
        git filter-branch --force --index-filter \
            "git rm --cached --ignore-unmatch '$link'" \
            --prune-empty --tag-name-filter cat -- --all
    done

    echo "[4/7] Cleaning up old refs and optimizing Git..."
    rm -rf .git/refs/original/
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
fi

echo "[5/7] Recreating necessary symlinks as real files..."
for link in $symlinks; do
    target=$(readlink "$link" || true)
    # Only recreate if target exists and is not ignored (like .env or local config)
    if [ -f "$target" ] && [[ ! "$link" =~ ^\.env ]]; then
        echo "Converting $link -> $target"
        rm -f "$link"
        cp "$target" "$link"
        git add "$link"
    else
        echo "Skipping $link (either missing target or ignored)"
    fi
done

if [ -n "$symlinks" ]; then
    git commit -m "Replace GitHub-rejected symlinks with real files"
fi

echo "[6/7] Force pushing cleaned repo to GitHub..."
git push -f origin main

echo "[7/7] ✅ Ultra-safe symlink fix complete. Local-only symlinks preserved!"

