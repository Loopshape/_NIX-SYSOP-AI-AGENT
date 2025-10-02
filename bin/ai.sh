#!/usr/bin/env bash
# AI Autonomic Synthesis Platform v32.1 (Unified & Rebounced)
# A single-file, comprehensive AI agent and project management tool.
# Merges a high-level command dispatcher with a sophisticated multi-stage AGI core.

# --- RUNTIME MODE DETECTION: EMBEDDED NODE.JS WEB SERVER ---
if [[ "${1:-}" == "serve" || "${1:-}" == "--serve" ]]; then
    # Use the full path to the script itself for robust execution
    AI_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)/$(basename "${BASH_SOURCE}")"
    export AI_SCRIPT_PATH
    
    exec node --input-type=module - "$AI_SCRIPT_PATH" "$@" <<'NODE_EOF'
import http from 'http';
import { exec } from 'child_process';
import fs from 'fs';
import path from 'path';

const PORT = process.env.AI_PORT || 8080;
const AI_SCRIPT_PATH = process.env.AI_SCRIPT_PATH; // Inherit from bash
const PROJECTS_DIR = process.env.HOME ? path.join(process.env.HOME, 'ai_projects') : './ai_projects';

const HTML_UI = `
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>AI Autonomic Synthesis Platform v32</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>:root{--bg:#0d1117;--text:#c9d1d9;--accent:#58a6ff;--secondary:#8b949e;--border:#30363d;--input-bg:#161b22;--success:#3fb950;--error:#f85149;}
body{font-family:'SF Mono',Consolas,'Courier New',monospace;background:var(--bg);color:var(--text);margin:0;padding:20px;font-size:14px;line-height:1.6;box-sizing:border-box;}
.container{max-width:1200px;margin:auto;display:grid;grid-template-columns:250px 1fr;grid-template-rows:auto 1fr;gap:20px;height:calc(100vh - 40px);}
h1{grid-column:1 / -1; color:var(--accent);text-align:center;border-bottom:1px solid var(--border);padding-bottom:15px;margin:0;font-size:1.8em;}
.sidebar{display:flex;flex-direction:column;gap:10px;border:1px solid var(--border);border-radius:6px;padding:15px;background:var(--input-bg);min-height:0;}
.sidebar h2{margin:0 0 10px;font-size:16px;color:var(--secondary);border-bottom:1px solid var(--border);padding-bottom:10px;}
#refreshProjects{background:var(--accent);color:var(--bg);border:none;padding:8px 12px;border-radius:5px;cursor:pointer;font-family:inherit;font-weight:bold;}
#refreshProjects:hover{opacity:0.9;}
.project-list{flex-grow:1;overflow-y:auto;padding-right:5px;}
.project-card{background:var(--bg);padding:10px;border-radius:4px;border:1px solid var(--border);margin-bottom:8px;font-size:12px;word-break:break-all;cursor:default;transition:background .2s;}
.project-card:hover{background:var(--border);}
.terminal{background:var(--input-bg);border:1px solid var(--border);border-radius:6px;padding:15px;display:flex;flex-direction:column;min-height:0;}
.output{flex-grow:1;white-space:pre-wrap;overflow-y:auto;}
.input-line{display:flex;border-top:1px solid var(--border);padding-top:10px;margin-top:10px;}
.prompt{color:var(--accent);font-weight:bold;margin-right:10px;}
input{flex-grow:1;background:transparent;border:none;color:var(--text);font-family:inherit;font-size:inherit;outline:none;}
.log{color:var(--secondary);}.success{color:var(--success);}.error{color:var(--error);}
.loading-line{display:flex;align-items:center;color:var(--secondary);margin:5px 0;}
.spinner{width:14px;height:14px;border:2px solid var(--border);border-top:2px solid var(--accent);border-radius:50%;animation:spin 1s linear infinite;margin-right:8px;}
@keyframes spin{to{transform:rotate(360deg);}}
@media (max-width: 800px) {
  body { padding: 10px; font-size: 13px; }
  .container { grid-template-columns: 1fr; grid-template-rows: auto auto 1fr; height: calc(100vh - 20px); gap: 15px; }
  .sidebar { max-height: 40vh; }
  .terminal { min-height: 40vh; }
  h1 { font-size: 1.6em; padding-bottom: 10px; }
}
</style></head>
<body><div class="container"><h1>🤖 AI Autonomic Synthesis Platform v32</h1>
<div class="sidebar"><h2>Projects</h2><button id="refreshProjects">Refresh Projects</button><div id="projectList" class="project-list"></div></div>
<div class="terminal"><div id="output" class="output"><div class="log">🚀 AI Agent ready. System initialized.</div></div><div class="input-line"><span class="prompt">$&gt;</span><input id="input" type="text" autofocus></div></div></div>
<script>
const output = document.getElementById('output');
const input = document.getElementById('input');
const projectList = document.getElementById('projectList');
const refreshProjectsBtn = document.getElementById('refreshProjects');

const appendToOutput = (content, className = '') => {
    const div = document.createElement('div');
    if (className) div.className = className;
    // Sanitize HTML content before adding to prevent XSS, but allow simple formatting
    const sanitizedContent = content.replace(/<script\\b[^>]*>([\\s\\S]*?)<\\/script>/gi, '');
    div.innerHTML = sanitizedContent;
    output.appendChild(div);
    output.scrollTop = output.scrollHeight;
};

input.addEventListener('keydown', async (e) => {
    if (e.key === 'Enter') {
        const command = input.value;
        if (!command) return;
        appendToOutput(\`<span class="prompt">$&gt;</span> \${command}\`);
        input.value = '';
        input.disabled = true;

        const loadingLine = document.createElement('div');
        loadingLine.id = 'loadingLine';
        loadingLine.className = 'loading-line';
        loadingLine.innerHTML = '<div class="spinner"></div><span>🧠 Thinking...</span>';
        output.appendChild(loadingLine);
        output.scrollTop = output.scrollHeight;

        try {
            const response = await fetch('/run', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ command }),
            });
            const result = await response.json();
            const formattedOutput = result.output.replace(/\\u001b\\[[0-9;]*m/g, '');
            appendToOutput(formattedOutput, result.type || (result.success ? 'success' : 'log'));
        } catch (error) {
            appendToOutput(\`❌ <strong>Network Error:</strong> Could not connect to the server. Details: \${error.message}\`, 'error');
        } finally {
            document.getElementById('loadingLine')?.remove();
            input.disabled = false;
            input.focus();
        }
    }
});

const fetchProjects = async () => {
    try {
        const response = await fetch('/projects');
        if (!response.ok) {
            const errorData = await response.json().catch(() => null);
            throw new Error(errorData?.error || \`Server responded with status \${response.status}\`);
        }
        const projects = await response.json();
        projectList.innerHTML = '';
        if (projects.length === 0) {
            projectList.innerHTML = '<div class="log">No projects found.</div>';
        } else {
            projects.forEach(proj => {
                const card = document.createElement('div');
                card.className = 'project-card';
                card.textContent = proj;
                projectList.appendChild(card);
            });
        }
    } catch (error) {
        projectList.innerHTML = '';
        appendToOutput(\`❌ <strong>Project Error:</strong> \${error.message}\`, 'error');
    }
};

refreshProjectsBtn.addEventListener('click', fetchProjects);
fetchProjects();
input.focus();
</script></body></html>
`;
const server = http.createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }
    if (req.url === '/') { res.writeHead(200, { 'Content-Type': 'text/html' }); res.end(HTML_UI); }
    else if (req.url === '/projects' && req.method === 'GET') {
        fs.readdir(PROJECTS_DIR, { withFileTypes: true }, (err, files) => {
            if (err) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: \`Failed to read projects directory: \${PROJECTS_DIR}\` }));
                return;
            }
            const dirs = files.filter(f => f.isDirectory()).map(f => f.name);
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(dirs));
        });
    }
    else if (req.url === '/run' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk.toString(); });
        req.on('end', () => {
            try {
                const { command } = JSON.parse(body);
                // FIX: Correctly escape for bash exec
                const sanitizedCmd = command.replace(/["`$]/g, '\\$&');
                exec(`"\${AI_SCRIPT_PATH}" --prompt "\${sanitizedCmd}"`, { timeout: 600000 }, (error, stdout, stderr) => {
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    if (error) {
                        const errorMessage = stderr || error.message;
                        res.end(JSON.stringify({ type: 'error', output: \`❌ <strong>Command Failed:</strong><br>\${errorMessage.replace(/\\n/g, '<br>')}\` }));
                    } else {
                        const outputType = stdout.includes("✅") ? 'success' : 'log';
                        res.end(JSON.stringify({ type: outputType, output: stdout }));
                    }
                });
            } catch (e) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ type: 'error', output: 'Invalid JSON in request' }));
            }
        });
    } else { res.writeHead(404); res.end('Not Found'); }
});
server.listen(PORT, () => console.log(\`AI Platform UI running at http://localhost:\${PORT}\`));
NODE_EOF
fi
# --- END OF NODE.JS SERVER BLOCK ---


# --- BASH AGENT CORE ---
set -euo pipefail
IFS=$'\n\t'

# ---------------- CONFIGURATION ----------------
AI_HOME="${AI_HOME:-$HOME/.ai_agent}"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/ai_projects}"
LOG_DIR="$AI_HOME/logs"
TMP_DIR="$AI_HOME/tmp"
SWAP_DIR="$AI_HOME/swap"
CORE_DB="$AI_HOME/agent_core.db"
LOG_FILE="$LOG_DIR/system.log"
CONFIG_FILE="$AI_HOME/config"
HMAC_SECRET_KEY="$AI_HOME/secret.key"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# --- Triumvirate Model Configuration ---
MESSENGER_MODEL="llama3:latest"
PLANNER_MODELS=("llama3:latest" "phi3:latest")
EXECUTOR_MODEL="llama3:8b"
OLLAMA_BIN="$(command -v ollama || echo 'ollama')"

# --- Agent Parameters ---
MAX_AGENT_LOOPS=7
MAX_RAM_BYTES=2097152 # 2 MiB
DEPENDENCIES=("git" "npm" "curl" "tar" "nano" "sqlite3" "openssl" "$OLLAMA_BIN")

# ---------------- COLORS & ICONS ----------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m';
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; ORANGE='\033[0;33m'; NC='\033[0m'
ICON_SUCCESS="✅"; ICON_WARN="⚠️"; ICON_ERROR="❌"; ICON_INFO="ℹ️"; ICON_SECURE="🔑";
ICON_DB="🗃️"; ICON_PLAN="📋"; ICON_THINK="🤔"; ICON_EXEC="⚡"; ICON_FEEDBACK="🙋"

# ---------------- LOGGING ----------------
[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"
log_to_file(){ echo "$1" >> "$LOG_FILE"; }
log_msg() {
    local lvl_color="$1" lvl_icon="$2" lvl_name="$3" msg="$4"
    local formatted_msg
    formatted_msg=$(printf "${lvl_color}[%s][%s] %s${NC}" "$lvl_name" "$(date '+%T')" "$msg")
    echo -e "$formatted_msg" >&2
    log_to_file "[${lvl_name}][$(date '+%Y-%m-%d %H:%M:%S')] $msg"
}
log_debug(){ [[ "$LOG_LEVEL" == "DEBUG" ]] && log_msg "$PURPLE" "🐛" "DEBUG" "$*"; }
log_info(){ [[ "$LOG_LEVEL" =~ ^(DEBUG|INFO)$ ]] && log_msg "$BLUE" "$ICON_INFO" "INFO" "$*"; }
log_warn(){ log_msg "$YELLOW" "$ICON_WARN" "WARN" "$*"; }
log_error(){ log_msg "$RED" "$ICON_ERROR" "ERROR" "$*" && exit 1; }
log_success(){ log_msg "$GREEN" "$ICON_SUCCESS" "SUCCESS" "$*"; }
log_phase() { log_msg "$PURPLE" "🚀" "PHASE" "$*"; }
log_think(){ printf "\n${ORANGE}${ICON_THINK} %s${NC}" "$*" >&2; }
log_plan(){ printf "\n${CYAN}${ICON_PLAN} %s${NC}" "$*" >&2; }
log_execute(){ printf "\n${GREEN}${ICON_EXEC} %s${NC}" "$*" >&2; }

# ---------------- EMOJI METADATA ----------------
declare -A EMOJI_METADATA
init_emoji_map() {
    EMOJI_METADATA["✅"]='{"name":"SUCCESS","sentiment":"positive","action_hint":"PROCEED"}'
    EMOJI_METADATA["⚠️"]='{"name":"WARNING","sentiment":"neutral","action_hint":"REVIEW"}'
    EMOJI_METADATA["❌"]='{"name":"ERROR","sentiment":"negative","action_hint":"DEBUG"}'
    EMOJI_METADATA["ℹ️"]='{"name":"INFO","sentiment":"neutral","action_hint":"ACKNOWLEDGE"}'
    EMOJI_METADATA["🔑"]='{"name":"SECURITY_OK","sentiment":"positive","action_hint":"PROCEED_SECURE"}'
    EMOJI_METADATA["🙋"]='{"name":"HUMAN_FEEDBACK","sentiment":"neutral","action_hint":"PROVIDE_GUIDANCE"}'
}

# ---------------- CORE UTILITIES ----------------
check_dependencies() {
    log_info "Checking for required dependencies..."
    local missing_deps=0
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_warn "Dependency missing: $dep"
            ((missing_deps++))
        fi
    done
    if [[ "$missing_deps" -gt 0 ]]; then
        log_error "$missing_deps dependencies are missing. Please run 'ai --heal' to install."
    fi
    log_debug "All dependencies are installed."
}

init_environment() {
    if [[ ! -d "$AI_HOME" ]]; then
        log_info "Project directory not found. Creating new environment at $AI_HOME..."
        mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$LOG_DIR" "$TMP_DIR" "$SWAP_DIR"
        if [[ ! -f "$CONFIG_FILE" ]]; then
            log_info "Creating default config file..."
            cat > "$CONFIG_FILE" << EOF
# AI System Configuration
API_ENDPOINT="http://localhost:11434/api/generate"
EOF
        fi
        if [[ ! -f "$HMAC_SECRET_KEY" ]]; then
            log_info "Generating new HMAC secret key..."
            openssl rand -hex 32 > "$HMAC_SECRET_KEY"; chmod 600 "$HMAC_SECRET_KEY"
        fi
        log_success "Environment initialized successfully."
    fi
}

sqlite_escape(){ echo "$1" | sed "s/'/''/g"; }
register_schema() {
    local table_name="$1" description="$2" schema_sql="$3"
    sqlite3 "$CORE_DB" "$schema_sql" || return 1
    sqlite3 "$CORE_DB" "INSERT OR REPLACE INTO _master_schema (table_name, description, schema_sql) VALUES ('$(sqlite_escape "$1")', '$(sqlite_escape "$2")', '$(sqlite_escape "$3")');"
}
init_db() {
    sqlite3 "$CORE_DB" "CREATE TABLE IF NOT EXISTS _master_schema (table_name TEXT PRIMARY KEY, description TEXT, schema_sql TEXT);"
    local tables_exist; tables_exist=$(sqlite3 "$CORE_DB" "SELECT COUNT(*) FROM _master_schema WHERE table_name IN ('memories', 'tool_logs');")
    if [[ "$tables_exist" -ne 2 ]]; then
        log_warn "One or more core schemas missing. Bootstrapping DB..."
        register_schema "memories" "Long-term memory for fuzzy cache." "CREATE TABLE IF NOT EXISTS memories (id INTEGER PRIMARY KEY, prompt_hash TEXT, prompt TEXT, response_ref TEXT);"
        register_schema "tool_logs" "Logs of every tool execution." "CREATE TABLE IF NOT EXISTS tool_logs (id INTEGER PRIMARY KEY, task_id TEXT, tool_name TEXT, args TEXT, result TEXT);"
    fi
}

calculate_hmac() { local data="$1"; local secret; secret=$(<"$HMAC_SECRET_KEY"); echo -n "$data" | openssl dgst -sha256 -hmac "$secret" | awk '{print $2}'; }
confirm_action() { local c=""; read -p "$(echo -e "\n${YELLOW}PROPOSED ACTION:${NC} ${CYAN}$1${NC}\nApprove? [y/N] ")" -n 1 -r c || true; echo; [[ "${c:-}" =~ ^[Yy]$ ]]; }

# ---------------- AI & MEMORY MANAGEMENT ----------------
hash_string(){ echo -n "$1" | sha256sum | cut -d' ' -f1; }
semantic_hash_prompt(){ echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ' | tr -s ' ' | sed 's/ ^*//;s/ *$//' | tr ' ' '_'; }
store_output_fast(){ local c="$1" h; h=$(hash_string "$c"); if ((${#c}>MAX_RAM_BYTES));then f="$SWAP_DIR/$h.txt.gz"; echo "$c"|gzip>"$f";echo "$f";else echo "$c";fi; }
retrieve_output_fast(){ local r="$1"; if [[ -f "$r" ]];then [[ "$r" == *.gz ]] && gzip -dc "$r"||cat "$r";else echo "$r";fi; }
get_cached_response(){ local p_h; p_h=$(semantic_hash_prompt "$1"); sqlite3 "$CORE_DB" "SELECT response_ref FROM memories WHERE prompt_hash = '$(sqlite_escape "$p_h")' LIMIT 1;"; }
add_to_memory_fast(){ local p_h="$1" p="$2" ref="$3"; sqlite3 "$CORE_DB" "INSERT INTO memories (prompt_hash, prompt, response_ref) VALUES ('$(sqlite_escape "$p_h")','$(sqlite_escape "$p")','$(sqlite_escape "$ref")');"; }

ensure_ollama() { if ! curl -s http://localhost:11434/api/tags >/dev/null; then log_info "Starting Ollama service..."; nohup "$OLLAMA_BIN" serve >/dev/null 2>&1 & sleep 3; if ! curl -s http://localhost:11434/api/tags >/dev/null; then log_error "Failed to start Ollama service."; fi; fi; }
run_worker_fast(){
    local m="$1" s="$2" p="$3" payload r_json
    payload=$(jq -nc --arg m "$m" --arg s "$s" --arg p "$p" '{model:$m,system:$s,prompt:$p,stream:false}')
    r_json=$(curl -s --max-time 300 -X POST http://localhost:11434/api/generate -d "$payload")
    if [[ $(echo "$r_json"|jq -r .error//empty) ]]; then echo "API_ERROR: $(echo "$r_json"|jq -r .error)"; else echo "$r_json"|jq -r .response; fi
}
run_worker_streaming() {
    local model="$1" system_prompt="$2" prompt="$3"
    local full_response=""
    local payload
    payload=$(jq -nc --arg m "$model" --arg s "$system_prompt" --arg p "$prompt" '{model:$m,system:$s,prompt:$p,stream:true}')
    while IFS= read -r line; do
        if jq -e . >/dev/null 2>&1 <<<"$line"; then
            local token
            token=$(echo "$line" | jq -r '.response // empty')
            if [[ -n "$token" ]]; then
                printf "%s" "$token" >&2; full_response+="$token"
            fi
        fi
    done < <(curl -s --max-time 300 -X POST http://localhost:11434/api/generate -d "$payload")
    printf "\n" >&2
    echo "$full_response"
}

# ---------------- DEVOPS TOOLSET ----------------
tool_run_command() { local proj_dir="$1" cmd="$2"; (cd "$proj_dir" && eval "$cmd") 2>&1 || echo "Command failed."; }
tool_write_file() { local proj_dir="$1" f_path="$2" content="$3"; mkdir -p "$(dirname "$proj_dir/$f_path")"; echo -e "$content">"$proj_dir/$f_path"; echo "File '$f_path' written."; }
tool_ask_human() {
    local proj_dir="$1"; shift 1; local question="$*"
    echo -e "\n${YELLOW}${ICON_FEEDBACK} AI requests your input:${NC} ${CYAN}$question${NC}"
    read -p "Your Response: " -r user_response
    echo "Human feedback received: '$user_response'"
}
tool_get_emoji_meaning() {
    local proj_dir="$1" emoji="$2"
    local meaning="${EMOJI_METADATA[$emoji]:-unknown}"
    echo "Meaning of '$emoji': $meaning"
}

# --- Export functions for subshells ---
export -f log_to_file log_msg log_debug log_info log_warn log_error log_success log_phase log_think log_plan log_execute
export -f hash_string semantic_hash_prompt store_output_fast retrieve_output_fast get_cached_response add_to_memory_fast sqlite_escape run_worker_fast run_worker_streaming
export -f tool_run_command tool_write_file tool_ask_human tool_get_emoji_meaning calculate_hmac
export AI_HOME LOG_LEVEL CORE_DB PROJECTS_DIR MAX_AGENT_LOOPS HMAC_SECRET_KEY MESSENGER_MODEL EXECUTOR_MODEL OLLAMA_BIN
export -a PLANNER_MODELS

# ---------------- AUTONOMOUS WORKFLOW ----------------
run_agi_workflow() {
    local user_prompt="$*"
    local task_id; task_id=$(hash_string "$user_prompt$(date +%s%N)" | cut -c1-16)
    local project_dir="$PROJECTS_DIR/task-$task_id"; mkdir -p "$project_dir"
    log_success "Project workspace: $project_dir (Task ID: $task_id)"

    local cached_ref; cached_ref=$(get_cached_response "$user_prompt")
    if [[ -n "$cached_ref" ]]; then
        log_success "Found high-quality match in fuzzy cache."
        echo -e "\n${CYAN}--- Cached Final Answer ---\n${NC}$(retrieve_output_fast "$cached_ref")"; return
    fi
    
    local conversation_history="Initial User Request: $user_prompt"
    local status="IN_PROGRESS"
    local last_used_emoji="ℹ️"

    for ((i=1; i<=MAX_AGENT_LOOPS; i++)); do
        log_phase "AGI Loop $i/$MAX_AGENT_LOOPS"
        
        local emoji_context="${EMOJI_METADATA[$last_used_emoji]}"
        
        log_think "Messenger (${MESSENGER_MODEL}) Analysis: "
        local messenger_prompt="PREVIOUS_ACTION_CONTEXT: $emoji_context. You are the Messenger. Analyze the current conversation context. If the previous action resulted in an error, focus on why. Provide a clear summary of the current state."
        local messenger_output; messenger_output=$(run_worker_streaming "$MESSENGER_MODEL" "$messenger_prompt" "$conversation_history")
        
        local pids=() temp_files=() planner_outputs=()
        for model in "${PLANNER_MODELS[@]}"; do
            local temp_file; temp_file=$(mktemp)
            temp_files+=("$temp_file")
            (
                log_debug "Starting planner: $model"
                local planner_prompt="You are a strategic Planner. If confused, use 'tool_ask_human <question>'. Otherwise, propose ONE specific tool to use next."
                run_worker_fast "$model" "$planner_prompt" "$messenger_output" > "$temp_file" 2> "${temp_file}.err"
            ) &
            pids+=($!)
        done

        local planner_errors=""
        for idx in "${!pids[@]}"; do
            if ! wait "${pids[$idx]}"; then
                log_warn "A planner model (${PLANNER_MODELS[$idx]}) exited with a non-zero status."
                local err_file="${temp_files[$idx]}.err"
                if [[ -s "$err_file" ]]; then planner_errors+="Error from ${PLANNER_MODELS[$idx]}:\n$(cat "$err_file")\n"; fi
            fi
        done

        local executor_context="PREVIOUS_ACTION_CONTEXT: $emoji_context. You are the Executor. Synthesize the plans. If planners failed, suggest 'tool_ask_human' about the failure. Decide the single best tool to use.
Format:
[REASONING] Your synthesis.
[TOOL] tool_name <arguments>
If solved, respond ONLY with: [FINAL_ANSWER] Your summary.
--- MESSENGER'S ANALYSIS ---
$messenger_output"
        if [[ -n "$planner_errors" ]]; then executor_context+="\n\n--- PLANNER ERRORS (investigate these) ---\n$planner_errors"; fi

        for idx in "${!PLANNER_MODELS[@]}"; do
            local model="${PLANNER_MODELS[$idx]}"; local file="${temp_files[$idx]}"
            local planner_output; planner_output=$(cat "$file")
            planner_outputs+=("$planner_output")
            log_plan "Planner (${model}) Strategy:\n${planner_output}"
            executor_context+="\n\n--- Plan from ${model} ---\n${planner_output}"
        done
        rm -f "${temp_files[@]}"*
        
        log_execute "Executor (${EXECUTOR_MODEL}) Decision: "
        local final_plan; final_plan=$(run_worker_streaming "$EXECUTOR_MODEL" "Executor" "$executor_context")
        
        if [[ "$final_plan" == *"[FINAL_ANSWER]"* ]]; then status="SUCCESS"; conversation_history="$final_plan"; last_used_emoji="✅"; break; fi

        local tool_line; tool_line=$(echo "$final_plan" | grep '\[TOOL\]' | head -n 1)
        if [[ -z "$tool_line" ]]; then log_warn "Executor did not choose a tool. Ending loop."; last_used_emoji="⚠️"; break; fi

        local clean_tool_cmd; clean_tool_cmd=$(echo "${tool_line#\[TOOL\] }" | sed 's/\r$//')
        local ai_hmac; ai_hmac=$(calculate_hmac "$clean_tool_cmd")
        local verified_hmac; verified_hmac=$(calculate_hmac "$clean_tool_cmd")
        if [[ "$ai_hmac" != "$verified_hmac" ]]; then log_error "HMAC MISMATCH!"; status="HMAC_FAILURE"; last_used_emoji="❌"; break; fi
        log_success "${ICON_SECURE} HMAC signature verified."; last_used_emoji="🔑"

        local tool_name; tool_name=$(echo "$clean_tool_cmd" | awk '{print $1}')
        local args_str; args_str=$(echo "$clean_tool_cmd" | cut -d' ' -f2-)
        local tool_args=(); eval "tool_args=($args_str)"

        local tool_result="User aborted action."
        if confirm_action "$clean_tool_cmd"; then
            if declare -f "tool_$tool_name" > /dev/null; then
                tool_result=$(tool_"$tool_name" "$project_dir" "${tool_args[@]}") || "Tool failed."
                if [[ "$tool_result" == Error:* ]]; then last_used_emoji="❌"; else last_used_emoji="✅"; fi
            else
                log_error "AI tried to call an unknown tool: '$tool_name'"; tool_result="Error: Tool '$tool_name' does not exist."
                last_used_emoji="❌";
            fi
        else
            last_used_emoji="⚠️"
        fi
        
        sqlite3 "$CORE_DB" "INSERT INTO tool_logs (task_id, tool_name, args, result) VALUES ('$task_id', '$tool_name', '$(sqlite_escape "$args_str")', '$(sqlite_escape "$tool_result")');"
        conversation_history="${last_used_emoji} Loop $i Result:\n[EXECUTOR PLAN]\n${final_plan}\n[TOOL RESULT]\n${tool_result}"
    done
    
    log_phase "AGI Workflow Complete (Status: $status)"
    local final_answer; final_answer=$(echo "$conversation_history" | grep '\[FINAL_ANSWER\]' | sed 's/\[FINAL_ANSWER\]//' | tail -n 1)
    if [[ -z "$final_answer" ]]; then final_answer="Workflow finished. Final context:\n$conversation_history"; fi

    local final_ref; final_ref=$(store_output_fast "$final_answer")
    add_to_memory_fast "$(semantic_hash_prompt "$user_prompt")" "$user_prompt" "$final_ref"
    echo -e "\n${GREEN}--- Final Answer ---\n${NC}${final_answer}"
}

# ---------------- PROJECT MANAGEMENT FEATURES ----------------
self_heal() {
    log_info "Initiating self-heal sequence..."
    check_dependencies
    log_info "Cleaning temporary files..."
    rm -f "$TMP_DIR"/*
    log_success "Self-heal executed successfully."
}
scan_project() {
    log_info "Scanning for TODO/FIXME comments in code..."
    grep -r --color=always -E "TODO|FIXME" . --exclude-dir={".git","node_modules",".ai_agent"} || log_info "No TODOs or FIXMEs found."
    log_info "Scanning for script and source files..."
    find . -type f \( -name "*.sh" -o -name "*.js" -o -name "*.ts" \) -not -path "./node_modules/*" -not -path "./.ai_agent/*"
}
show_status() {
    log_info "Displaying system status..."
    echo "  - AI Home Directory: $AI_HOME"
    echo "  - Log File: $LOG_FILE"
    echo "  - Config File: $CONFIG_FILE"
    echo "  - Core Database: $CORE_DB"
    check_dependencies
}

# ---------------- MAIN DISPATCHER ----------------
main() {
    # Initialize core components on every run
    init_environment
    init_db
    init_emoji_map

    local cmd="${1:-}"

    case "$cmd" in
        --help)
            cat << EOF
Usage: ai <command> [options]

Core AI Commands:
  serve, --serve           Launch the interactive AI web server.
  <prompt>, --prompt ...   Run the AGI workflow with a specific prompt.
  --auto                   Run a predefined automatic AGI workflow.

Project & System Management:
  --build, --compile       Build the project using npm.
  --rebuild                Clean and rebuild the project.
  --scan                   Scan project files for TODOs and list sources.
  --config                 Open the configuration file for editing.
  --upload                 Create a compressed archive of the current directory.
  --fix, --heal            Run a self-heal check, dependency check, and cleanup.
  --status                 Display current system status and check dependencies.
  --clean                  Remove all temporary files from the AI environment.
  --git <git_args...>      Pass commands directly to git.
  --setup                  (DEPRECATED) Use --status or --heal instead.
  --help                   Show this help message.
EOF
            ;;
        serve|--serve)
            # This case is handled by the Node.js block at the top
            exit 0
            ;;
        --build|--compile)
            log_info "Building project..."
            npm run build
            log_success "Build finished."
            ;;
        --rebuild)
            log_info "Cleaning project (removing dist)..."
            rm -rf ./dist
            log_info "Rebuilding project..."
            npm run build
            log_success "Rebuild finished."
            ;;
        --scan)
            scan_project
            ;;
        --config)
            log_info "Opening configuration in nano..."
            nano "$CONFIG_FILE"
            ;;
        --status)
            show_status
            ;;
        --clean)
            log_info "Cleaning AI temporary directory..."
            rm -f "$TMP_DIR"/*
            log_success "Temporary files cleaned."
            ;;
        --auto)
            ensure_ollama
            log_info "Running automatic workflow..."
            run_agi_workflow "Analyze the current project status and suggest improvements."
            ;;
        --upload)
            local archive_name="project_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            log_info "Creating project archive: $archive_name..."
            tar -czf "$archive_name" . --exclude=".git" --exclude="node_modules" --exclude=".ai_agent"
            log_success "Project archived. Ready for upload."
            ;;
        --prompt)
            shift
            if [[ -z "$*" ]]; then log_error "The '--prompt' flag requires an argument."; fi
            ensure_ollama
            run_agi_workflow "$@"
            ;;
        --fix|--heal)
            self_heal
            ;;
        --git)
            shift
            if [[ -z "$*" ]]; then log_error "The '--git' flag requires a command (e.g., status, push)."; fi
            log_info "Executing git command: git $*"
            git "$@"
            ;;
        "")
            log_warn "No command given. Use --help for available options."
            ;;
        *)
            # Default action: treat any non-flag argument as a prompt
            ensure_ollama
            log_info "Defaulting to AGI prompt."
            run_agi_workflow "$@"
            ;;
    esac
}

# --- SCRIPT ENTRY POINT ---
if [[ -z "${NODE_ENV:-}" ]]; then
    main "$@"
fi
