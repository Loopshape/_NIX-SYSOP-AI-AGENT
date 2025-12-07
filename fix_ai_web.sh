#!/usr/bin/env bash
# fix_ai_web.sh — Make AI Crew web folder WSL-ready

set -euo pipefail

AI_REPO="$HOME/_/ai_orchestrator"
WEB_DIR="$HOME/_/web"
APACHE_LINK="/var/www/html/ai"

echo "=== Fixing AI Crew web folder ==="

# 1️⃣ Remove old link
sudo rm -rf "$APACHE_LINK"

# 2️⃣ Symlink web folder
sudo ln -s "$WEB_DIR" "$APACHE_LINK"
echo "Symlink created: $APACHE_LINK → $WEB_DIR"

# 3️⃣ Symlink PHP entrypoints into web
for f in orchestrator.php run.php fetch.php outputs.php; do
    if [ -f "$AI_REPO/$f" ] && [ ! -L "$WEB_DIR/$f" ]; then
        ln -s "$AI_REPO/$f" "$WEB_DIR/$f"
        echo "Linked $f into web folder"
    fi
done

# 4️⃣ Fix folder traversal for Apache in WSL
chmod 751 "$HOME"
chmod 751 "$HOME/_"
chmod -R 750 "$AI_REPO"

echo "=== Web folder fixed! ==="
echo "Test: curl -X POST -d 'prompt=test' http://localhost:8080/ai/orchestrator.php"

