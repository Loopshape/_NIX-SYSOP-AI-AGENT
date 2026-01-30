#!/usr/bin/env bash
# =============================================================================
#  NEXUS-AI Mobile – Autonomous Cognitive Operating System (v5.0-mobile)
#  Termux Edition (2π/5 agents)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

BASE_DIR="${HOME}/ai"
DB_FILE="${BASE_DIR}/.db/ai_memory.db"
FIFO="${BASE_DIR}/nexus.pipe"
API_PORT=7332
PC_NEXUS_URL="http://192.168.1.XX:7331" # To be configured by user

# Mobile Agent Pool (2π/5)
AGENTS=("core" "sign" "loop" "code" "sense")

mkdir -p "$BASE_DIR/.db"
touch "$DB_FILE"

# ------------------------------------------------------------------
# SENSE Agent (Mobile Sensors)
# ------------------------------------------------------------------
get_sensors() {
  local sense_data="{}"
  if command -v termux-battery-status >/dev/null; then
      sense_data=$(termux-battery-status)
  fi
  # Add more termux sensor calls here
  echo "$sense_data"
}

# ------------------------------------------------------------------
# Core Logic (Shared with PC)
# ------------------------------------------------------------------
log() { echo "[NEXUS-M] $(date '+%H:%M:%S') $*" >&2; }

init_db() {
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS memory (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 role TEXT,
 content TEXT,
 ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL
}

sql() {
  init_db
  sqlite3 "$DB_FILE" "${1:-}"
}

remember() {
  local role="${1:-user}"
  local content="${2:-}"
  sql "INSERT INTO memory (role,content) VALUES ($(jq -Rs . <<<"$role"),$(jq -Rs . <<<"$content"));"
}

ollama_call() {
  local prompt="${1:-}"
  local model="${2:-llama3.2:3b}" # Lighter model for mobile
  
  log "Calling $model..."
  curl -s http://localhost:11434/api/generate \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$model\",\"prompt\":$(jq -Rs . <<<"$prompt"),\"stream\":false}" \
    | jq -r '.response'
}

consensus() {
  local user_prompt="${1:-}"
  local sensors
  sensors=$(get_sensors)
  
  log "Starting mobile consensus..."
  
  local final_response=""
  for agent in "${AGENTS[@]}"; do
      local agent_prompt="[AGENT:$agent] [SENSORS:$sensors] [PROMPT:$user_prompt]"
      local result
      if [[ "$agent" == "sense" ]]; then
          result="Sensors active: $sensors"
      else
          result=$(ollama_call "$agent_prompt" "$agent")
      fi
      
      if [[ "$agent" == "core" ]]; then
          final_response="$result"
      fi
  done
  
  remember "user" "$user_prompt"
  remember "ai" "$final_response"
  echo "$final_response"
}

# ------------------------------------------------------------------
# Remote Sync (Forwarding to PC)
# ------------------------------------------------------------------
sync_to_pc() {
    local prompt="${1:-}"
    log "Forwarding to PC NEXUS..."
    curl -s -X POST "$PC_NEXUS_URL/prompt" -d "{\"prompt\":\"$prompt\"}"
}

# CLI entry
case "${1:-}" in
  daemon)
    init_db
    [[ -p "$FIFO" ]] || mkfifo "$FIFO"
    while true; do
      read -r input < "$FIFO"
      consensus "$input"
    done
    ;;
  sense) get_sensors ;; 
  *) consensus "${*:-hello}" ;; 
esac
