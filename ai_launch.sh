#!/usr/bin/env bash
# ai_launch.sh - Launch & maintain Local AI CLI

set -euo pipefail
IFS=$'\n\t'

AI_HOME="${HOME}/.local_ai"
DB="$AI_HOME/core.db"
LOG="$AI_HOME/launch.log"

mkdir -p "$AI_HOME/modules"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

# -----------------------------
# Load environment
# -----------------------------
if [ -f "$AI_HOME/.env.local" ]; then
    log "Loading environment from $AI_HOME/.env.local"
    set -a
    source "$AI_HOME/.env.local"
    set +a
fi

# -----------------------------
# Python venv
# -----------------------------
[ -f "$HOME/.sysop_ai_env/bin/activate" ] && source "$HOME/.sysop_ai_env/bin/activate"

# -----------------------------
# DB INIT
# -----------------------------
sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS modules(
    name TEXT PRIMARY KEY,
    code BLOB,
    hmac TEXT,
    last_update DATETIME DEFAULT CURRENT_TIMESTAMP
);"
sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS cache(
    prompt_hash TEXT PRIMARY KEY,
    final_answer TEXT
);"

# -----------------------------
# Populate modules from local files
# -----------------------------
populate_modules() {
    log "Populating modules into DB..."
    for f in "$AI_HOME"/modules/*.sh; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f" .sh)
        code=$(<"$f")
        hmac=$(python3 -c "import hmac, hashlib; print(hmac.new(b'$HMAC_SECRET', b'''$code''', hashlib.sha256).hexdigest())")
        sqlite3 "$DB" "INSERT OR REPLACE INTO modules(name, code, hmac, last_update) VALUES('$name', quote('$code'), '$hmac', datetime('now'));"
        log "Module '$name' added/updated in DB"
    done
}

# -----------------------------
# Start Ollama if not running
# -----------------------------
if ! pgrep -x ollama >/dev/null; then
    log "Starting Ollama server..."
    nohup ollama serve > "$AI_HOME/ollama.log" 2>&1 &
    sleep 2
fi

# -----------------------------
# Self-Heal Script
# -----------------------------
SELF_HEAL="$AI_HOME/self_heal.sh"
cat > "$SELF_HEAL" <<'SH'
#!/usr/bin/env bash
# Self-Healing AI CLI

AI_BIN="$HOME/.bin/ai"
if [ -f "$AI_BIN" ]; then
    chmod +x "$AI_BIN"
fi
SH
chmod +x "$SELF_HEAL"

log "✅ AI Launch Complete!"
log "Use: ai 'your prompt' | ai --populate | ai --run <module>"