#!/usr/bin/env bash

# =============================================================================
#  NEXUS-AI – Autonomous Cognitive Operating System (v5.1)
#  Singlefile CLI + Daemon + REST (Python helper) + Multi-Agent Consensus
#  - Safer file execution (dry-run default)
#  - Robust Ollama bridge (retries + error codes)
#  - Structured logging
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# -------------------------
# CONFIG
# -------------------------
BASE_DIR="${HOME}/_/ai"
DB_DIR="${BASE_DIR}/.db"
DB_FILE="${DB_DIR}/ai_memory.db"
FIFO="${BASE_DIR}/nexus.pipe"
API_PORT="${API_PORT:-7331}"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
# Map of agent label -> model (adjust to your local names)
declare -A AGENT_MODELS=(
  [CUBE]="gemma3:1b"
  [CORE]="deepseek-v3.1:671b-cloud"
  [LOOP]="loop:latest"
  [LINE]="line:latest"
  [WAVE]="qwen3-vl:2b"
  [COIN]="stable-code:latest"
  [CODE]="phi:2.7b"
  [WORK]="deepseek-v3.1:671b-cloud"
)
# Default agent order (quorum semantics may be added)
AGENT_ORDER=(CUBE CORE LOOP LINE WAVE COIN CODE WORK)

LOG_FILE="${DB_DIR}/ai_system.log"
STRUCTURED_LOG="${DB_DIR}/ai_system.jsonl"

# Operational flags
ALLOW_EXECUTE="${ALLOW_EXECUTE:-0}"   # must be set to 1 explicitly to execute model-produced shell code
DEFAULT_TIMEOUT=30                    # seconds for external calls
OLLAMA_RETRIES=2
MAX_CONTENT_LEN=8192                  # max chars to store in memory

mkdir -p "$DB_DIR"
touch "$DB_FILE" "$LOG_FILE" "$STRUCTURED_LOG"

# -------------------------
# Logging helpers
# -------------------------
log() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts=$(date --iso-8601=seconds)
  printf '%s %s %s\n' "$ts" "$level" "$msg" | tee -a "$LOG_FILE" >&2
  # structured line
  printf '{"ts":"%s","level":"%s","msg":"%s"}\n' "$ts" "$level" "$(echo "$msg" | sed 's/"/\\"/g')" >> "$STRUCTURED_LOG"
}

# -------------------------
# DB / Memory helpers
# -------------------------
init_db() {
  sqlite3 "$DB_FILE" <<'SQL'
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS memory (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 user TEXT,
 role TEXT,
 content TEXT,
 ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_memory_ts ON memory (ts);
SQL
}

sanitize_sql_value() {
  # remove NULs, limit length, basic quote escape
  local v="$1"
  v="${v//$'\000'/}"               # remove NUL
  v="$(echo "$v" | sed 's/\r//g')" # strip CR
  v="${v//\'/''}"                  # single-quote escape for sqlite
  if (( ${#v} > MAX_CONTENT_LEN )); then
    v="${v:0:MAX_CONTENT_LEN}"
  fi
  echo "$v"
}

sql_exec() {
  init_db
  sqlite3 "$DB_FILE" "$1"
}

remember() {
  local role="${1:-user}"
  local content="${2:-}"
  local user="${USER:-nexus_user}"

  local safe_user safe_role safe_content
  safe_user=$(sanitize_sql_value "$user")
  safe_role=$(sanitize_sql_value "$role")
  safe_content=$(sanitize_sql_value "$content")

  sql_exec "INSERT INTO memory (user,role,content) VALUES ('$safe_user','$safe_role','$safe_content');"
  log "INFO" "remembered role=$role user=$user len=${#safe_content}"
}

recall() {
  local limit="${1:-10}"
  init_db
  sqlite3 -json "$DB_FILE" "SELECT id,user,role,content,ts FROM memory ORDER BY id DESC LIMIT $limit;"
}

# -------------------------
# Ollama API bridge (robust)
# -------------------------
ollama_call() {
  # usage: ollama_call "<prompt>" "<model>" "<timeout_seconds>"
  local prompt="${1:-}"
  local model="${2:-${AGENT_MODELS[CODE]:-llama3}}"
  local timeout="${3:-$DEFAULT_TIMEOUT}"

  log "DEBUG" "ollama_call model=$model timeout=${timeout}s prompt_len=${#prompt}"

  # Prepare payload safely (use jq to escape prompt)
  local payload
  payload=$(jq -n --arg m "$model" --arg p "$prompt" '{model:$m,prompt:$p,stream:false}')

  local attempt=0
  local response="" err=""
  while (( attempt <= OLLAMA_RETRIES )); do
    attempt=$((attempt+1))
    # use curl with --max-time and fail gracefully
    response=$(curl -sS --max-time "$timeout" -H "Content-Type: application/json" -d "$payload" "${OLLAMA_HOST}/api/generate" 2>&1) || err="$response"
    # try to extract common fields
    if [[ -n "$response" ]]; then
      # Ollama slim usually returns {"response":"..."}
      local extracted
      extracted=$(echo "$response" | jq -r '.response // .[0].response // empty' 2>/dev/null || true)
      if [[ -n "$extracted" ]]; then
        printf '%s' "$extracted"
        return 0
      fi
      # If response is non-empty but no .response, return entire payload (fallback)
      printf '%s' "$response"
      return 0
    fi
    log "WARN" "Ollama call attempt $attempt failed: ${err:0:200}"
    sleep $((attempt * 1))
  done

  # On persistent failure return a prefixed error so callers can detect fallback
  log "ERROR" "Ollama unreachable after ${OLLAMA_RETRIES} attempts"
  printf '__OLLAMA_ERROR__:%s' "${err:-timeout}"
  return 2
}

# -------------------------
# Consensus engine (sequential with timeout)
# -------------------------
consensus() {
  local user_prompt="${1:-}"
  local recall_context
  recall_context=$(recall 5)

  log "INFO" "Starting consensus for: ${user_prompt:0:120}"

  local final_response=""
  local -a agent_results=()

  for agent in "${AGENT_ORDER[@]}"; do
    local model="${AGENT_MODELS[$agent]:-llama3}"
    local agent_prompt="[AGENT:${agent}] [CONTEXT:${recall_context}] [PROMPT:${user_prompt}]"
    # Each agent call has a timeout
    local result
    result=$(ollama_call "$agent_prompt" "$model" 30) || true

    # If Ollama returned error prefix, record it
    if [[ "$result" == __OLLAMA_ERROR__* ]]; then
      log "WARN" "Agent $agent produced Ollama error: ${result:0:120}"
      agent_results+=("[$agent]: ERROR:${result}")
      continue
    fi

    agent_results+=("[$agent]: ${result:0:200}")
    # Give CODE and CORE higher influence if present
    if [[ "$agent" == "CORE" || "$agent" == "CODE" ]]; then
      final_response="$result"
    fi
  done

  # If final_response empty, fallback to last agent output
  if [[ -z "$final_response" && ${#agent_results[@]} -gt 0 ]]; then
    final_response="${agent_results[-1]#*: }"
  fi

  remember "user" "$user_prompt"
  remember "ai" "$(echo "$final_response" | sed 's/"/\\"/g')"

  # Output combined result
  {
    echo "--- CONSENSUS REACHED ---"
    echo "$final_response"
    echo ""
    echo "--- AGENT DETAILS ---"
    for r in "${agent_results[@]}"; do
      echo "$r"
    done
  } | sed 's/^/ /'
}

# -------------------------
# File-system agent (safe-by-default)
# -------------------------
# Behavior:
#  - Translate natural instructions into bash using a code model (CODE)
#  - Default: return plan only (dry-run). Execution happens only if ALLOW_EXECUTE=1.
file_agent() {
  local instruction="${1:-}"
  log "INFO" "file_agent received instruction (len=${#instruction})"

  # Ask CODE agent to translate into executable bash (strict instruction)
  local code_model="${AGENT_MODELS[CODE]:-phi:2.7b}"
  local plan
  plan=$(ollama_call "# Linux automation agent. Output ONLY executable bash (no explanations):\n\n$instruction" "$code_model" 30)

  if [[ "$plan" == __OLLAMA_ERROR__* ]]; then
    log "ERROR" "file_agent: code model error: $plan"
    return 2
  fi

  # Sanitize plan preview (do not execute yet)
  local preview_file
  preview_file=$(mktemp "${BASE_DIR}/plan.XXXX.sh")
  printf '%s\n' "#!/usr/bin/env bash" "$plan" > "$preview_file"
  chmod 600 "$preview_file"

  log "INFO" "File Agent produced plan saved to $preview_file (dry-run)"
  echo "----- PLAN PREVIEW BEGIN -----"
  sed -n '1,200p' "$preview_file"
  echo "----- PLAN PREVIEW END -----"

  # Execution policy: explicit env var required
  if [[ "${ALLOW_EXECUTE}" == "1" ]]; then
    log "WARN" "ALLOW_EXECUTE=1, executing plan in subshell with timeout"
    # Run under timeout and in a subshell to limit side effects
    timeout 60 bash "$preview_file"
    local rc=$?
    log "INFO" "Plan executed, rc=$rc"
    rm -f "$preview_file"
    return $rc
  else
    log "INFO" "Execution skipped (ALLOW_EXECUTE not set). To execute set ALLOW_EXECUTE=1 in environment."
    # keep plan for inspection
    echo "Plan saved at: $preview_file"
    return 0
  fi
}

# -------------------------
# API server (Python tiny server) — replace fragile netcat
# -------------------------
start_api_server() {
  # Write small Python HTTP server that exposes:
  # GET /memory   -> recall (JSON)
  # POST /remember {role,content} -> remember
  # POST /prompt {prompt} -> write to FIFO for daemon
  local py="${BASE_DIR}/api_server.py"
  cat > "$py" <<'PY'
#!/usr/bin/env python3
import json,os,sys
from http.server import BaseHTTPRequestHandler,HTTPServer
BASE_DIR=os.environ.get("BASE_DIR","${BASE_DIR}")
DB=os.path.join(BASE_DIR,".db","ai_memory.db")
FIFO=os.path.join(BASE_DIR,"nexus.pipe")
class Handler(BaseHTTPRequestHandler):
    def _send(self,status,body):
        self.send_response(status)
        self.send_header("Content-Type","application/json")
        self.send_header("Content-Length",str(len(body.encode())))
        self.end_headers()
        self.wfile.write(body.encode())
    def do_GET(self):
        if self.path.startswith("/memory"):
            import sqlite3
            conn=sqlite3.connect(DB)
            cur=conn.cursor()
            rows=list(cur.execute("SELECT id,user,role,content,ts FROM memory ORDER BY id DESC LIMIT 20"))
            self._send(200,json.dumps(rows))
        else:
            self._send(404,json.dumps({"error":"not_found"}))
    def do_POST(self):
        length=int(self.headers.get("Content-Length","0"))
        raw=self.rfile.read(length).decode()
        try:
            data=json.loads(raw) if raw else {}
        except:
            data={}
        if self.path.startswith("/remember"):
            role=data.get("role","remote")
            content=data.get("content","")
            import sqlite3
            conn=sqlite3.connect(DB)
            cur=conn.cursor()
            cur.execute("INSERT INTO memory (user,role,content) VALUES (?,?,?)",("remote",role,content))
            conn.commit()
            self._send(200,json.dumps({"status":"remembered"}))
        elif self.path.startswith("/prompt"):
            prompt=data.get("prompt","")
            try:
                with open(FIFO,"w") as f:
                    f.write(prompt+"\n")
                self._send(200,json.dumps({"status":"accepted"}))
            except Exception as e:
                self._send(500,json.dumps({"error":str(e)}))
        else:
            self._send(404,json.dumps({"error":"not_found"}))

if __name__=="__main__":
    port=int(os.environ.get("API_PORT","${API_PORT}"))
    server=HTTPServer(('127.0.0.1',port),Handler)
    print("API server listening on http://127.0.0.1:%d" % port, file=sys.stderr)
    server.serve_forever()
PY
  chmod +x "$py"
  # start server in background
  log "INFO" "Starting API server on http://127.0.0.1:${API_PORT}"
  python3 "$py" &
  sleep 0.2
}

# -------------------------
# Daemon loop
# -------------------------
daemon() {
  init_db
  [[ -p "$FIFO" ]] || mkfifo "$FIFO"

  # start API server
  start_api_server

  # signal handling
  trap 'log "INFO" "Shutting down NEXUS daemon"; pkill -P $$ || true; exit 0' INT TERM

  log "INFO" "NEXUS daemon online (agents active)"
  while true; do
    if read -r input < "$FIFO"; then
      [[ -z "$input" ]] && continue
      log "INFO" "Processing FIFO input: ${input:0:200}"
      local response
      response=$(consensus "$input")
      # if input is an action request, pass to file_agent
      if [[ "$input" =~ ^(create|generate|build|write|delete|refactor) ]]; then
        file_agent "$input"
      fi
      log "INFO" "Response: ${response:0:200}"
    fi
  done
}

# -------------------------
# CLI entry
# -------------------------
case "${1:-}" in
  daemon) daemon ;;
  api) start_api_server ;; 
  remember) shift; remember "user" "$*" ;; 
  recall) shift; recall "${1:-10}" ;; 
  consensus) shift; consensus "$*" ;; 
  file-agent) shift; file_agent "$*" ;; 
  *) 
    if [[ -n "${1:-}" ]]; then
      consensus "$*"
    else
      echo "NEXUS-AI v5.1"
      echo "Usage: $0 [daemon|api|remember|recall|consensus|file-agent]"
    fi
  ;;
esac

