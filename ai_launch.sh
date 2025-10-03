#!/usr/bin/env bash
# ~/bin/ai_launch.sh
# Launch Ollama server + ensure environment + single CLI integration

set -euo pipefail
IFS=$'\n\t'

AI_HOME="$HOME/.local_ai"
AI_BIN="$HOME/.bin/ai"
LOGS="$HOME/logs"

mkdir -p "$LOGS"

# -----------------------------
# Load environment
# -----------------------------
[ -f "$AI_HOME/.env.local" ] && source "$AI_HOME/.env.local"

# -----------------------------
# Start Ollama server (single instance)
# -----------------------------
if ! pgrep -x ollama >/dev/null 2>&1; then
    echo "[INFO] Starting Ollama server..."
    nohup ollama serve >"$LOGS/ollama_server.log" 2>&1 &
else
    echo "[INFO] Ollama server already running."
fi

# -----------------------------
# Ensure dependencies installed (only mandatory)
# -----------------------------
if ! command -v python3 >/dev/null 2>&1; then
    echo "[INFO] Installing python3-full..."
    sudo apt update && sudo apt install -y python3-full
fi

for dep in sqlite3 git curl wget nodejs build-essential; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "[INFO] Installing $dep..."
        sudo apt install -y "$dep"
    fi
done

# -----------------------------
# Self-healing modules & DB
# -----------------------------
echo "[INFO] Ensuring AI DB & modules..."
python3 "$AI_BIN" "__self_heal__" >/dev/null 2>&1 || true

# -----------------------------
# Launch CLI
# -----------------------------
if [[ $# -gt 0 ]]; then
    "$AI_BIN" "$*"
else
    echo "Usage: $0 '<your query>'"
fi
