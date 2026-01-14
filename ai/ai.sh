#!/usr/bin/env bash
# =============================================================================
#  WSL Runtime AI Orchestration System – v3.2 (Batch Operators)
# =============================================================================
#  Features:
#   • 8-Agent "Shifted Entropy" Model: Cube, Core, Loop, Wave, Sign, Line, Coin, Work
#   • Advanced Batch Operators (* . + - :) 
#   • Unrestricted Batch File Processing (JSON/Text)
#   • Universal Input Parsing: Prompt / File / URL / Hash
#   • Dynamic Temperature & Token Budget per Phase
#   • Embedding‑based Memory Recall (Semantic Context)
#   • SQLite Memory & Locking
#   • Parallel Execution (Job Pool)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# -------------------------------------------------------------------------
#   0️⃣  Configuration & constants
# -------------------------------------------------------------------------

# Base directories
readonly BASE_DIR="${HOME}/.repository/wsl-runtime"
readonly AI_DIR="${HOME}/_/ai"
readonly DB_FILE="${BASE_DIR}/ai_memory.db"
readonly LOG_FILE="${BASE_DIR}/ai_system.log"

# Load optional user configuration
if [[ -f "${HOME}/.ai_config" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.ai_config"
fi

# Core constants
readonly OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
readonly OLLAMA_MODEL="${OLLAMA_MODEL:-llama3}"
readonly EMBED_MODEL="${EMBED_MODEL:-$OLLAMA_MODEL}"
readonly MAX_CONCURRENT_AGENTS="${MAX_CONCURRENT_AGENTS:-4}"
readonly LOG_ROTATE_KEEP="${LOG_ROTATE_KEEP:-5}"
readonly LOG_ROTATE_SIZE="${LOG_ROTATE_SIZE:-5242880}"   # 5 MiB default
readonly MEMORY_TOP_K="${MEMORY_TOP_K:-3}"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Agent definitions (2π/8 Shifted Entropy Model)
declare -A AGENTS=(
    [0]="Cube"
    [1]="Core"
    [2]="Loop"
    [3]="Wave"
    [4]="Sign"
    [5]="Line"
    [6]="Coin"
    [7]="Work"
)

# -------------------------------------------------------------------------
#   1️⃣  Logging (with rotation)
# -------------------------------------------------------------------------
log_message() {
    local level="$1" message="$2"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        INFO)  printf "${GREEN}[INFO]${NC} %s\n" "$message" ;;
        WARN)  printf "${YELLOW}[WARN]${NC} %s\n" "$message" ;;
        ERROR) printf "${RED}[ERROR]${NC} %s\n" "$message" ;;
        DEBUG) printf "${BLUE}[DEBUG]${NC} %s\n" "$message" ;;
        *)     printf "[%s] %s\n" "$level" "$message" ;;
    esac

    # Rotate if needed
    if [[ -f "$LOG_FILE" && $(stat -c%s "$LOG_FILE") -ge $LOG_ROTATE_SIZE ]]; then
        for ((i=LOG_ROTATE_KEEP-1; i>=0; i--)); do
            if [[ -f "${LOG_FILE}.${i}" ]]; then
                mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i+1))"
            fi
        done
        mv "$LOG_FILE" "${LOG_FILE}.0"
    fi

    printf "[%s] [%s] %s\n" "$ts" "$level" "$message" >> "$LOG_FILE"
}

# -------------------------------------------------------------------------
#   2️⃣  SQLite helpers – flock for atomic access
# -------------------------------------------------------------------------
_sql_lock() {
    exec 200>"$DB_FILE.lock"
    flock -n 200 && return 0 || return 1
}
_sql_unlock() { exec 200>&-; }

sql_exec() {
    local query="${1:-}"
    if [[ -z "$query" ]]; then
        query=$(cat)
    fi

    local waited=0
    while ! _sql_lock; do
        (( waited++ )) && (( waited > 50 )) && { 
            log_message "ERROR" "Failed to acquire DB lock after 5s"
            return 1
        }
        sleep 0.1
    done

    sqlite3 "$DB_FILE" "$query"
    local ret=$?
    _sql_unlock
    return $ret
}

# -------------------------------------------------------------------------
#   3️⃣  DB schema + init
# -------------------------------------------------------------------------
init_database() {
    mkdir -p "$(dirname "$DB_FILE")"
    
    sql_exec <<'SQL'
PRAGMA journal_mode=WAL;
BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS agent_memories (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id      INTEGER NOT NULL,
    agent_name    TEXT    NOT NULL,
    prompt        TEXT    NOT NULL,
    response      TEXT    NOT NULL,
    tokens_used   INTEGER,
    confidence    REAL,
    angle_position REAL,
    timestamp     DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS memory_clusters (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    description   TEXT,
    embedding     BLOB,
    token_count   INTEGER,
    last_accessed DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS system_state (
    key         TEXT PRIMARY KEY,
    value       TEXT,
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_agent_memories ON agent_memories (agent_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_memory_clusters ON memory_clusters (last_accessed);
INSERT OR IGNORE INTO system_state (key,value) VALUES
    ('cycle_phase','0'),
    ('total_tokens','0'),
    ('active_agents','0'),
    ('system_version','3.2.0');
COMMIT;
SQL
}

# -------------------------------------------------------------------------
#   4️⃣  Ollama & Input helpers
# -------------------------------------------------------------------------
_check_ollama() {
    curl -s "${OLLAMA_HOST}/api/tags" >/dev/null 2>&1 && return 0 || return 1
}

_ollama_post() {
    local endpoint="$1" payload="$2"
    local attempt=0 delay=1
    while (( attempt < 3 )); do
        local resp
        resp=$(curl -s -X POST "${OLLAMA_HOST}${endpoint}" \
                -H "Content-Type: application/json" \
                -d "$payload" --max-time 30) && { 
            echo "$resp"
            return 0
        } || {
            ((attempt++))
            log_message "WARN" "Ollama request failed (attempt $attempt); retry in ${delay}s"
            sleep $delay
            ((delay*=2))
        }
    done
    log_message "ERROR" "All Ollama attempts failed for $endpoint"
    return 1
}

embed_text() {
    local txt="$1"
    local payload
    payload=$(jq -nc --arg txt "$txt" --arg model "$EMBED_MODEL" 
            '{model:$model, input:$txt}')
    _ollama_post "/api/embeddings" "$payload" | jq -r '.embedding // empty'
}

_cosine_similarity() {
    python3 - <<'PY' "$@"
import sys, base64, struct, math
def decode(b64):
    data = base64.b64decode(b64)
    return struct.unpack("<%df" % (len(data)//4), data)
a = decode(sys.argv[1])
b = decode(sys.argv[2])
dot = sum(x*y for x,y in zip(a,b))
norm_a = math.sqrt(sum(x*x for x in a))
norm_b = math.sqrt(sum(y*y for y in b))
print(dot/(norm_a*norm_b) if norm_a and norm_b else 0.0)
PY
}

# -------------------------------------------------------------------------
#   Input Resolution Helpers
# -------------------------------------------------------------------------
resolve_input() {
    local input="$1"

    if [[ "$input" =~ ^https?:// ]]; then
        log_message "INFO" "Input detected as URL: $input"
        local content
        content=$(curl -sL --max-time 10 "$input" || echo "Error fetching URL")
        echo "$content" | sed 's/<[^>]*>//g' | tr -s ' \t\n' ' ' | cut -c 1-4000
        return
    fi

    if [[ -f "$input" ]]; then
        log_message "INFO" "Input detected as file: $input"
        cat "$input"
        return
    fi

    if [[ "$input" =~ ^[a-fA-F0-9]{64}$ ]]; then
        log_message "INFO" "Input detected as Hash: $input"
        local memory
        memory=$(sql_exec "SELECT response FROM agent_memories WHERE prompt LIKE '%$input%' LIMIT 1;")
        if [[ -n "$memory" ]]; then
            echo "Recalling memory for hash $input: $memory"
        else
            echo "Hash $input found, but no direct memory link. Analyzing as ID."
        fi
        return
    fi

    echo "$input"
}

# -------------------------------------------------------------------------
#   5️⃣  Semantic memory recall
# -------------------------------------------------------------------------
retrieve_semantic_context() {
    local prompt="$1"
    local embed_b64
    embed_b64=$(embed_text "$prompt")
    [[ -z "$embed_b64" ]] && return 0

    sql_exec "SELECT id, description, embedding FROM memory_clusters;" |
    while IFS='|' read -r cid desc emb;
    do
        local sim
        sim=$(_cosine_similarity "$embed_b64" "$emb")
        echo -e "$sim\t$cid\t$desc"
    done | sort -nr | head -n "$MEMORY_TOP_K" | cut -f2- |
    while IFS=$'\t' read -r cid desc;
    do
        printf "%s\n" "$desc"
    done
}

# -------------------------------------------------------------------------
#   6️⃣  Agent temperature schedule
# -------------------------------------------------------------------------
calc_temperature() {
    local agent_id=$1
    local phase
    phase=$(sql_exec "SELECT value FROM system_state WHERE key='cycle_phase';")
    local phase_norm
    phase_norm=$(awk "BEGIN{printf \"%.4f\", $phase / ${#AGENTS[@]}}")
    local offset=$(awk "BEGIN{printf \"%.4f\", $agent_id / ${#AGENTS[@]}}")
    local angle
    angle=$(awk "BEGIN{printf \"%.4f\", 2*3.14159265*($phase_norm+$offset)}")
    local temp
    temp=$(awk "BEGIN{printf \"%.2f\", 0.6 + 0.3*sin($angle)}")
    echo "$temp"
}

# -------------------------------------------------------------------------
#   7️⃣  Core agent execution
# -------------------------------------------------------------------------
execute_agent() {
    local agent_id=$1 prompt="$2" full_context="$3"
    local agent_name="${AGENTS[$agent_id]}"
    local position
    position=$(awk "BEGIN{printf \"%.4f\", 2*3.14159265*$agent_id/${#AGENTS[@]}}")
    local temperature
    temperature=$(calc_temperature "$agent_id")
    local context
    context=$(retrieve_semantic_context "$prompt")

    local ollama_prompt
    if [[ -n "$context" ]]; then
        ollama_prompt="Context (semantic memory):\n${context}\n\nTask:\n${prompt}"
    else
        ollama_prompt="Task:\n${prompt}"
    fi
    
    case "$agent_name" in
        "Cube") ollama_prompt="[Role: Structural Analyzer] Analyze the dimensions and structure of: $ollama_prompt" ;;
        "Core") ollama_prompt="[Role: Central Logic] Identify the core truth and logic of: $ollama_prompt" ;;
        "Loop") ollama_prompt="[Role: Iterative Refiner] Look for patterns and cycles in: $ollama_prompt" ;;
        "Wave") ollama_prompt="[Role: Flow & Trend] Analyze the flow, trend, and variability of: $ollama_prompt" ;;
        "Sign") ollama_prompt="[Role: Semiotics & Meaning] Interpret the symbols and hidden meanings in: $ollama_prompt" ;;
        "Line") ollama_prompt="[Role: Linear Progression] Connect the dots and outline the sequence for: $ollama_prompt" ;;
        "Coin") ollama_prompt="[Role: Value & Probability] Assess the value, cost, and flip-side probabilities of: $ollama_prompt" ;;
        "Work") ollama_prompt="[Role: Action & Execution] Define the actionable steps and output for: $ollama_prompt" ;;
    esac

    local payload
    payload=$(jq -nc 
        --arg model "$OLLAMA_MODEL"
        --arg prompt "$ollama_prompt"
        --argjson temperature "$temperature"
        --argjson num_predict 256 
        '{model:$model, prompt:$prompt, stream:false,
          options:{temperature:$temperature, num_predict:$num_predict}}')

    local response tokens_used
    if _check_ollama; then
        local raw
        raw=$(_ollama_post "/api/generate" "$payload")
        response=$(jq -r '.response // empty' <<<"$raw")
        tokens_used=$(jq -r '.total_duration // 0' <<<"$raw")
    else
        response="(SIMULATED) $agent_name ($position rad) processed: ${prompt:0:50}..."
        tokens_used=$((100 + 10 * agent_id))
    fi

    local confidence
    confidence=$(awk "BEGIN{printf \"%.2f\", 0.9 - ($temperature-0.6)/2}")

    sql_exec "INSERT INTO agent_memories
        (agent_id, agent_name, prompt, response, tokens_used, confidence, angle_position)
        VALUES
        ($agent_id, '$agent_name', '$(escape_sql "$prompt")',
               '$(escape_sql "$response")', $tokens_used, $confidence, $position);"

    jq -nc 
        --argjson agent_id "$agent_id"
        --arg agent_name "$agent_name"
        --arg response "$response"
        --argjson position "$position"
        --argjson confidence "$confidence"
        --argjson tokens_used "$tokens_used"
        '{agent_id:$agent_id, agent_name:$agent_name, response:$response,
          position:$position, confidence:$confidence, tokens_used:$tokens_used}'
}

escape_sql() { sed "s/'/''/g" <<<"$1"; }

# -------------------------------------------------------------------------
#   Core Reasoning Logic (Single Task)
# -------------------------------------------------------------------------
process_single_task() {
    local raw_input="$1"
    
    local prompt
    prompt=$(resolve_input "$raw_input")
    
    if [[ -z "$prompt" ]]; then
        log_message "ERROR" "Input resolved to empty string. Skipping."
        return
    fi

    local temp_dir
    temp_dir=$(mktemp -d)

    log_message "INFO" "Starting [Cube-Core-Loop-Wave-Sign-Line-Coin-Work] cycle for: ${prompt:0:40}..."
    sql_exec "UPDATE system_state SET value='${#AGENTS[@]}' WHERE key='active_agents';"

    local pids=()
    for agent_id in "${!AGENTS[@]}"; do
        (
            execute_agent "$agent_id" "$prompt" "" > "$temp_dir/agent_${agent_id}.json"
        ) &
        pids+=($!)

        while (( ${#pids[@]} >= MAX_CONCURRENT_AGENTS )); do
            wait -n
            pids=($(jobs -pr))
        done
    done
    wait

    local workers_json=()
    for agent_id in "${!AGENTS[@]}"; do
        if [[ -s "$temp_dir/agent_${agent_id}.json" ]]; then
            workers_json+=("$(cat "$temp_dir/agent_${agent_id}.json")")
        else
            workers_json+=("{\"agent_id\":$agent_id,\"agent_name\":\"${AGENTS[$agent_id]}\",\"response\":\"[FAILED]\"}")
        fi
    done

    local joint_context
    joint_context=$(printf "%s\n" "${workers_json[@]}" | jq -r '"[" + .agent_name + "]: " + .response' | paste -sd'\n' -)
    local coordinator_prompt="[Role: Coordinator] Summarize the 8-agent analysis into a coherent conclusion.\nTask: $prompt\nAnalysis:\n$joint_context"
    
    local payload
    payload=$(jq -nc --arg model "$OLLAMA_MODEL" --arg prompt "$coordinator_prompt" 
            '{model:$model, prompt:$prompt, stream:false}')
    local coord_raw
    local coord_resp="Coordinator unavailable"
    if _check_ollama; then
        coord_raw=$(_ollama_post "/api/generate" "$payload")
        coord_resp=$(jq -r '.response // empty' <<<"$coord_raw")
    fi

    local new_phase
    new_phase=$(( ( $(sql_exec "SELECT value FROM system_state WHERE key='cycle_phase';") + 1 ) % ${#AGENTS[@]} ))
    sql_exec "UPDATE system_state SET value='$new_phase' WHERE key='cycle_phase';"
    sql_exec "UPDATE system_state SET value='0' WHERE key='active_agents';"

    rm -rf "$temp_dir"

    jq -nc 
        --arg prompt "$prompt"
        --argjson phase "$new_phase"
        --argjson workers "$(printf "%s\n" "${workers_json[@]}" | jq -s '.')"
        --arg coordinator "$coord_resp"
        '{status:"success", prompt:$prompt, cycle_phase:$phase,
          workers:$workers, coordinator:$coordinator}'
}

# -------------------------------------------------------------------------
#   9️⃣  Orchestrator – with Operator Dispatch
# -------------------------------------------------------------------------
parallel_reasoning() {
    local input="$1"

    # Operator Detection
    if [[ "$input" == "*"* ]]; then
        local rest="${input#* }"
        log_message "INFO" "Operator [*]: Recursive batch processing for '$rest'"
        find . -type f -not -path '*/.*' -not -path '*/node_modules/*' | while read -r file;
        do
             echo ">>> Processing File: $file"
             process_single_task "File: $file. Task: $rest"
        done
        return
    elif [[ "$input" == "."* ]]; then
        local rest="${input#. }"
        log_message "INFO" "Operator [.]: Flat batch processing for '$rest'"
        find . -maxdepth 1 -type f -not -path '*/.*' | while read -r file;
        do
             echo ">>> Processing File: $file"
             process_single_task "File: $file. Task: $rest"
        done
        return
    elif [[ "$input" == "+"* ]]; then
        # Format: +ext prompt...
        local no_plus="${input#+}"
        local ext="${no_plus%% *}"
        local rest="${no_plus#* }"
        log_message "INFO" "Operator [+]: Extension batch processing for '.$ext' with '$rest'"
        find . -type f -name "*.$ext" -not -path '*/.*' -not -path '*/node_modules/*' | while read -r file;
        do
             echo ">>> Processing File: $file"
             process_single_task "File: $file. Task: $rest"
        done
        return
    elif [[ "$input" == "-"* ]]; then
        local rest="${input#- }"
        # Format: - filename
        local target_file="${rest%% *}"
        if [[ -f "$target_file" ]]; then
            log_message "INFO" "Operator [-]: Enhanced suggestion for '$target_file'"
            local content
            content=$(cat "$target_file")
            process_single_task "Target File: $target_file\nContent:\n$content\n\nTask: Analyze this file and provide enhanced suggestions for improvements, refactoring, and error handling."
        else
            log_message "ERROR" "Operator [-]: Target file '$target_file' not found."
        fi
        return
    elif [[ "$input" == ":"* ]]; then
        local rest="${input#: }"
        # Format: : file1 file2 ... prompt
        local combined_content=""
        local prompt_start=0
        local accumulated_prompt=""
        
        read -ra words <<< "$rest"
        for word in "${words[@]}"; do
            if [[ -f "$word" && "$prompt_start" -eq 0 ]]; then
                combined_content+="--- File: $word ---\n$(cat "$word")\n\n"
            else
                prompt_start=1
                accumulated_prompt+="$word "
            fi
        done
        
        log_message "INFO" "Operator [:]: Combined context logic refactoring."
        process_single_task "Combined Context:\n$combined_content\n\nTask: $accumulated_prompt\nGoal: Analyze these combined files to refactor the workflow logic."
        return
    fi

    # Default fallback
    process_single_task "$input"
}


# -------------------------------------------------------------------------
#   Batch Processing
# -------------------------------------------------------------------------
process_batch() {
    local batch_file="$1"
    if [[ ! -f "$batch_file" ]]; then
        echo "Error: Batch file not found: $batch_file"
        exit 1
    fi

    log_message "INFO" "Processing batch file: $batch_file"

    # Check extension
    if [[ "$batch_file" =~ \.json$ ]]; then
        # JSON Mode: expect array of objects with "prompt" key
        local count
        count=$(jq '. | length' "$batch_file")
        echo "Found $count items in JSON batch."
        
        for ((i=0; i<count; i++)); do
            local item_prompt
            item_prompt=$(jq -r ".[${i}].prompt" "$batch_file")
            echo "Processing item $((i+1))/$count..."
            parallel_reasoning "$item_prompt"
            echo "---------------------------------------------------"
        done
    else
        # Line-by-line Text Mode
        local i=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            ((i++))
            [[ -z "$line" ]] && continue
            echo "Processing item $i..."
            parallel_reasoning "$line"
            echo "---------------------------------------------------"
        done < "$batch_file"
    fi
}

# -------------------------------------------------------------------------
#   🔟  Memory recall & Stats
# -------------------------------------------------------------------------
recall_memory() {
    local query="$1"
    local limit="${2:-10}"
    local esc_query
    esc_query=$(escape_sql "$query")

    sql_exec "SELECT agent_name, substr(prompt,1,60), substr(response,1,100), confidence
             FROM agent_memories
             WHERE prompt LIKE '%$esc_query%' OR response LIKE '%$esc_query%'
             ORDER BY timestamp DESC LIMIT $limit;" |
    while IFS='|' read -r agent p r c;
    do
        printf "[%s] (%.2f) Q: %s... A: %s...\n" "$agent" "$c" "$p" "$r"
    done
}

get_system_stats() {
    jq -nc --argjson stats "$(sql_exec "
        SELECT json_object(
            'cycle_phase', (SELECT value FROM system_state WHERE key='cycle_phase'),
            'total_memories', (SELECT COUNT(*) FROM agent_memories),
            'unique_agents', (SELECT COUNT(DISTINCT agent_id) FROM agent_memories)
        );
    ")" '$stats'
}

cleanup_memories() {
    local days="${1:-30}"
    sql_exec "DELETE FROM agent_memories WHERE date(timestamp) < date('now','-${days} days');"
    log_message "INFO" "Cleaned memories older than $days days."
}

export_database() {
    local backup_dir="${BASE_DIR}/backups"
    mkdir -p "$backup_dir"
    cp "$DB_FILE" "${backup_dir}/ai_memory_$(date '+%Y%m%d_%H%M%S').db"
}

list_models() {
    _check_ollama && curl -s "${OLLAMA_HOST}/api/tags" | jq -r '.models[].name' || echo "Ollama offline"
}

# -------------------------------------------------------------------------
#   1️⃣3️⃣  Main entry point
# -------------------------------------------------------------------------
main() {
    local cmd="${1:-help}"
    init_database

    case "$cmd" in
        reason)
            [[ $# -lt 2 ]] && { echo "Usage: $0 reason \"<prompt|op...>\""; exit 1; }
            parallel_reasoning "${2}"
            ;;

        batch)
            [[ $# -lt 2 ]] && { echo "Usage: $0 batch <file.json|file.txt>"; exit 1; }
            process_batch "${2}"
            ;;

        recall)
            [[ $# -lt 2 ]] && { echo "Usage: $0 recall \"<query>\" [limit]"; exit 1; }
            recall_memory "${2}" "${3:-10}"
            ;;

        stats)  get_system_stats ;;
        cleanup) cleanup_memories "${2:-30}" ;; 
        export) export_database ;; 
        
        status)
            echo "=== AI System Status (v3.2) ==="
            echo "Agents: ${AGENTS[*]}"
            echo "DB: $DB_FILE"
            echo "Cycle: $(sql_exec "SELECT value FROM system_state WHERE key='cycle_phase';") / 8"
            ;;

        agents)
            echo "2π/8 Shifted Entropy Agents:"
            for id in {0..7}; do
                echo "  [$id] ${AGENTS[$id]}"
            done
            ;;

        models) list_models ;;

        help|*)
            cat <<'EOF'
WSL Runtime AI Orchestration v3.2
================================
Commands:
  reason "<input>"       – Run 8-Agent cycle. Supports Operators:
                           "* <task>"      : Recursive batch (all files)
                           ". <task>"      : Flat batch (current folder)
                           "+<ext> <task>" : Extension batch (e.g. +py Check)
                           "- <file>"      : Enhanced file analysis
                           ": <f1> <f2> ..." : Combined logic refactoring
  batch <file>           – Process a JSON or Text batch file
  recall "<query>" [N]   – Search memory
  stats                  – Show JSON stats
  cleanup [days]         – Prune old memories
  export                 – Backup DB
  agents                 – List agents
  models                 – List Ollama models
EOF
            ;;
    esac
}

main "$@"
