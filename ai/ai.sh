#!/usr/bin/env bash
# =============================================================================
#  NEXUS-AI – Autonomous Cognitive Operating System (v5.0)
#  Singlefile CLI + Daemon + REST + Multi-Agent Consensus
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

BASE_DIR="${HOME}/_/ai"
DB_FILE="${BASE_DIR}/.db/ai_memory.db"
FIFO="${BASE_DIR}/nexus.pipe"
API_PORT=7331

# Desktop Agent Pool (2π/Agentpool)
AGENTS=("glm-4.7:cloud")

mkdir -p "$BASE_DIR/.db"
touch "$DB_FILE"

# ------------------------------------------------------------------
# Core logging
# ------------------------------------------------------------------
log() { echo "[NEXUS] $(date '+%H:%M:%S') "$*"" >&2; }

# ------------------------------------------------------------------
# Memory API (Self-healing)
# ------------------------------------------------------------------
init_db() {
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS memory (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 user TEXT,
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
  local user="${USER:-nexus_user}"
  
  # Simple SQL escaping: replace ' with ''
  sql "INSERT INTO memory (user,role,content) VALUES ('${user//\'/''}','${role//\'/''}','${content//\'/''}');"
}

recall() {
  local limit="${1:-10}"
  sql "SELECT json_object('id', id, 'user', user, 'role', role, 'content', content, 'ts', ts) FROM memory ORDER BY id DESC LIMIT $limit;"
}

# ------------------------------------------------------------------
# Ollama call (slim-compatible)
# ------------------------------------------------------------------
ollama_call() {
  local prompt="${1:-}"
  local model="${2:-glm-4.7:cloud}"

  log "Calling $model..."
  local response
  response=$(curl -s http://localhost:11434/api/generate \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$model\",\"prompt\":$(jq -Rs . <<<"$prompt"),\"stream\":false}" \
    | jq -r '.response')

  echo "$response"
}

# ------------------------------------------------------------------
# Consensus Engine (8 Agents)
# ------------------------------------------------------------------
consensus() {
  local user_prompt="${1:-}"
  local context
  context=$(recall 5)
  
  log "Starting consensus for: $user_prompt"
  
  local final_response=""
  local agent_results=""
  
  # Sequential execution to simulate the "rotational" consensus
  for agent in "${AGENTS[@]}"; do
      local agent_prompt="[AGENT:$agent] [CONTEXT:$context] [PROMPT:$user_prompt]"
      local result
      result=$(ollama_call "$agent_prompt" "$agent")
      agent_results+="\n[$agent]: $result"
      
      # CORE/CODE/LOOP have higher influence on the final state
      if [[ "$agent" == "core" || "$agent" == "code" ]]; then
          final_response="$result"
      fi
  done
  
  remember "user" "$user_prompt"
  remember "ai" "$final_response"
  
  echo -e "--- CONSENSUS REACHED ---\n$final_response\n\n--- AGENT DETAILS ---$agent_results"
}

# ------------------------------------------------------------------
# Natural Prompt → File System Agent
# ------------------------------------------------------------------
file_agent() {
  local instruction="${1:-}"

  local plan
  plan=$(ollama_call "
# You are a Linux automation agent.
# Translate the following into bash commands.
# Only output executable bash:

$instruction
" "code")

  log "Executing File Agent Plan..."
  echo "$plan" | bash
}

# ------------------------------------------------------------------
# REST API (pure bash + netcat)
# ------------------------------------------------------------------
api_server() {
  log "API server on http://localhost:$API_PORT"
  while true; do
    # This is a more advanced NC server loop that can read the request
    # We use a temp file to capture the request
    local tmp_req
    tmp_req=$(mktemp)
    
    {
      # Read request into temp file (stop after headers or a short timeout)
      # This is tricky in pure bash, so we'll use a simplified version:
      # We'll just read the first line and then everything else we can.
      if ! read -r first_line; then
          rm -f "$tmp_req"
          return
      fi
      echo "$first_line" > "$tmp_req"
      
      local body='{"status":"ok"}'
      local response_code="200 OK"
      
      if [[ "$first_line" =~ GET\ /memory ]]; then
        body=$(recall 20 | jq -s .)
      elif [[ "$first_line" =~ POST\ /remember ]]; then
        # In a real NC server, parsing POST body is hard. 
        # We'll assume the next lines or just log it.
        remember "remote" "Mobile announcement received"
        body='{"status":"remembered"}'
      elif [[ "$first_line" =~ POST\ /prompt ]]; then
        # Trigger consensus from remote
        echo "Remote prompt received" > "$FIFO" &
        body='{"status":"accepted"}'
      else
        body='{"error":"not_found"}'
        response_code="404 Not Found"
      fi
      
      printf "HTTP/1.1 %s\r\n" "$response_code"
      printf "Content-Type: application/json\r\n"
      printf "Content-Length: %d\r\n" "${#body}"
      printf "Connection: close\r\n\r\n"
      echo "$body"
      
      rm -f "$tmp_req"
    } | nc -l -p "$API_PORT" -q 1 || log "NC restart"
  done
}
# ------------------------------------------------------------------
# Daemon loop
# ------------------------------------------------------------------
daemon() {
  init_db
  [[ -p "$FIFO" ]] || mkfifo "$FIFO"

  log "NEXUS daemon online (agents active)"
  api_server &

  while true; do
    if read -r input < "$FIFO"; then
        [[ -z "$input" ]] && continue

        log "Processing FIFO input: $input"
        local response
        response=$(consensus "$input")

        if [[ "$input" =~ ^(create|generate|build|write|delete|refactor) ]]; then
          file_agent "$input"
        fi
        
        log "Response: $response"
    fi
  done
}

# ------------------------------------------------------------------
# CLI entry
# ------------------------------------------------------------------
case "${1:-}" in
  daemon) daemon ;; 
  api) api_server ;; 
  remember) shift; remember "user" "$*" ;; 
  recall) shift; recall "${1:-10}" ;; 
  consensus) shift; consensus "$*" ;; 
  *) 
    if [[ -n "${1:-}" ]]; then
        consensus "$*"
    else
        echo "NEXUS-AI v5.0"
        echo "Usage: $0 [daemon|api|remember|recall|consensus|prompt]"
    fi
  ;; 
esac
