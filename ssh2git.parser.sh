#!/usr/bin/env bash
set -euo pipefail

# Recursively find all .git directories
find . -type d -name ".git" | while read -r gitdir; do
    repo_dir=$(dirname "$gitdir")
    cd "$repo_dir" || continue

    echo "[*] Processing repo: $repo_dir"

    # List all remotes
    for remote in $(git remote); do
        url=$(git remote get-url "$remote")
        
        # Only convert GitHub HTTPS URLs
        if [[ "$url" == https://github.com/* ]]; then
            ssh_url=${url/https:\/\/github.com\//git@github.com:}
            git remote set-url "$remote" "$ssh_url"
            echo "[✔] Converted $remote in $repo_dir to SSH: $ssh_url"
        else
            echo "[i] Skipped $remote in $repo_dir (not a GitHub HTTPS URL)"
        fi
    done

    cd - >/dev/null
done

echo "[✅] Conversion complete!"
