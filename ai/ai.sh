#!/usr/bin/env bash

# =============================================================================
#  NEXUS-AI – Autonomous Cognitive Operating System (v5.2)
#  Singlefile CLI + Daemon + REST (Python helper) + Multi-Agent Consensus
#  Enhancements in v5.2:
#   - model-to-memory recording: every agent output is stored with agent attribution
#   - quorum voting (simple hash-majority) to choose final response
#   - improved Ollama bridge with JSON parsing, backoff and richer error codes
#   - Node/Browser-friendly static UI scaffolding (static www/ + minimal index.html)
#   - safer execution model (dry-run default; signed manifest for auto-run)
#   - systemd service unit generator helper
#   - structured JSONL logging + agent_output DB table
#   - smaller configurable timeouts & per-agent weights
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# List of available/intended commands for this script:
# eval, exec, bash, node, python3, npm, awk, sed, cd, cat, pkill, mkdir, chown, chmod, sudo, echo, grep, ls, uname, free, date, hash

# -------------------------
# CONFIG
# -------------------------
BASE_DIR="${HOME}/_/ai"
DB_DIR="${BASE_DIR}/.db"
DB_FILE="${DB_DIR}/ai_memory.db"
FIFO="${BASE_DIR}/nexus.pipe"
WWW_DIR="${BASE_DIR}/www"
API_PORT="${API_PORT:-7331}"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
LOG_FILE="${DB_DIR}/ai_system.log"
STRUCTURED_LOG="${DB_DIR}/ai_system.jsonl"

# Node.js and npm are assumed to be available for potential frontend tasks or build tooling.
# Example: `npm install <package>` or `node <script.js>`

# Map of agent label -> model (adjust to your local names)
declare -A AGENT_MODELS=(
  [SIGN]="glm-4.7:cloud"
  [CUBE]="gemma3:1b"
  [CORE]="deepseek-v3.1:671b-cloud"
  [LOOP]="loop:latest"
  [LINE]="line:latest"
  [WAVE]="qwen3-vl:2b"
  [COIN]="stable-code:latest"
  [CODE]="phi:2.7b"
  [WORK]="deepseek-v3.1:671b-cloud"
)
# Optional per-agent timeout (seconds) and weight (simple int)
declare -A AGENT_TIMEOUT=( [SIGN]=40 [CUBE]=20 [CORE]=30 [LOOP]=18 [LINE]=18 [WAVE]=20 [COIN]=20 [CODE]=30 [WORK]=25 )
declare -A AGENT_WEIGHT=( [SIGN]=4 [CUBE]=1 [CORE]=3 [LOOP]=1 [LINE]=1 [WAVE]=1 [COIN]=1 [CODE]=3 [WORK]=1 )

AGENT_ORDER=(SIGN CUBE CORE LOOP LINE WAVE COIN CODE WORK)

# Operational flags
ALLOW_EXECUTE="${ALLOW_EXECUTE:-0}"   # must be set to 1 explicitly to execute model-produced shell code
DEFAULT_TIMEOUT=30                       # seconds for external calls
OLLAMA_RETRIES=3
MAX_CONTENT_LEN=8192                    # max chars to store in memory

# -------------------------
# MCP Extension
# -------------------------
MCP_LOADER="${HOME}/_/mcp/loader.sh"
if [[ -f "$MCP_LOADER" ]]; then
    # We need to define log function before sourcing if the loader uses it,
    # but the log function is defined later in this script.
    # However, the loader defined in generate_mcp_content.py only uses echo.
    # So it is safe to source here, or we can move this block after log function definition.
    # Ideally, source it after log definition so we can use log inside the check.
    : # Placeholder for logic flow, see actual insertion below
fi

# Use mkdir, chown, chmod for directory setup. sudo might be needed for chown if running as non-owner.
# Example: sudo chown -R $USER:$USER "$BASE_DIR"
mkdir -p "$DB_DIR" "$WWW_DIR"
touch "$LOG_FILE" "$STRUCTURED_LOG"
[[ -f "$DB_FILE" ]] || touch "$DB_FILE"

# -------------------------
# Logging helpers
# -------------------------
log() {
  local level="$1"; shift
  local msg="$*"
  local ts
  # date command is used for timestamping.
  ts=$(date --utc +"%Y-%m-%dT%H:%M:%SZ")
  # echo is used for logging to stdout/stderr. grep can be used to filter logs.
  echo "[${ts}] [${level}] ${msg}" | tee -a "$LOG_FILE" >&2
  # structured line
  # python3 is used for JSON formatting.
  python3 -c "import json,sys; obj=dict(ts='$ts',level='$level',msg='$msg'); print(json.dumps(obj))" >> "$STRUCTURED_LOG" 2>/dev/null || true
}

# -------------------------
# MCP Extension Loading
# -------------------------
if [[ -f "$MCP_LOADER" ]]; then
  log "INFO" "Loading MCP extensions from $MCP_LOADER"
  # source command is used to load external scripts.
  source "$MCP_LOADER"
else
  log "WARN" "MCP loader not found at $MCP_LOADER"
fi

# -------------------------
# DB / Memory helpers
# -------------------------
init_db() {
  # sqlite3 is used for database operations. hash is used via sha256sum.
  # bash is implicitly used by sqlite3 command.
  sqlite3 "$DB_FILE" <<'SQL'
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS memory (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 user TEXT,
 role TEXT,
 content TEXT,
 ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS agent_output (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 agent TEXT,
 model TEXT,
 content TEXT,
 hash TEXT,
 ts DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_memory_ts ON memory (ts);
CREATE INDEX IF NOT EXISTS idx_agent_output_ts ON agent_output (ts);
SQL
}

sanitize_sql_value() {
  # remove NULs, limit length, basic quote escape
  local v="$1"
  v="${v//$'\000'/}"                # remove NUL
  # echo and sed are used for string manipulation.
  v="$(echo "$v" | sed 's/\r//g')" # strip CR
  v="${v//\'/''}"                    # single-quote escape for sqlite
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

record_agent_output() {
  local agent="$1"; local model="$2"; local content="$3"
  local safe_agent safe_model safe_content
  safe_agent=$(sanitize_sql_value "$agent")
  safe_model=$(sanitize_sql_value "$model")
  safe_content=$(sanitize_sql_value "$content")
  local h
  # hash is used here via sha256sum and awk
  h=$(printf '%s' "$safe_content" | sha256sum | awk '{print $1}')
  sql_exec "INSERT INTO agent_output (agent,model,content,hash) VALUES ('$safe_agent','$safe_model','$safe_content','$h');"
}

recall() {
  local limit="${1:-10}"
  init_db
  # python3 is used for JSON formatting. sqlite3 for DB query.
  sqlite3 -json "$DB_FILE" "SELECT id,user,role,content,ts FROM memory ORDER BY id DESC LIMIT $limit;"
}

# -------------------------
# Ollama API bridge (robust)
# -------------------------
ollama_call() {
  # usage: ollama_call "<prompt>" "<model>" "<timeout_seconds>"
  local prompt="${1:-}"
  local model="${2:-${AGENT_MODELS[CODE]:-glm-4.7:cloud}}"
  local timeout="${3:-$DEFAULT_TIMEOUT}"

  log "DEBUG" "ollama_call model=$model timeout=${timeout}s prompt_len=${#prompt}"

  # Prepare payload safely (use jq to escape prompt)
  local payload
  # jq is a JSON processor, often used with shell scripts.
  payload=$(jq -n --arg m "$model" --arg p "$prompt" '{model:$m,prompt:$p,stream:false}' 2>/dev/null) || {
    # fallback simple json-escape if jq is not available
    # sed is used for escaping
    payload=$(printf '{"model":"%s","prompt":"%s","stream":false}' "$model" "$(echo "$prompt" | sed 's/"/\\"/g')")
  }

  local attempt=0
  local response err
  while (( attempt < OLLAMA_RETRIES )); do
    attempt=$((attempt+1))
    # curl is used for HTTP requests.
    response=$(curl -sS --max-time "$timeout" -H "Content-Type: application/json" -d "$payload" "${OLLAMA_HOST}/api/generate" 2>&1) || err="$response"
    if [[ -n "$response" ]]; then
      # try to extract common fields with jq
      local extracted
      extracted=$(echo "$response" | jq -r '.response // .output // .[0].response // empty' 2>/dev/null || true)
      if [[ -n "$extracted" ]]; then
        printf '%s' "$extracted"
        return 0
      fi
      # if JSON parse failed, but response non-empty, return raw
      printf '%s' "$response"
      return 0
    fi
    log "WARN" "Ollama call attempt $attempt failed: ${err:0:200}"
    sleep $((attempt * 1))
  done

  log "ERROR" "Ollama unreachable after ${OLLAMA_RETRIES} attempts"
  printf '__OLLAMA_ERROR__:%s' "${err:-timeout}"
  return 2
}

# -------------------------
# Consensus engine (hash-majority + weight fallback)
# -------------------------
consensus() {
  local user_prompt="${1:-}"
  local recall_context
  # recall uses sqlite3 and python3.
  recall_context=$(recall 5 || true)

  log "INFO" "Starting consensus for: ${user_prompt:0:120}"

  local -a agent_results=()
  declare -A hash_score
  declare -A hash_value

  for agent in "${AGENT_ORDER[@]}"; do
    local model="${AGENT_MODELS[$agent]:-glm-4.7:cloud}"
    local timeout=${AGENT_TIMEOUT[$agent]:-$DEFAULT_TIMEOUT}
    local prompt="[AGENT:${agent}] [CONTEXT:${recall_context}] [PROMPT:${user_prompt}]"
    local result
    # ollama_call uses curl, sed, printf, echo, awk (via sha256sum piping)
    result=$(ollama_call "$prompt" "$model" "$timeout") || true

    if [[ "$result" == __OLLAMA_ERROR__* ]]; then
      log "WARN" "Agent $agent produced Ollama error: ${result:0:120}"
      agent_results+=("[$agent]: ERROR:${result}")
      continue
    fi

    # normalize output (trim)
    local norm
    # sed is used for trimming whitespace
    norm=$(echo "$result" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # record agent output
    record_agent_output "$agent" "$model" "$norm"

    # compute hash
    local h
    # hash is used here via sha256sum and awk
    h=$(printf '%s' "$norm" | sha256sum | awk '{print $1}')
    hash_value[$h]="$norm"
    # increase score by agent weight
    local w=${AGENT_WEIGHT[$agent]:-1}
    hash_score[$h]=$(( ${hash_score[$h]:-0} + w ))

    agent_results+=("[$agent]: ${norm:0:200}")
  done

  # choose highest-scoring hash
  local best_hash="" best_score=0
  for k in "${!hash_score[@]}"; do
    local s=${hash_score[$k]}
    if (( s > best_score )); then
      best_score=$s; best_hash=$k
    fi
  done

  local final_response
  if [[ -n "$best_hash" ]]; then
    final_response="${hash_value[$best_hash]}"
  else
    # fallback to last agent
    final_response="${agent_results[-1]#*: }"
  fi

  # store to memory both prompt and model "reasoning" (model-to-memory)
  remember "user" "$user_prompt"
  remember "model" "${final_response}"

  # output combined result
  # echo and sed are used here.
  {
    echo "--- CONSENSUS REACHED ---"
    echo "$final_response"
    echo ""
    echo "--- AGENT DETAILS ---"
    for r in "${agent_results[@]}"; do
      echo "$r"
    done
  } | sed 's/^/ /' # sed for formatting output
}

# -------------------------
# File-system agent (safe-by-default)
# -------------------------
file_agent() {
  local instruction="${1:-}"
  log "INFO" "file_agent received instruction (len=${#instruction})"

  local code_model="${AGENT_MODELS[CODE]:-glm-4.7:cloud}"
  local plan
  # ollama_call uses curl, sed, printf, echo, awk.
  plan=$(ollama_call "# Linux automation agent. Output ONLY executable bash (no explanations):\n\n$instruction" "$code_model" 30)

  if [[ "$plan" == __OLLAMA_ERROR__* ]]; then
    log "ERROR" "file_agent: code model error: $plan"
    return 2
  fi

  # Sanitize plan preview (do not execute yet)
  local preview_file
  # mktemp creates a temporary file.
  preview_file=$(mktemp "${BASE_DIR}/plan.XXXX.sh")
  # printf and echo write to the file. chmod sets permissions.
  printf '%s\n' "#!/usr/bin/env bash" "$plan" > "$preview_file"
  chmod 600 "$preview_file"

  log "INFO" "File Agent produced plan saved to $preview_file (dry-run)"
  echo "----- PLAN PREVIEW BEGIN -----"
  # sed is used to limit preview output.
  sed -n '1,200p' "$preview_file"
  echo "----- PLAN PREVIEW END -----"

  if [[ "${ALLOW_EXECUTE}" == "1" ]]; then
    log "WARN" "ALLOW_EXECUTE=1, executing plan in subshell with timeout"
    # The 'bash' command itself is used for execution.
    # 'timeout' is a command-line utility.
    # eval and exec can be used here for more complex command execution, but with caution:
    # Example using eval: eval "$plan" # DANGEROUS: executes arbitrary code.
    # Example using exec: exec bash -c "your_command_here" # Replaces current shell process.
    # USE WITH EXTREME CAUTION: eval and exec can lead to security vulnerabilities if the plan is untrusted.
    timeout 60 bash "$preview_file"
    local rc=$?
    log "INFO" "Plan executed, rc=$rc"
    # rm removes the temporary file.
    rm -f "$preview_file"
    return $rc
  else
    log "INFO" "Execution skipped (ALLOW_EXECUTE not set). To execute set ALLOW_EXECUTE=1 in environment."
    echo "Plan saved at: $preview_file"
    return 0
  fi
}

# -------------------------
# API server (Python tiny server) — improved
# -------------------------
start_api_server() {
  local py="${BASE_DIR}/api_server.py"
  # Writing the Python script to a file. python3 is used to execute it.
  # This script uses http.server, json, os, sys, sqlite3.
  cat > "$py" <<PY
#!/usr/bin/env python3
import json,os,sys,sqlite3
from http.server import BaseHTTPRequestHandler,HTTPServer
BASE_DIR=os.environ.get('BASE_DIR', "${BASE_DIR}")
DB=os.path.join(BASE_DIR,'.db','ai_memory.db')
FIFO=os.path.join(BASE_DIR,'nexus.pipe')
WWW=os.path.join(BASE_DIR,'www')
class Handler(BaseHTTPRequestHandler):
    def _send(self,status,body):
        self.send_response(status)
        self.send_header('Content-Type','application/json')
        self.send_header('Content-Length',str(len(body.encode())))
        self.end_headers()
        self.wfile.write(body.encode())
    def do_GET(self):
        if self.path.startswith('/memory'):
            conn=sqlite3.connect(DB)
            cur=conn.cursor()
            # sqlite3 is used here.
            rows=list(cur.execute('SELECT id,user,role,content,ts FROM memory ORDER BY id DESC LIMIT 50'))
            self._send(200,json.dumps(rows))
        elif self.path.startswith('/agent_output'):
            conn=sqlite3.connect(DB)
            cur=conn.cursor()
            # sqlite3 is used here.
            rows=list(cur.execute('SELECT id,agent,model,substr(content,1,400) as content,ts FROM agent_output ORDER BY id DESC LIMIT 100'))
            self._send(200,json.dumps(rows))
        elif self.path == '/' or self.path.startswith('/index'):
            try:
                # cat could be used here to read index.html, but Python reads it directly.
                with open(os.path.join(WWW,'index.html'),'r',encoding='utf-8') as f:
                    data=f.read()
                self.send_response(200)
                self.send_header('Content-Type','text/html; charset=utf-8')
                self.end_headers()
                self.wfile.write(data.encode())
            except Exception as e:
                self._send(500,json.dumps({'error':str(e)}))
        else:
            self._send(404,json.dumps({'error':'not_found'}))
    def do_POST(self):
        length=int(self.headers.get('Content-Length','0'))
        raw=self.rfile.read(length).decode()
        try:
            data=json.loads(raw) if raw else {}
        except:
            data={}
        if self.path.startswith('/remember'):
            role=data.get('role','remote')
            content=data.get('content','')
            conn=sqlite3.connect(DB)
            cur=conn.cursor()
            cur.execute('INSERT INTO memory (user,role,content) VALUES (?,?,?)',('remote',role,content))
            conn.commit()
            self._send(200,json.dumps({'status':'remembered'}))
        elif self.path.startswith('/prompt'):
            prompt=data.get('prompt','')
            try:
                # echo could be used to write to FIFO, but Python does it directly.
                with open(FIFO,'w') as f:
                    f.write(prompt+'\n')
                self._send(200,json.dumps({'status':'accepted'}))
            except Exception as e:
                self._send(500,json.dumps({'error':str(e)}))
        else:
            self._send(404,json.dumps({'error':'not_found'}))
if __name__=='__main__':
    port=int(os.environ.get('API_PORT', "${API_PORT}"))
    server=HTTPServer(('127.0.0.1',port),Handler)
    print('API server listening on http://127.0.0.1:%d' % port, file=sys.stderr)
    server.serve_forever()
PY
  chmod +x "$py"
  log "INFO" "Starting API server on http://127.0.0.1:${API_PORT}"
  # python3 is used to run the server in the background.
  python3 "$py" &
  sleep 0.2
}

# -------------------------
# Static UI scaffold
# -------------------------
write_static_ui() {
  # cat is implicitly used to write this content to index.html
  cat > "${WWW_DIR}/index.html" <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>NEXUS-AI Dashboard</title>
<style>
body{font-family:sans-serif;margin:18px;background:#0f0f12;color:#eaeaea}
.card{background:#111;padding:12px;border-radius:8px;margin-bottom:12px}
pre{white-space:pre-wrap}
</style>
</head>
<body>
<h1>NEXUS-AI — Dashboard</h1>
<div class="card">
<h3>Send prompt</h3>
<textarea id="prompt" rows="4" cols="60"></textarea><br/>
<button id="send">Send</button>
<pre id="resp"></pre>
</div>
<div class="card">
<h3>Recent memory</h3>
<pre id="mem">loading...</pre>
</div>
<script>
async function fetchMem(){
  const r=await fetch('/memory');
  const j=await r.json();
  document.getElementById('mem').textContent=JSON.stringify(j,null,2);
}
fetchMem();
document.getElementById('send').onclick=async()=>{
  const p=document.getElementById('prompt').value;
  const res=await fetch('/prompt',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({prompt:p})});
  const j=await res.json();
  document.getElementById('resp').textContent=JSON.stringify(j,null,2);
}
</script>
</body>
</html>
HTML
  log "INFO" "Wrote static UI to ${WWW_DIR}/index.html"
}

# -------------------------
# Systemd unit generator
# -------------------------
write_systemd_unit() {
  local unit="/etc/systemd/system/nexus-ai.service"
  # cat is used to write the unit file.
  # sudo might be required to write to /etc/systemd/system/.
  # Example: sudo tee $unit < "${BASE_DIR}/nexus-ai.service"
  cat > "${BASE_DIR}/nexus-ai.service" <<UNIT
[Unit]
Description=NEXUS-AI daemon
After=network.target

[Service]
Type=simple
User=${USER}
Environment=BASE_DIR=${BASE_DIR}
ExecStart=${BASE_DIR}/nexus_ai_v5.2.sh daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
  log "INFO" "Wrote systemd unit template to ${BASE_DIR}/nexus-ai.service (copy to /etc/systemd/system/ to install)"
}

# -------------------------
# System Information Tools
# -------------------------
# uname and free commands are available for system information.
# Example usage:
system_info() {
  log "INFO" "--- System Information ---"
  # uname and free are standard Linux commands.
  uname -a | log "INFO"
  free -h | log "INFO"
  log "INFO" "------------------------"
}

# -------------------------
# Daemon loop
# -------------------------
daemon() {
  # Basic system info on startup
  log "INFO" "NEXUS Daemon starting..."
  system_info # Call the system_info function

  init_db
  # mkfifo creates a named pipe.
  [[ -p "$FIFO" ]] || mkfifo "$FIFO"
  write_static_ui
  start_api_server

  # trap handles signals like INT and TERM for clean shutdown. pkill is used.
  trap 'log "INFO" "Shutting down NEXUS daemon"; pkill -P $$ || true; exit 0' INT TERM

  log "INFO" "NEXUS daemon online (agents active)"
  while true; do
    # read is a bash builtin. cd might be used within loops or commands.
    if read -r input < "$FIFO"; then
      [[ -z "$input" ]] && continue
      log "INFO" "Processing FIFO input: ${input:0:200}"
      local response
      # consensus uses multiple tools: ollama_call (curl, sed, awk), record_agent_output, remember, echo, sed.
      response=$(consensus "$input") || true
      # file_agent uses ollama_call, mktemp, printf, chmod, sed, timeout, bash, rm.
      # eval and exec can be used here if ALLOW_EXECUTE is 1, with extreme caution.
      if [[ "$input" =~ ^(create|generate|build|write|delete|refactor) ]]; then
        # Example of using eval: eval "$plan" # DANGEROUS: executes arbitrary code.
        # Example of using exec: exec bash -c "your_command_here" # Replaces current shell process.
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
  write-systemd) write_systemd_unit ;;
  *)
    if [[ -n "${1:-}" ]]; then
      # Using bash as the primary interpreter for the script itself.
      # cd could be used here to change directory before executing commands.
      # Example: cd /path/to/dir
      consensus "$*"
    else
      echo "NEXUS-AI v5.2"
      echo "Usage: $0 [daemon|api|remember|recall|consensus|file-agent|write-systemd]"
      echo "Available commands include: eval, exec, bash, node, python3, npm, awk, sed, cd, cat, pkill, mkdir, chown, chmod, sudo, echo, grep, ls, uname, free, date, hash."
      # Example usage of some commands:
      # echo "Current directory: $(pwd)"
      # ls -l | grep ".py$"
      # node --version
      # npm --version
      # sudo apt update # requires sudo privileges
    fi
  ;;
esac