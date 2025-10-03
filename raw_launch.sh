#!/usr/bin/env bash
# ai_launch.sh - Bulletproof launcher for Local AI (Termux + Proot)
set -euo pipefail; IFS=$'\n\t'

# --- Configuration ---
AI_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/local_ai"
DB="$AI_HOME/core.db"
SANDBOX="$AI_HOME/sandbox" 
LOGS="$HOME/logs/local_ai"
OLLAMA_MODEL="2244:latest"

# --- SQL Injection Protection ---
sqlite3_escape() {
    printf "%s" "$1" | sed "s/'/''/g"
}

# --- Improved Ollama Health Check ---
is_ollama_ready() {
    if pgrep -x ollama >/dev/null 2>&1; then
        curl -s --connect-timeout 5 http://localhost:11434/api/tags >/dev/null 2>&1
        return $?
    fi
    return 1
}

# In the module initialization section:
for mod in blockchain nostr lightning termux proot url-parser snippet-assembler; do
    if ! sqlite3 "$DB" "SELECT 1 FROM modules WHERE name='$mod';" | grep -q '1'; then
        log "Creating placeholder module: $mod"
        CODE_PLACEHOLDER="echo \"Module $mod placeholder: Not yet implemented\""
        ESCAPED_CODE=$(sqlite3_escape "$CODE_PLACEHOLDER")
        sqlite3 "$DB" "INSERT INTO modules(name, code) VALUES('$mod', '$ESCAPED_CODE')"
    fi
done
