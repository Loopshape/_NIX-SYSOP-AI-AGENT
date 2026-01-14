#!/bin/bash

# ============================================================================
# WSL Runtime AI Orchestration System - FIXED VERSION
# ============================================================================

set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly BASE_DIR="$HOME/.repository/wsl-runtime"
readonly AI_DIR="$HOME/_/ai"
readonly DB_FILE="$BASE_DIR/ai_memory.db"
readonly LOG_FILE="$BASE_DIR/ai_system.log"
readonly OLLAMA_HOST="http://localhost:11434"
readonly OLLAMA_MODEL="llama2"  # Changed to a model that actually exists

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 2π/8 Agent Definitions
declare -A AGENTS=(
    [0]="Analyzer"
    [1]="Reasoner" 
    [2]="Synthesizer"
    [3]="Validator"
    [4]="Optimizer"
    [5]="Integrator"
    [6]="Innovator"
    [7]="Coordinator"
)

# Initialize logging
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO") echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        *) echo "[$level] $message" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Safe SQL execution with error handling
sql_exec() {
    local query="$1"
    local result
    
    # Use a lock file to prevent concurrent database access
    local lock_file="$DB_FILE.lock"
    
    # Wait for lock with timeout (5 seconds)
    local timeout=5
    local start_time=$(date +%s)
    
    while [[ -f "$lock_file" ]]; do
        local current_time=$(date +%s)
        if (( current_time - start_time > timeout )); then
            log_message "ERROR" "Database lock timeout"
            return 1
        fi
        sleep 0.1
    done
    
    # Create lock file
    touch "$lock_file"
    
    # Execute query
    result=$(sqlite3 "$DB_FILE" "$query" 2>/dev/null) || {
        log_message "ERROR" "SQL query failed: $query"
        rm -f "$lock_file"
        return 1
    }
    
    # Remove lock file
    rm -f "$lock_file"
    
    echo "$result"
}

# Initialize SQLite3 database
init_database() {
    if [[ ! -f "$DB_FILE" ]]; then
        log_message "INFO" "Initializing SQLite3 database..."
        
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$DB_FILE")"
        
        sql_exec <<EOF
CREATE TABLE IF NOT EXISTS agent_memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id INTEGER NOT NULL,
    agent_name TEXT NOT NULL,
    prompt TEXT NOT NULL,
    response TEXT NOT NULL,
    tokens_used INTEGER,
    confidence REAL,
    angle_position REAL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS memory_clusters (
    cluster_id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT,
    agent_pattern TEXT,
    token_count INTEGER,
    last_accessed DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS system_state (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agent_memories ON agent_memories(agent_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_memory_clusters ON memory_clusters(last_accessed);

INSERT OR IGNORE INTO system_state (key, value) VALUES 
    ('cycle_phase', '0'),
    ('total_tokens', '0'),
    ('active_agents', '0'),
    ('system_version', '2.1.0');
EOF
        
        log_message "INFO" "Database initialized at $DB_FILE"
    fi
}

# Check Ollama status
check_ollama() {
    if curl -s "$OLLAMA_HOST/api/tags" > /dev/null 2>&1; then
        log_message "INFO" "Ollama is running on $OLLAMA_HOST"
        return 0
    else
        log_message "WARN" "Ollama is not running. Using simulated responses."
        return 1
    fi
}

# Calculate agent position in 2π cycle
calculate_agent_position() {
    local agent_id="$1"
    local total_agents=8
    local pi=3.141592653589793
    
    # Calculate position in radians
    local position=$(echo "scale=4; 2 * $pi * $agent_id / $total_agents" | bc)
    echo "$position"
}

# Escape strings for SQL
escape_string() {
    local string="$1"
    # Replace single quotes with two single quotes for SQL
    echo "$string" | sed "s/'/''/g"
}

# Get agent description based on ID
get_agent_description() {
    local agent_id="$1"
    case "$agent_id" in
        0) echo "You are the Analyzer agent. Break down complex problems into components. Focus on structural analysis and identifying core elements." ;;
        1) echo "You are the Reasoner agent. Apply logical deduction and inference. Focus on cause-effect relationships and logical consistency." ;;
        2) echo "You are the Synthesizer agent. Combine ideas creatively. Focus on novel combinations and cross-domain thinking." ;;
        3) echo "You are the Validator agent. Check accuracy and consistency. Focus on error detection and quality assurance." ;;
        4) echo "You are the Optimizer agent. Improve efficiency and performance. Focus on resource optimization and process improvement." ;;
        5) echo "You are the Integrator agent. Connect disparate concepts. Focus on system integration and holistic understanding." ;;
        6) echo "You are the Innovator agent. Generate novel solutions. Focus on creative problem-solving and breakthrough thinking." ;;
        7) echo "You are the Coordinator agent. Orchestrate all agents. Focus on workflow management and result synthesis." ;;
    esac
}

# Execute prompt through a specific agent
execute_agent_prompt() {
    local agent_id="$1"
    local prompt="$2"
    local agent_name="${AGENTS[$agent_id]}"
    local position=$(calculate_agent_position "$agent_id")
    local description=$(get_agent_description "$agent_id")
    
    log_message "DEBUG" "Agent $agent_id ($agent_name) processing at position $position"
    
    # Escape the prompt for safe handling
    local escaped_prompt=$(escape_string "$prompt")
    
    # Prepare context
    local context="$description"
    
    # Try to call Ollama
    local response_text=""
    local tokens_used=0
    
    if check_ollama; then
        # Prepare the prompt for Ollama
        local ollama_prompt="Context: $context\n\nTask: $prompt\n\nProvide a concise response from your specific perspective:"
        
        # Call Ollama API
        local ollama_response=$(curl -s -X POST "$OLLAMA_HOST/api/generate" \
            -H "Content-Type: application/json" \
            -d "{
                \"model\": \"$OLLAMA_MODEL\",
                \"prompt\": \"$ollama_prompt\",
                \"stream\": false,
                \"options\": {
                    \"temperature\": 0.$((70 + agent_id * 3)),
                    \"num_predict\": 150
                }
            }" 2>/dev/null || echo "{}")
        
        # Extract response
        response_text=$(echo "$ollama_response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('response', 'No response from Ollama').replace('\"', '').replace(\"'\", '').strip())
except:
    print('Error parsing Ollama response')
" 2>/dev/null || echo "Agent ${agent_name}: Processing '${prompt:0:50}...'")
        
        tokens_used=$(echo "$ollama_response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('total_duration', 100))
except:
    print('100')
" 2>/dev/null || echo "100")
    else
        # Fallback simulated response
        local angles=("π/4" "π/2" "3π/4" "π" "5π/4" "3π/2" "7π/4" "2π")
        local angle=${angles[$agent_id]}
        
        response_text="Agent ${agent_name} (${angle}) analysis: ${prompt:0:100}... This requires ${agent_name,,} approach considering the ${angle} phase position. Key insights would focus on $(echo ${agent_name,,} | sed 's/izer//g')-oriented solutions."
        tokens_used=$((100 + agent_id * 20))
    fi
    
    # Escape response for SQL
    local escaped_response=$(escape_string "$response_text")
    
    # Calculate confidence based on position and agent role
    local confidence=$(echo "scale=2; 0.75 + 0.25 * (1 - $agent_id / 8)" | bc)
    
    # Store in database with safe SQL
    sql_exec "INSERT INTO agent_memories (agent_id, agent_name, prompt, response, tokens_used, confidence, angle_position) 
              VALUES ($agent_id, '$agent_name', '$escaped_prompt', '$escaped_response', $tokens_used, $confidence, $position);"
    
    # Return response in JSON format
    echo "{\"agent_id\": $agent_id, \"agent_name\": \"$agent_name\", \"response\": \"$response_text\", \"position\": $position, \"confidence\": $confidence}"
}

# Parallel execution of all agents
parallel_reasoning() {
    local prompt="$1"
    local results=()
    local pids=()
    local temp_dir=$(mktemp -d)
    
    log_message "INFO" "Starting parallel reasoning with ${#AGENTS[@]} agents"
    
    # Update active agents count
    sql_exec "UPDATE system_state SET value = '${#AGENTS[@]}' WHERE key = 'active_agents';"
    
    # Execute each agent in parallel
    for agent_id in "${!AGENTS[@]}"; do
        (
            local result=$(execute_agent_prompt "$agent_id" "$prompt")
            echo "$result" > "$temp_dir/agent_${agent_id}.json"
        ) &
        pids+=($!)
    done
    
    # Wait for all agents to complete
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
    
    # Collect results
    for agent_id in "${!AGENTS[@]}"; do
        if [[ -f "$temp_dir/agent_${agent_id}.json" ]]; then
            local result=$(cat "$temp_dir/agent_${agent_id}.json")
            results+=("$result")
        else
            # Fallback if agent failed
            local angle=$(calculate_agent_position "$agent_id")
            local name="${AGENTS[$agent_id]}"
            results+=("{\"agent_id\": $agent_id, \"agent_name\": \"$name\", \"response\": \"Failed to process\", \"position\": $angle, \"confidence\": 0.0}")
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Update active agents count back to 0
    sql_exec "UPDATE system_state SET value = '0' WHERE key = 'active_agents';"
    
    # Increment cycle phase
    local current_phase=$(sql_exec "SELECT value FROM system_state WHERE key = 'cycle_phase';")
    local new_phase=$(( (current_phase + 1) % ${#AGENTS[@]} ))
    sql_exec "UPDATE system_state SET value = '$new_phase' WHERE key = 'cycle_phase';"
    
    # Create memory cluster
    local cluster_desc=$(echo "$prompt" | cut -c1-50 | sed "s/'/''/g")
    sql_exec "INSERT INTO memory_clusters (description, agent_pattern, token_count) 
              VALUES ('$cluster_desc', '0-7', ${#AGENTS[@]} * 100);"
    
    log_message "INFO" "Parallel reasoning complete. Cycle phase: $new_phase"
    
    # Return JSON formatted results
    echo "{"
    echo "  \"status\": \"success\","
    echo "  \"prompt\": \"$prompt\","
    echo "  \"cycle_phase\": $new_phase,"
    echo "  \"total_agents\": ${#AGENTS[@]},"
    echo "  \"agents\": ["
    
    for i in "${!results[@]}"; do
        if [[ $i -eq $(( ${#results[@]} - 1 )) ]]; then
            echo "    ${results[$i]}"
        else
            echo "    ${results[$i]},"
        fi
    done
    
    echo "  ]"
    echo "}"
}

# Memory recall function
recall_memory() {
    local query="$1"
    local limit="${2:-10}"
    
    log_message "INFO" "Searching memory for: $query"
    
    # Escape query for SQL
    local escaped_query=$(escape_string "$query")
    
    # Query database
    sql_exec "SELECT 
        agent_name,
        substr(prompt, 1, 100) as prompt_preview,
        substr(response, 1, 200) as response_preview,
        confidence,
        timestamp,
        angle_position
    FROM agent_memories 
    WHERE prompt LIKE '%$escaped_query%' OR response LIKE '%$escaped_query%'
    ORDER BY timestamp DESC
    LIMIT $limit;" | while IFS='|' read -r agent_name prompt_preview response_preview confidence timestamp angle_position; do
        echo "Agent: $agent_name"
        echo "Prompt: $prompt_preview"
        echo "Response: $response_preview"
        echo "Confidence: $confidence | Time: $timestamp | Angle: $angle_position"
        echo "---"
    done
}

# Get system statistics
get_system_stats() {
    echo "{"
    echo "  \"system_stats\": {"
    
    # Get individual stats
    local cycle_phase=$(sql_exec "SELECT value FROM system_state WHERE key = 'cycle_phase';")
    local total_tokens=$(sql_exec "SELECT value FROM system_state WHERE key = 'total_tokens';")
    local active_agents=$(sql_exec "SELECT value FROM system_state WHERE key = 'active_agents';")
    local total_memories=$(sql_exec "SELECT COUNT(*) FROM agent_memories;")
    local tokens_used_total=$(sql_exec "SELECT SUM(tokens_used) FROM agent_memories;")
    local unique_agents=$(sql_exec "SELECT COUNT(DISTINCT agent_id) FROM agent_memories;")
    
    echo "    \"cycle_phase\": \"$cycle_phase\","
    echo "    \"total_tokens\": \"$total_tokens\","
    echo "    \"active_agents\": \"$active_agents\","
    echo "    \"total_memories\": \"$total_memories\","
    echo "    \"tokens_used_total\": \"${tokens_used_total:-0}\","
    echo "    \"unique_agents\": \"$unique_agents\""
    echo "  }"
    echo "}"
}

# Cleanup old memories
cleanup_memories() {
    local days_to_keep="${1:-30}"
    
    log_message "INFO" "Cleaning up memories older than $days_to_keep days"
    
    local deleted=$(sql_exec "DELETE FROM agent_memories 
                              WHERE date(timestamp) < date('now', '-$days_to_keep days');
                              SELECT changes();")
    
    log_message "INFO" "Deleted $deleted old memories"
}

# Export database for backup
export_database() {
    local backup_dir="$BASE_DIR/backups"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$backup_dir/ai_memory_$timestamp.db"
    
    mkdir -p "$backup_dir"
    cp "$DB_FILE" "$backup_file"
    
    log_message "INFO" "Database exported to $backup_file"
    
    # Keep only last 5 backups
    ls -t "$backup_dir"/*.db 2>/dev/null | tail -n +6 | xargs -r rm -f
}

# List available Ollama models
list_models() {
    if check_ollama; then
        curl -s "$OLLAMA_HOST/api/tags" | python3 -c "
import json, sys
try:
    models = json.load(sys.stdin).get('models', [])
    for model in models:
        print(f\"{model['name']} ({model.get('size', 'N/A')})\")
except:
    print('Could not fetch models')
"
    else
        echo "Ollama not available"
    fi
}

# Main execution flow
main() {
    # Parse command line arguments
    local command="${1:-help}"
    
    # Initialize system
    init_database
    
    case "$command" in
        "reason")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 reason \"<prompt>\""
                exit 1
            fi
            parallel_reasoning "${2}"
            ;;
        
        "recall")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 recall \"<query>\" [limit]"
                exit 1
            fi
            recall_memory "${2}" "${3:-10}"
            ;;
        
        "stats")
            get_system_stats
            ;;
        
        "cleanup")
            cleanup_memories "${2:-30}"
            ;;
        
        "export")
            export_database
            ;;
        
        "status")
            echo "=== WSL Runtime AI System Status ==="
            echo "Database: $DB_FILE"
            echo "Log file: $LOG_FILE"
            echo "Active agents: ${#AGENTS[@]}"
            
            if check_ollama; then
                echo "Ollama: Running ($OLLAMA_MODEL)"
            else
                echo "Ollama: Not running (using simulated responses)"
            fi
            
            echo ""
            echo "System Statistics:"
            get_system_stats | python3 -c "
import json, sys
data = json.load(sys.stdin)['system_stats']
for key, value in data.items():
    print(f'  {key}: {value}')
"
            ;;
        
        "agents")
            echo "2π/8 Agent System:"
            for id in "${!AGENTS[@]}"; do
                local pos=$(calculate_agent_position "$id")
                local pi_ratio=$(echo "scale=2; $pos / 3.14159" | bc)
                printf "  Agent %d: %-15s Position: %.4f (%.2fπ)\n" \
                       "$id" "${AGENTS[$id]}" "$pos" "$pi_ratio"
            done
            ;;
        
        "models")
            echo "Available Ollama models:"
            list_models
            ;;
        
        "help"|*)
            echo "WSL Runtime AI Orchestration System v2.1"
            echo "========================================="
            echo "Environment: WSL1 Debian | 8GB RAM | 500GB HDD"
            echo "Architecture: 2π/8-agent system with SQLite memory"
            echo ""
            echo "Commands:"
            echo "  reason \"<prompt>\"    - Execute parallel reasoning with all 8 agents"
            echo "  recall \"<query>\"     - Search memory database"
            echo "  stats                - Get system statistics"
            echo "  cleanup [days]       - Cleanup old memories (default: 30 days)"
            echo "  export               - Export database backup"
            echo "  status               - Check system status"
            echo "  agents               - List all agents with positions"
            echo "  models               - List available Ollama models"
            echo "  help                 - Show this help"
            echo ""
            echo "Example:"
            echo "  $0 reason \"Analyze this code and suggest improvements\""
            ;;
    esac
}

# Trap signals for cleanup
trap 'log_message "WARN" "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
