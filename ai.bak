#!/usr/bin/env bash
# Minimal One-Shot AI CLI (Proot / Termux)
set -euo pipefail
IFS=$'\n\t'

AI_HOME="${HOME}/.local_ai"
DB="$AI_HOME/core.db"
SANDBOX="$AI_HOME/sandbox"
mkdir -p "$AI_HOME" "$SANDBOX" "$HOME/logs"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# --- Dependencies via apt only ---
apt update && apt install -y python3-full curl wget git unzip nodejs build-essential nano busybox

# --- Ollama CLI ---
if ! command -v ollama &>/dev/null; then
    log "Downloading Ollama CLI..."
    curl -L -o /tmp/ollama.tar.gz https://ollama-releases.s3.amazonaws.com/ollama-cli-latest-linux.tar.gz
    tar -xzf /tmp/ollama.tar.gz -C /tmp
    chmod +x /tmp/ollama
    mv /tmp/ollama /usr/local/bin/
    log "Ollama installed."
fi

# --- Initialize DB if missing ---
if [ ! -f "$DB" ]; then
    log "Initializing DB..."
    sqlite3 "$DB" "CREATE TABLE mindflow(id INTEGER PRIMARY KEY, session_id TEXT, model_name TEXT, output TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);"
    sqlite3 "$DB" "CREATE TABLE cache(prompt_hash TEXT PRIMARY KEY, final_answer TEXT);"
fi

# --- Webserver (optional) ---
if ! pgrep -f "busybox httpd" > /dev/null; then
    busybox httpd -f -p 80 -h "$SANDBOX" &
fi

# --- Prompt Input ---
PROMPT="${*:-}"
if [ -z "$PROMPT" ]; then
    read -rp "Enter your prompt: " PROMPT
fi

# --- Fake/Placeholder Model Output ---
MODEL="default-model"
OUTPUT="Simulated AI answer for: $PROMPT"

# --- Language Filter: English/German Only ---
OUTPUT=$(echo "$OUTPUT" | sed 's/[^A-Za-z0-9äöüßÄÖÜ,.!?;:()"\x27 \t\n-]//g')

# --- Save to DB ---
SESSION=$(uuidgen)
sqlite3 "$DB" "INSERT INTO mindflow(session_id, model_name, output) VALUES('$SESSION','$MODEL','$(echo "$OUTPUT" | sed "s/'/''/g")');"

# --- Cache ---
HASH=$(echo -n "$PROMPT" | sha256sum | awk '{print $1}')
sqlite3 "$DB" "INSERT OR REPLACE INTO cache(prompt_hash, final_answer) VALUES('$HASH','$(echo "$OUTPUT" | sed "s/'/''/g")');"

# --- Output ---
echo "$OUTPUT"
log "✅ AI CLI finished. Language filtered: English/German only."