#!/usr/bin/env bash
# =============================================================================
#  NEXUS-AI – Autonomous Cognitive Operating System (v4.0)
#  Singlefile CLI + Daemon + REST + File Agent
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

BASE_DIR="${HOME}/_/ai"
DB_FILE="${BASE_DIR}/.db/ai_memory.db"
FIFO="${BASE_DIR}/nexus.pipe"
API_PORT=7331

mkdir -p "$BASE_DIR/.db"
touch "$DB_FILE"

# ------------------------------------------------------------------
# Core logging
# ------------------------------------------------------------------
log() { echo "[NEXUS] $(date '+%H:%M:%S') $*" >&2; }

# ------------------------------------------------------------------
# Ollama call (slim-compatible)
# ------------------------------------------------------------------
ollama_call() {
  local prompt="$1"
  curl -s http://localhost:11434/api/generate \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"llama3\",\"prompt\":$(jq -Rs . <<<"$prompt")}" \
  | jq -r '.response'
}

# ------------------------------------------------------------------
# Memory API
# ------------------------------------------------------------------
sql() { sqlite3 "$DB_FILE" "$1"; }

init_db() {
sql <<'SQL'
CREATE TABLE IF NOT EXISTS memory (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 role TEXT,
 content TEXT,
 ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL
}

remember() {
  sql "INSERT INTO memory (role,content) VALUES ('user',$(jq -Rs . <<<"$1"));"
  sql "INSERT INTO memory (role,content) VALUES ('ai',$(jq -Rs . <<<"$2"));"
}

recall() {
  sql "SELECT content FROM memory ORDER BY id DESC LIMIT 10;"
}

# ------------------------------------------------------------------
# Natural Prompt → File System Agent
# ------------------------------------------------------------------
file_agent() {
  local instruction="$1"

  local plan
  plan=$(ollama_call "
You are a Linux automation agent.
Translate the following into bash commands.
Only output executable bash:

$instruction
")

  log "Executing:"
  echo "$plan"

  bash -c "$plan"
}

# ------------------------------------------------------------------
# REST API (pure bash + netcat)
# ------------------------------------------------------------------
api_server() {
  log "API server on http://localhost:$API_PORT"
  while true; do
    { 
      read line
      if [[ "$line" =~ GET\ /memory ]]; then
        body=$(recall | jq -R . | jq -s .)
      else
        body='{"status":"ok"}'
      fi
      printf "HTTP/1.1 200 OK\r\n"
      printf "Content-Type: application/json\r\n\r\n"
      echo "$body"
    } | nc -l -p "$API_PORT" -q 1
  done
}

# ------------------------------------------------------------------
# Daemon loop
# ------------------------------------------------------------------
daemon() {
  init_db
  [[ -p "$FIFO" ]] || mkfifo "$FIFO"

  log "NEXUS daemon online"
  api_server &

  while true; do
    read -r input < "$FIFO"
    [[ -z "$input" ]] && continue

    context=$(recall)
    response=$(ollama_call "
Context:
$context

User:
$input
")

    remember "$input" "$response"

    if [[ "$input" =~ ^(create|generate|build|write|delete|refactor) ]]; then
      file_agent "$input"
    fi

    echo "$response"
  done
}

# ------------------------------------------------------------------
# CLI entry
# ------------------------------------------------------------------
case "${1:-}" in
  daemon) daemon ;;
  api) api_server ;;
  remember) shift; remember "$*" "OK" ;;
  recall) recall ;;
  *)
    init_db
    resp=$(ollama_call "$*")
    remember "$*" "$resp"
    echo "$resp"
  ;;
esac

