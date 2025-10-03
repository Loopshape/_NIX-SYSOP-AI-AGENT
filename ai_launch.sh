#!/usr/bin/env bash
# ai_launch.sh – Proot-safe AI bootstrap
set -euo pipefail
IFS=$'\n\t'

AI_HOME="$HOME/.local_ai"
AI_DB="$AI_HOME/core.db"
LOG_DIR="$HOME/logs"
DISTRO="debian"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

mkdir -p "$AI_HOME" "$AI_HOME/modules" "$LOG_DIR"

# 1. Load env vars
if [ -f "$HOME/_NIX-SYSOP-AI-AGENT-by-Aris-Arjuna-Noorsanto/.env.local" ]; then
    log "🔑 Loading environment variables..."
    set -a
    source "$HOME/_NIX-SYSOP-AI-AGENT-by-Aris-Arjuna-Noorsanto/.env.local"
    set +a
fi

# 2. Check distro (only outer proot-distro!)
if ! proot-distro list | grep -q "$DISTRO"; then
    log "⚠ $DISTRO not installed, installing now..."
    proot-distro install "$DISTRO"
else
    log "✅ $DISTRO is already installed."
fi

# 3. Update distro (without nesting proot-distro)
log "🔄 Updating $DISTRO packages..."
proot-distro login "$DISTRO" -- bash -lc "
    apt-get update -y &&
    apt-get install -y python3-full curl git nodejs build-essential wget unzip
"

# 4. Initialize database if missing
if [ ! -f "$AI_DB" ]; then
    log "🗄 Initializing AI core database..."
    sqlite3 "$AI_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS mindflow(
    id INTEGER PRIMARY KEY,
    session_id TEXT,
    loop_id INTEGER,
    model_name TEXT,
    output TEXT,
    rank INTEGER,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS task_logs(
    id INTEGER PRIMARY KEY,
    tool_used TEXT,
    args TEXT,
    output_summary TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS cache(
    prompt_hash TEXT PRIMARY KEY,
    final_answer TEXT
);
SQL
fi

# 5. Start Ollama if not running
if ! pgrep -x ollama >/dev/null 2>&1; then
    log "🚀 Starting Ollama service..."
    nohup ollama serve > "$LOG_DIR/ollama_server.log" 2>&1 &
else
    log "✅ Ollama already running."
fi

# 6. Lightweight HTTP server for sandbox
if ! pgrep -f "busybox httpd" >/dev/null; then
    log "🌐 Starting BusyBox HTTP server on :80..."
    busybox httpd -f -p 80 -h "$AI_HOME/sandbox" &
fi

# 7. Final info
log "✅ AI environment ready!"
log "Run AI CLI with: ai 'your prompt'"
