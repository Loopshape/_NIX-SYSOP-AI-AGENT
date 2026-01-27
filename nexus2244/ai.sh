#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    
    case "$level" in
        INFO) echo -e "${GREEN}[INFO]${NC} $message" ;;
        WARN) echo -e "${YELLOW}[WARN]${NC} $message" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" ;;
        DEBUG) echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        *) echo "[$level] $message" ;;
    esac
}

# Ensure directories exist
mkdir -p entropy memory memory/backups ui

# Generate genesis hash
GENESIS=$(date +%s%N | sha256sum | cut -d' ' -f1)
PROMPT="${*:-No prompt provided}"

log "INFO" "NEXUS-2244 Cognitive Kernel Initializing..."
log "INFO" "Genesis Hash: $GENESIS"
log "INFO" "Prompt: $PROMPT"

# Initialize memory
echo "{ \"genesis\": \"$GENESIS\", \"timestamp\": \"$(date -Iseconds)\", \"prompt\": \"$PROMPT\" }" > memory/memory.json

# Load mind files if they exist
load_mind_files() {
    local mind_files=("mindmap.txt" "mindset.txt" "mindbend.txt")
    local loaded_content=""
    
    for file in "${mind_files[@]}"; do
        if [[ -f "$HOME/ai/$file" ]]; then
            log "INFO" "Loading mind file: $file"
            loaded_content+="$(cat "$HOME/ai/$file")\n\n"
        fi
    done
    
    if [[ -n "$loaded_content" ]]; then
        echo -e "# PRIOR KNOWLEDGE\n$loaded_content" > entropy/prior_knowledge.txt
    fi
}

load_mind_files

# Define agents with enhanced models
declare -A AGENTS
AGENTS[coder]="deepseek-coder"
AGENTS[agi]="deepseek-r1"
AGENTS[nemodian]="wave"
AGENTS[sysop]="llama3.1"
AGENTS[cube]="gemma3:1b"
AGENTS[core]="deepseek-v3.1:671b-cloud"
AGENTS[loop]="loop:latest"
AGENTS[line]="line:latest"
AGENTS[wave]="qwen3-vl:2b"
AGENTS[coin]="stable-code:latest"
AGENTS[code]="phi:2.7b"
AGENTS[work]="deepseek-v3.1:671b-cloud"

# 2π/8 phase rotation
declare -a PHASE_ORDER=(coder agi nemodian sysop cube core loop line wave coin code work)
PHASE_INDEX=$(( $(date +%s) % ${#PHASE_ORDER[@]} ))

# Function to stream agent output
stream_agent() {
    local name="$1"
    local model="$2"
    local phase_offset="$3"
    
    log "INFO" "Starting agent: $name (model: $model, phase: $phase_offset)"
    
    # Create unique stream file
    local stream_file="entropy/${name}_${GENESIS}.stream"
    local hash_file="entropy/${name}_${GENESIS}.hash"
    
    # Check if model exists
    if ! ollama list | grep -q "$model"; then
        log "WARN" "Model $model not found, pulling..."
        ollama pull "$model" &
    fi
    
    # Stream from Ollama
    ollama run "$model" "$PROMPT" --stream 2>/dev/null | \
    while IFS= read -r token; do
        # Skip empty tokens
        [[ -z "$token" ]] && continue
        
        # Append to stream file
        echo "$token" >> "$stream_file"
        
        # Generate hashes
        local sha=$(echo -n "$token" | sha256sum | cut -d' ' -f1)
        local md5=$(echo -n "$sha" | md5sum | cut -d' ' -f1)
        
        # Store hash
        echo "$sha" >> "$hash_file"
        
        # Broadcast via Node.js
        node -e "
            import('${PWD}/server.js').then(module => {
                const { broadcast, generateHash } = module;
                const hashes = { md5: '$md5', sha256: '$sha', genesis: '$GENESIS' };
                broadcast('$name', '$token', hashes, $phase_offset);
            }).catch(err => console.error('Broadcast error:', err));
        " 2>/dev/null &
        
        # Small delay to prevent overwhelming
        sleep 0.01
    done
    
    # Process completed stream
    if [[ -f "$stream_file" ]]; then
        log "DEBUG" "Processing $name stream with vector engine"
        
        # Create vector embedding
        cat "$stream_file" | node vector.js 2>/dev/null || true
        
        # Calculate entropy
        local token_count=$(wc -w < "$stream_file" 2>/dev/null || echo "0")
        local unique_tokens=$(tr ' ' '\n' < "$stream_file" | sort -u | wc -l 2>/dev/null || echo "0")
        local entropy=$(echo "scale=4; $unique_tokens / ($token_count + 1)" | bc 2>/dev/null || echo "0.0")
        
        # Store entropy
        echo "$entropy" > "entropy/${name}_${GENESIS}.entropy"
        
        log "INFO" "Agent $name completed: $token_count tokens, entropy: $entropy"
    fi
}

# Goal engine functions
initialize_goals() {
    log "INFO" "Initializing goal engine..."
    
    node -e "
        import('sqlite3').then(sqlite3 => {
            const db = new sqlite3.Database('memory/goals.db');
            db.run(`
                CREATE TABLE IF NOT EXISTS goals (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    description TEXT NOT NULL,
                    priority INTEGER DEFAULT 1,
                    status TEXT DEFAULT 'active',
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
                    success_score REAL DEFAULT 0.0,
                    parent_goal INTEGER,
                    hash TEXT UNIQUE
                )
            ");
            db.close();
        });
    " 2>/dev/null &
}

create_goal() {
    local description="$1"
    local priority="${2:-1}"
    
    node -e "
        const crypto = require('crypto');
        const db = require('sqlite3').Database('memory/goals.db');
        const hash = crypto.createHash('md5').update('$description').digest('hex');
        
        db.run(
            'INSERT OR IGNORE INTO goals (description, priority, hash) VALUES (?, ?, ?)',
            ['$description', $priority, hash],
            function(err) {
                if (!err) console.log('Goal created:', hash);
                db.close();
            }
        );
    " 2>/dev/null
}

# Start goal engine
initialize_goals

# Create initial goal from prompt
if [[ "$PROMPT" != "No prompt provided" ]]; then
    create_goal "$PROMPT" 1
fi

# Main execution loop
log "INFO" "Starting 2π/8 phase rotation..."
log "INFO" "Phase index: $PHASE_INDEX"

# Start agents with phase offsets
declare -a pids=()
for i in "${!PHASE_ORDER[@]}"; do
    agent="${PHASE_ORDER[$i]}"
    model="${AGENTS[$agent]}"
    
    if [[ -n "$model" ]]; then
        # Calculate phase offset (0.0 to 1.0)
        phase_offset=$(echo "scale=2; $i / ${#PHASE_ORDER[@]}" | bc)
        
        # Start agent in background
        stream_agent "$agent" "$model" "$phase_offset" &
        pids+=($!)
        
        # Limit concurrent agents
        if [[ ${#pids[@]} -ge 4 ]]; then
            wait -n
            pids=($(jobs -p))
        fi
    fi
done

# Wait for all agents
wait

# Generate summary
log "INFO" "Generating summary and skill extraction..."

# Process all streams into a summary
cat entropy/*.stream 2>/dev/null | head -c 10000 > entropy/summary.txt 2>/dev/null || true

# Extract skills from successful patterns
if [[ -s entropy/summary.txt ]]; then
    log "INFO" "Extracting skills from execution..."
    
    node -e "
        const fs = require('fs');
        const crypto = require('crypto');
        const summary = fs.readFileSync('entropy/summary.txt', 'utf8').substring(0, 1000);
        const hash = crypto.createHash('md5').update(summary).digest('hex');
        
        const db = new (require('sqlite3').Database)('memory/goals.db');
        db.run(
            'INSERT OR REPLACE INTO skills (name, description, hash) VALUES (?, ?, ?)',
            ['skill_' + hash.substring(0, 8), summary, hash],
            () => db.close()
        );
    " 2>/dev/null &
fi

# Visual multiverse generation
log "INFO" "Generating visual multiverse data..."

cat > ui/data.json << DATA
{
    "genesis": "$GENESIS",
    "timestamp": "$(date -Iseconds)",
    "agents": $(for agent in "${!AGENTS[@]}"; do echo "\"$agent\""; done | jq -s '.'),
    "streams": $(find entropy -name "*.stream" -exec basename {} \; | jq -R -s 'split("\n") | map(select(. != ""))'),
    "entropy": $(find entropy -name "*.entropy" -exec sh -c 'echo "$(basename {} .entropy): $(cat {})"' \; | jq -R -s 'split("\n") | map(select(. != "")) | map(split(": ")) | map({(.[0]): .[1]}) | add')
}
DATA

log "INFO" "Starting NEXUS HTTP API..."
node server.js &

# Wait for API to start
sleep 2

log "SUCCESS" "NEXUS-2244 Cognitive Kernel Ready"
log "INFO" "WebSocket: ws://localhost:2244"
log "INFO" "HTTP API: http://localhost:7070"
log "INFO" "Timeline DB: memory/timeline.db"
log "INFO" "Visualization: ui/index.html"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "   NEXUS-2244 COGNITIVE STACK OPERATIONAL"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🌐 Web Interface:  http://localhost:2244/ui/index.html"
echo "🔌 WebSocket:      ws://localhost:2244"
echo "📡 HTTP API:       http://localhost:7070/api/ask"
echo "📊 Models:         http://localhost:7070/api/models"
echo "⏱️  Timeline:      http://localhost:7070/api/timeline"
echo ""
echo "🤖 Active Agents:  ${#AGENTS[@]}"
echo "🎯 Genesis Hash:   $GENESIS"
echo "📝 Prompt:         $PROMPT"
echo ""
echo "═══════════════════════════════════════════════════════════"

# Keep running
wait
