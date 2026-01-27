#!/usr/bin/env bash
# install_loop.sh — WSL-ready AI Crew setup under user 'loop'

set -euo pipefail

# Paths
AI_REPO="$HOME/_/ai_orchestrator"
WEB_REPO="$HOME/_/web"
RESULTS_DIR="$AI_REPO/results"
LOGS_DIR="$AI_REPO/logs"
CREW_SCRIPT="$AI_REPO/crew/ai_orchestrator.py"
APACHE_LINK="/var/www/html/ai"
OLLAMA_PATH="/home/linuxbrew/.linuxbrew/bin/ollama"

echo "=== Setting up AI Crew under user 'loop' ==="

# 1️⃣ Ensure folders exist
mkdir -p "$RESULTS_DIR" "$LOGS_DIR"
chmod 770 "$RESULTS_DIR" "$LOGS_DIR"

# 2️⃣ Fix ownership (loop owns everything)
sudo chown -R loop:loop "$HOME/_"

# 3️⃣ Ensure Python orchestrator is executable
chmod 750 "$CREW_SCRIPT"

# 4️⃣ Inject absolute Ollama path in Python orchestrator
if ! grep -q "^OLLAMA" "$CREW_SCRIPT"; then
    sed -i "1iOLLAMA=\"$OLLAMA_PATH\"  # absolute path injected by install_loop.sh" "$CREW_SCRIPT"
else
    sed -i "s|^OLLAMA=.*|OLLAMA=\"$OLLAMA_PATH\"|" "$CREW_SCRIPT"
fi

# 5️⃣ Symlink web folder to Apache doc root
if [ -L "$APACHE_LINK" ] || [ -e "$APACHE_LINK" ]; then
    sudo rm -rf "$APACHE_LINK"
fi
sudo ln -s "$WEB_REPO" "$APACHE_LINK"
echo "Symlink created: $APACHE_LINK → $WEB_REPO"

# 6️⃣ Ensure parent folders are traversable by Apache in WSL
chmod 751 "$HOME/_"
chmod 751 "$HOME"

# ✅ Done
echo "=== Installation complete! ==="
echo "Test AI Crew:"
echo "curl -X POST -d 'prompt=test' http://localhost:8080/ai/orchestrator.php"
echo "Results will be in $RESULTS_DIR/final.html"

