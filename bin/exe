#!/usr/bin/env bash
# AI Autonomic Synthesis Platform v1.20 (Full Features)
set -euo pipefail
IFS=$'\n\t'

# === ENVIRONMENT ===
AI_HOME="${AI_HOME:-$HOME/.local_ai}"
BIN_PATH="${BIN_PATH:-$HOME/bin/ai}"
PROJECTS_DIR="$AI_HOME/projects"
TMP_DIR="$AI_HOME/tmp"
SWAP_DIR="$AI_HOME/swap"
DOWNLOADS_DIR="$AI_HOME/downloads"
OUTPUTS_DIR="$AI_HOME/outputs"
LOG_DIR="$AI_HOME/logs"
CORE_DB="$AI_HOME/agent_core.db"
TASK_DB="$AI_HOME/ai_task_manager.db"
LOG_FILE="$LOG_DIR/system.log"
HMAC_SECRET_KEY="$AI_HOME/secret.key"

MODELS=("core" "coin" "loop" "code" "2244")
DEFAULT_AGI_LOOPS=12
MAX_RAM_BYTES=4096000

mkdir -p "$AI_HOME" "$PROJECTS_DIR" "$TMP_DIR" "$SWAP_DIR" "$DOWNLOADS_DIR" "$OUTPUTS_DIR" "$LOG_DIR"

# === COLORS / ICONS ===
ICON_INFO="ℹ️"; ICON_WARN="⚠️"; ICON_ERROR="❌"; ICON_SUCCESS="✅"; ICON_TASK="📝"; ICON_TRADE="💰"
log_info()  { printf "%b\n" "\e[38;5;81m$ICON_INFO [INFO] $*\e[0m"; }
log_warn()  { printf "%b\n" "\e[38;5;214m$ICON_WARN [WARN] $*\e[0m"; }
log_error() { printf "%b\n" "\e[38;5;196m$ICON_ERROR [ERROR] $*\e[0m"; }
log_ok()    { printf "%b\n" "\e[38;5;46m$ICON_SUCCESS [OK] $*\e[0m"; }
log_task()  { printf "%b\n" "\e[38;5;201m$ICON_TASK [TASK] $*\e[0m"; }
log_trade() { printf "%b\n" "\e[38;5;33m$ICON_TRADE [TRADE] $*\e[0m"; }

# === DATABASE HELPERS ===
sqlite_exec() { sqlite3 "$1" "$2"; }
sqlite_escape() { printf "%s" "$1" | sed "s/'/''/g"; }

init_databases() {
    sqlite_exec "$CORE_DB" "
        CREATE TABLE IF NOT EXISTS memories(id INTEGER PRIMARY KEY,prompt_hash TEXT UNIQUE,prompt TEXT,response_ref TEXT,created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
        CREATE TABLE IF NOT EXISTS tool_logs(id INTEGER PRIMARY KEY,task_id TEXT,tool_name TEXT,args TEXT,result TEXT,created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
        CREATE TABLE IF NOT EXISTS agi_loops(id INTEGER PRIMARY KEY,task_id TEXT,loop_number INTEGER,model TEXT,input TEXT,output TEXT,status TEXT DEFAULT 'completed',created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
        CREATE TABLE IF NOT EXISTS mindflow(id INTEGER PRIMARY KEY,task_id TEXT,node_id TEXT,parent_id TEXT,model TEXT,content TEXT,created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
    "
    sqlite_exec "$TASK_DB" "
        CREATE TABLE IF NOT EXISTS projects(hash TEXT PRIMARY KEY,path TEXT NOT NULL,ts DATETIME DEFAULT CURRENT_TIMESTAMP);
        CREATE TABLE IF NOT EXISTS file_hashes(project_hash TEXT,file_path TEXT,file_hash TEXT,mime_type TEXT,rehashed INTEGER DEFAULT 0,PRIMARY KEY(project_hash,file_path));
        CREATE TABLE IF NOT EXISTS events(id INTEGER PRIMARY KEY AUTOINCREMENT,ts DATETIME DEFAULT CURRENT_TIMESTAMP,type TEXT,data TEXT);
    "
    if [[ ! -f "$HMAC_SECRET_KEY" ]]; then
        openssl rand -hex 32 > "$HMAC_SECRET_KEY"
        chmod 600 "$HMAC_SECRET_KEY"
    fi
}

# === HASHING ===
hash_string() { printf "%s" "$1" | sha256sum | awk '{print $1}'; }
hash_file() { sha256sum "$1" | awk '{print $1}'; }

# === WALLET BIP39 ===
wallet_connect_bip39() {
    local mnemonic="$1"
    if [[ -z "$mnemonic" ]]; then log_warn "Mnemonic required"; return 1; fi
    local id="wallet_$(hash_string "${mnemonic:0:16}")"
    log_info "Wallet connected (BIP39 derived ID: $id)"
    echo "$id"
}

# === FILE / URL / ZIP / MIME ===
process_zip() { local zipfile="$1" dest="$2"; mkdir -p "$dest"; unzip -o "$zipfile" -d "$dest"; log_ok "Extracted ZIP $zipfile -> $dest"; }
download_url() { local url="$1" dest="$2"; mkdir -p "$(dirname "$dest")"; curl -sSL "$url" -o "$dest"; log_ok "Downloaded $url -> $dest"; }
process_file() { local file="$1"; local mime; mime=$(file --mime-type -b "$file"); case "$mime" in text/*) log_info "Text file: $file";; image/*) log_info "Image file: $file";; application/zip) process_zip "$file" "$PROJECTS_DIR/tmp/$(basename "$file" .zip)";; *) log_warn "Unknown MIME $mime for $file";; esac; }

# --- RECURSIVE PROJECT SCAN & REGEX ---
scan_project() {
    local project_path="$1"
    local project_hash=$(hash_string "$project_path")
    find "$project_path" -type f | while read -r f; do
        local fh=$(hash_file "$f")
        local mime=$(file --mime-type -b "$f")
        sqlite_exec "$TASK_DB" "INSERT OR REPLACE INTO file_hashes(project_hash,file_path,file_hash,mime_type) VALUES('$project_hash','$(sqlite_escape "$f")','$fh','$mime');"
        process_file "$f"
    done
}

# --- CODE UTILITIES ---
format_code() { local file="$1"; if [[ "$file" =~ \.js$|\.ts$ ]]; then npx prettier --write "$file" && npx eslint --fix "$file"; log_ok "Formatted & linted $file"; fi; }

# --- LONG-RUNNING TASKS ---
build_webkit() { mkdir -p "$TMP_DIR/webkit"; cd "$TMP_DIR/webkit"; git clone https://github.com/WebKit/WebKit.git .; ./Tools/Scripts/build-webkit --no-clean; log_ok "WebKit build completed"; }

# --- AGI STREAMING & MINDFLOW ---
run_worker_streaming() { local model="$1" user_prompt="$2" out_pipe="$3"; python3 - <<END
import sys, time
for i in range(30):
    sys.stdout.write(f"[{model}][token{i:02d}]\\n")
    sys.stdout.flush()
    time.sleep(0.02)
sys.stdout.write(f"[{model}][FINAL_ANSWER]\\n")
sys.stdout.flush()
END
}

run_agi_mindflow() {
    local prompt="$*"
    local task_id=$(hash_string "$prompt$(date +%s%N)" | cut -c1-16)
    mkdir -p "$TMP_DIR/task-$task_id/outputs"
    log_ok "AGI Mindflow task $task_id initialized"

    local loop_num=0 MAX_LOOPS=$DEFAULT_AGI_LOOPS active=1
    while (( loop_num<MAX_LOOPS && active )); do
        loop_num=$((loop_num+1))
        active=0
        declare -A out_files
        for model in "${MODELS[@]}"; do
            local outf="$TMP_DIR/task-$task_id/${model}_loop${loop_num}.out"
            out_files["$model"]="$outf"
            run_worker_streaming "$model" "$prompt" "$outf" &
        done
        wait
        local fused=""
        for model in "${MODELS[@]}"; do
            local file="${out_files[$model]}"
            local content=$(cat "$file")
            fused+=$'\n'"[$model] $content"
            local node_id=$(hash_string "$task_id|$loop_num|$model")
            sqlite_exec "$CORE_DB" "INSERT INTO mindflow(task_id,node_id,parent_id,model,content) VALUES('$(sqlite_escape "$task_id")','$node_id','','$(sqlite_escape "$model")','$(sqlite_escape "$content")');"
            if grep -q "\[FINAL_ANSWER\]" <<<"$content"; then active=0; fi
        done
        printf "%s\n" "$fused" > "$TMP_DIR/task-$task_id/outputs/mindmap_loop${loop_num}.txt"
    done
    log_ok "AGI Mindflow task $task_id completed"
    cat "$TMP_DIR/task-$task_id/outputs/mindmap_loop${loop_num}.txt"
}

# --- DISPATCHER ---
main() {
    init_databases
    local cmd="${1:-help}"; shift || true
    case "$cmd" in
        agi) run_agi_mindflow "$*" ;;
        wallet) case "${1:-}" in connect) wallet_connect_bip39 "$2" ;; *) log_warn "wallet command: connect <mnemonic>" ;; esac ;;
        scan) scan_project "$1" ;;
        format) format_code "$1" ;;
        download) download_url "$1" "$2" ;;
        unzip) process_zip "$1" "$2" ;;
        webkit) build_webkit ;;
        help|--help) echo "AGI Platform v1.20 - Full Features CLI" ;;
        *) log_warn "Unknown command: $cmd" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi
