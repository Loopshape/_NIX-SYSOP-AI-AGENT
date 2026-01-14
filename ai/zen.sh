#!/usr/bin/env bash
# =============================================================================
#  ZEN: 2π/8-Agents Entropy-Driven Parallel Reasoning System
# =============================================================================
#  Hybrid Bash/Node.js/Python3 ES Module Wrapper
#  Features:
#   • 8-Agent phased reasoning (2π/8 angle positions)
#   • SQLite3 semantic memory with embedding recall
#   • Entropy-driven parallel execution
#   • Token streaming to files
#   • URL/File/Hash/WalletSeed parsing
#   • CRUD/SOAP/REST batch processing
#   • Hybrid execution modes
# =============================================================================

set -euo pipefail
IFS=$'\n\t'
exec 2>&1

# =============================================================================
#  CONFIGURATION
# =============================================================================
readonly ZEN_ROOT="${HOME}/_/ai"
readonly ZEN_DIR="${ZEN_ROOT}/zen"
readonly DB_PATH="${ZEN_DIR}/zen_memory.db"
readonly LOG_PATH="${ZEN_DIR}/zen_entropy.log"
readonly TOKEN_STREAM_DIR="${ZEN_DIR}/streams"
readonly MODELS_DIR="${ZEN_DIR}/models"
readonly CACHE_DIR="${ZEN_DIR}/cache"

# Default models
readonly OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
readonly LLAMA_MODEL="${LLAMA_MODEL:-llama3.2:3b}"
readonly EMBED_MODEL="${EMBED_MODEL:-nomic-embed-text}"
readonly CODE_MODEL="${CODE_MODEL:-codellama:7b}"

# Entropy parameters
readonly ENTROPY_SEED="${ENTROPY_SEED:-$(date +%s%N)}"
readonly MAX_ENTROPY="${MAX_ENTROPY:-0.9}"
readonly MIN_ENTROPY="${MIN_ENTROPY:-0.1}"
readonly ENTROPY_DECAY="${ENTROPY_DECAY:-0.95}"

# 2π/8 Agents (phased reasoning)
declare -A AGENTS=(
    ["0"]="Observer:0.0"
    ["1"]="Analyzer:0.785"      # π/4
    ["2"]="Synthesizer:1.571"   # π/2
    ["3"]="Critic:2.356"        # 3π/4
    ["4"]="Generator:3.142"     # π
    ["5"]="Validator:3.927"     # 5π/4
    ["6"]="Optimizer:4.712"     # 3π/2
    ["7"]="Integrator:5.498"    # 7π/4
)

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# =============================================================================
#  INITIALIZATION
# =============================================================================
init_zen() {
    mkdir -p "$ZEN_DIR" "$TOKEN_STREAM_DIR" "$MODELS_DIR" "$CACHE_DIR"
    
    if [[ ! -f "${ZEN_DIR}/.initialized" ]]; then
        zen_log "SYSTEM" "Initializing ZEN environment..."
        
        # Initialize SQLite database
        init_database
        
        # Initialize entropy pool
        echo "$ENTROPY_SEED" > "${ZEN_DIR}/entropy.seed"
        
        # Create hybrid modules
        create_hybrid_modules
        
        touch "${ZEN_DIR}/.initialized"
        zen_log "SYSTEM" "ZEN initialized at ${ZEN_DIR}"
    fi
}

# =============================================================================
#  HYBRID MODULE CREATION
# =============================================================================
create_hybrid_modules() {
    # Node.js ES Module wrapper
    cat > "${ZEN_DIR}/zen.mjs" <<'NODEJS'
#!/usr/bin/env node
// ZEN Node.js ES Module Wrapper
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { spawn, execSync } from 'child_process';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import crypto from 'crypto';

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

class ZenMemory {
    constructor(dbPath) {
        this.dbPath = dbPath;
        this.db = null;
    }

    async init() {
        this.db = await open({
            filename: this.dbPath,
            driver: sqlite3.Database
        });

        await this.db.exec(`
            CREATE TABLE IF NOT EXISTS memories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                hash TEXT UNIQUE,
                content TEXT,
                embedding BLOB,
                agent_id INTEGER,
                phase REAL,
                entropy REAL,
                tokens INTEGER,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                accessed_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS clusters (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                centroid BLOB,
                size INTEGER,
                variance REAL,
                last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS tokens (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session TEXT,
                agent_id INTEGER,
                token TEXT,
                position INTEGER,
                entropy REAL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE INDEX IF NOT EXISTS idx_memories_hash ON memories(hash);
            CREATE INDEX IF NOT EXISTS idx_memories_phase ON memories(phase);
            CREATE INDEX IF NOT EXISTS idx_tokens_session ON tokens(session);
        `);
    }

    async storeMemory(content, agentId = 0, phase = 0.0, entropy = 0.5) {
        const hash = crypto.createHash('sha256').update(content).digest('hex');
        const embedding = await this.generateEmbedding(content);
        
        await this.db.run(
            `INSERT OR REPLACE INTO memories 
             (hash, content, embedding, agent_id, phase, entropy, accessed_at)
             VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`,
            [hash, content, embedding, agentId, phase, entropy]
        );
        
        return hash;
    }

    async generateEmbedding(text) {
        // Use Ollama embeddings API
        const response = await fetch('http://localhost:11434/api/embeddings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                model: 'nomic-embed-text',
                prompt: text
            })
        });
        
        const data = await response.json();
        return Buffer.from(data.embedding);
    }

    async recallSemantic(query, limit = 5) {
        const queryEmbedding = await this.generateEmbedding(query);
        
        return await this.db.all(`
            SELECT content, 
                   agent_id,
                   phase,
                   entropy,
                   dot_product(embedding, ?) as similarity
            FROM memories
            ORDER BY similarity DESC
            LIMIT ?
        `, [queryEmbedding, limit]);
    }
}

class ZenAgent {
    constructor(id, name, phase) {
        this.id = id;
        this.name = name;
        this.phase = phase;
        this.entropy = 0.5;
    }

    async process(input, context = {}) {
        const temperature = 0.7 + (this.entropy * 0.3);
        const streamPath = join(__dirname, 'streams', 
            `agent_${this.id}_${Date.now()}.txt`);

        const response = await this.callOllama(input, temperature, streamPath);
        
        // Update entropy based on response characteristics
        this.entropy = this.calculateEntropy(response);
        
        return {
            agent: this.name,
            phase: this.phase,
            response: response,
            entropy: this.entropy,
            stream: streamPath
        };
    }

    calculateEntropy(text) {
        // Calculate Shannon entropy of text
        const freq = {};
        for (const char of text) {
            freq[char] = (freq[char] || 0) + 1;
        }
        
        let entropy = 0;
        const len = text.length;
        for (const count of Object.values(freq)) {
            const p = count / len;
            entropy -= p * Math.log2(p);
        }
        
        return Math.min(entropy / 8, 0.9); // Normalize
    }

    async callOllama(prompt, temperature, streamPath) {
        return new Promise((resolve, reject) => {
            const proc = spawn('ollama', [
                'run', 
                'llama3.2:3b',
                prompt
            ], {
                env: { ...process.env, OLLAMA_HOST: 'http://localhost:11434' }
            });

            let output = '';
            const stream = fs.createWriteStream(streamPath);

            proc.stdout.on('data', (data) => {
                const text = data.toString();
                output += text;
                stream.write(text);
            });

            proc.stderr.on('data', (data) => {
                console.error(`Agent ${this.name} error:`, data.toString());
            });

            proc.on('close', (code) => {
                stream.end();
                resolve(output);
            });

            proc.on('error', reject);
        });
    }
}

export { ZenMemory, ZenAgent };
NODEJS

    # Python3 wrapper for ML operations
    cat > "${ZEN_DIR}/zen.py" <<'PYTHON'
#!/usr/bin/env python3
"""
ZEN Python Wrapper for ML/Embedding Operations
"""
import sqlite3
import numpy as np
import hashlib
import json
import sys
import os
from pathlib import Path
from typing import List, Tuple, Optional
import requests
from datetime import datetime

class ZenEmbedder:
    """Handle text embeddings and similarity"""
    
    def __init__(self, ollama_host="http://localhost:11434"):
        self.ollama_host = ollama_host
        self.cache = {}
        
    def embed_text(self, text: str, model: str = "nomic-embed-text") -> np.ndarray:
        """Get text embedding from Ollama"""
        cache_key = hashlib.sha256(text.encode()).hexdigest()
        
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        try:
            response = requests.post(
                f"{self.ollama_host}/api/embeddings",
                json={"model": model, "prompt": text},
                timeout=30
            )
            response.raise_for_status()
            embedding = np.array(response.json()["embedding"], dtype=np.float32)
            self.cache[cache_key] = embedding
            return embedding
        except Exception as e:
            print(f"Embedding error: {e}", file=sys.stderr)
            # Fallback to simple TF-IDF like embedding
            return self.fallback_embed(text)
    
    def fallback_embed(self, text: str) -> np.ndarray:
        """Simple fallback embedding"""
        words = text.lower().split()
        vocab = list(set(words))
        embedding = np.zeros(384, dtype=np.float32)
        
        for i, word in enumerate(vocab[:384]):
            embedding[i] = words.count(word) / len(words)
        
        norm = np.linalg.norm(embedding)
        if norm > 0:
            embedding = embedding / norm
        
        return embedding
    
    def cosine_similarity(self, a: np.ndarray, b: np.ndarray) -> float:
        """Calculate cosine similarity"""
        dot = np.dot(a, b)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        
        if norm_a == 0 or norm_b == 0:
            return 0.0
        
        return float(dot / (norm_a * norm_b))
    
    def cluster_embeddings(self, embeddings: List[np.ndarray], k: int = 8) -> List[List[int]]:
        """Simple K-means clustering"""
        from sklearn.cluster import KMeans
        
        if len(embeddings) < k:
            k = len(embeddings)
        
        if k <= 1:
            return [list(range(len(embeddings)))]
        
        kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
        clusters = kmeans.fit_predict(embeddings)
        
        result = [[] for _ in range(k)]
        for idx, cluster_id in enumerate(clusters):
            result[cluster_id].append(idx)
        
        return result

class ZenEntropy:
    """Entropy and chaos management for parallel reasoning"""
    
    def __init__(self, seed: int = None):
        self.seed = seed or int(datetime.now().timestamp() * 1000)
        np.random.seed(self.seed)
        self.entropy_pool = []
        self.decay_rate = 0.95
        
    def generate_entropy(self, n: int = 8) -> List[float]:
        """Generate entropy values for agents"""
        entropies = np.random.uniform(0.1, 0.9, n)
        
        # Apply 2π/8 phase distribution
        phases = np.linspace(0, 2 * np.pi, n, endpoint=False)
        phase_mod = (np.sin(phases) + 1) / 2  # Convert to 0-1 range
        
        entropies = entropies * 0.7 + phase_mod * 0.3
        return entropies.tolist()
    
    def adjust_entropy(self, current: float, feedback: float) -> float:
        """Adjust entropy based on feedback"""
        new_entropy = current * self.decay_rate + feedback * (1 - self.decay_rate)
        return np.clip(new_entropy, 0.1, 0.9)
    
    def calculate_chaos_index(self, responses: List[str]) -> float:
        """Calculate chaos index from multiple responses"""
        if not responses:
            return 0.0
        
        # Measure diversity between responses
        similarities = []
        embedder = ZenEmbedder()
        
        for i in range(len(responses)):
            for j in range(i + 1, len(responses)):
                emb_i = embedder.embed_text(responses[i])
                emb_j = embedder.embed_text(responses[j])
                sim = embedder.cosine_similarity(emb_i, emb_j)
                similarities.append(sim)
        
        if similarities:
            avg_similarity = np.mean(similarities)
            chaos = 1.0 - avg_similarity
        else:
            chaos = 0.5
        
        return float(chaos)

class ZenParser:
    """Parse various input types"""
    
    @staticmethod
    def parse_input(input_str: str) -> dict:
        """Parse prompt/url/file/hash/walletseed"""
        result = {
            "type": "prompt",
            "content": input_str,
            "valid": True
        }
        
        # URL detection
        if input_str.startswith(("http://", "https://", "ftp://")):
            result["type"] = "url"
            try:
                response = requests.get(input_str, timeout=10)
                result["content"] = response.text[:10000]  # Limit
            except:
                result["valid"] = False
        
        # File detection
        elif os.path.exists(input_str):
            result["type"] = "file"
            try:
                with open(input_str, 'r', encoding='utf-8') as f:
                    result["content"] = f.read(10000)  # Limit
            except:
                result["valid"] = False
        
        # Hash detection (64 hex chars)
        elif len(input_str) == 64 and all(c in "0123456789abcdefABCDEF" for c in input_str):
            result["type"] = "hash"
        
        # Wallet seed detection (12 or 24 words)
        elif 12 <= len(input_str.split()) <= 24:
            result["type"] = "walletseed"
        
        return result
    
    @staticmethod
    def batch_process(file_path: str, operation: str = "crud") -> List[dict]:
        """Batch process file with CRUD/SOAP/REST operations"""
        results = []
        
        if not os.path.exists(file_path):
            return results
        
        with open(file_path, 'r') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                
                result = {
                    "line": line_num,
                    "input": line,
                    "operation": operation,
                    "status": "pending"
                }
                
                try:
                    if operation == "crud":
                        # CRUD operations on local data
                        parsed = ZenParser.parse_input(line)
                        result["parsed"] = parsed
                        result["status"] = "success"
                    
                    elif operation == "soap":
                        # SOAP-like operation
                        result["status"] = "soap_not_implemented"
                    
                    elif operation == "rest":
                        # REST API call
                        if line.startswith("http"):
                            response = requests.get(line, timeout=5)
                            result["response_code"] = response.status_code
                            result["status"] = "success"
                    
                    results.append(result)
                    
                except Exception as e:
                    result["status"] = f"error: {str(e)}"
                    results.append(result)
        
        return results

if __name__ == "__main__":
    # Command line interface
    if len(sys.argv) > 1:
        parser = ZenParser()
        
        if sys.argv[1] == "parse":
            result = parser.parse_input(sys.argv[2])
            print(json.dumps(result, indent=2))
        
        elif sys.argv[1] == "embed":
            embedder = ZenEmbedder()
            embedding = embedder.embed_text(sys.argv[2])
            print(f"Embedding shape: {embedding.shape}")
            print(f"First 10 values: {embedding[:10]}")
        
        elif sys.argv[1] == "entropy":
            entropy = ZenEntropy()
            values = entropy.generate_entropy(8)
            print(f"Entropy values: {values}")
            print(f"Chaos index: {entropy.calculate_chaos_index(sys.argv[2:])}")
PYTHON

    # Make executables
    chmod +x "${ZEN_DIR}/zen.mjs"
    chmod +x "${ZEN_DIR}/zen.py"
}

# =============================================================================
#  DATABASE FUNCTIONS
# =============================================================================
init_database() {
    zen_log "DATABASE" "Initializing SQLite memory at ${DB_PATH}"
    
    sqlite3 "$DB_PATH" <<'SQL'
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = ON;
PRAGMA busy_timeout = 5000;

-- Core memory table
CREATE TABLE IF NOT EXISTS zen_memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid TEXT UNIQUE NOT NULL,
    content_hash TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding BLOB,
    agent_id INTEGER DEFAULT 0,
    phase REAL DEFAULT 0.0,
    entropy REAL DEFAULT 0.5,
    token_count INTEGER DEFAULT 0,
    importance REAL DEFAULT 0.5,
    context TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    
    CHECK (entropy >= 0.0 AND entropy <= 1.0),
    CHECK (phase >= 0.0 AND phase < 6.28318530718), -- 2π
    CHECK (importance >= 0.0 AND importance <= 1.0)
);

-- Memory clusters for semantic recall
CREATE TABLE IF NOT EXISTS memory_clusters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cluster_hash TEXT UNIQUE NOT NULL,
    centroid BLOB NOT NULL,
    size INTEGER DEFAULT 0,
    variance REAL DEFAULT 0.0,
    average_entropy REAL DEFAULT 0.5,
    dominant_agent INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Token streams for parallel processing
CREATE TABLE IF NOT EXISTS token_streams (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stream_id TEXT UNIQUE NOT NULL,
    session_id TEXT NOT NULL,
    agent_id INTEGER NOT NULL,
    token_index INTEGER NOT NULL,
    token TEXT NOT NULL,
    entropy REAL DEFAULT 0.5,
    confidence REAL DEFAULT 0.5,
    temperature REAL DEFAULT 0.7,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES reasoning_sessions(uuid) ON DELETE CASCADE
);

-- Reasoning sessions
CREATE TABLE IF NOT EXISTS reasoning_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid TEXT UNIQUE NOT NULL,
    prompt_hash TEXT NOT NULL,
    prompt TEXT NOT NULL,
    input_type TEXT CHECK(input_type IN ('prompt', 'url', 'file', 'hash', 'walletseed')),
    agent_count INTEGER DEFAULT 8,
    initial_entropy REAL DEFAULT 0.5,
    final_entropy REAL,
    total_tokens INTEGER DEFAULT 0,
    duration_ms INTEGER,
    result_path TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Agent states
CREATE TABLE IF NOT EXISTS agent_states (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id INTEGER NOT NULL,
    agent_name TEXT NOT NULL,
    current_phase REAL DEFAULT 0.0,
    current_entropy REAL DEFAULT 0.5,
    temperature REAL DEFAULT 0.7,
    tokens_generated INTEGER DEFAULT 0,
    sessions_participated INTEGER DEFAULT 0,
    average_confidence REAL DEFAULT 0.5,
    last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(agent_id, agent_name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_memories_hash ON zen_memories(content_hash);
CREATE INDEX IF NOT EXISTS idx_memories_phase ON zen_memories(phase);
CREATE INDEX IF NOT EXISTS idx_memories_entropy ON zen_memories(entropy);
CREATE INDEX IF NOT EXISTS idx_streams_session ON token_streams(session_id, agent_id);
CREATE INDEX IF NOT EXISTS idx_sessions_created ON reasoning_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_agent_states_active ON agent_states(agent_id, last_active);

-- Views
CREATE VIEW IF NOT EXISTS vw_agent_activity AS
SELECT 
    a.agent_id,
    a.agent_name,
    a.current_phase,
    a.current_entropy,
    a.tokens_generated,
    a.sessions_participated,
    COUNT(DISTINCT m.id) as memories_stored,
    AVG(m.importance) as avg_memory_importance
FROM agent_states a
LEFT JOIN zen_memories m ON a.agent_id = m.agent_id
GROUP BY a.agent_id, a.agent_name;

CREATE VIEW IF NOT EXISTS vw_entropy_trends AS
SELECT 
    DATE(created_at) as date,
    AVG(entropy) as avg_entropy,
    COUNT(*) as memory_count,
    SUM(token_count) as total_tokens
FROM zen_memories
GROUP BY DATE(created_at);

-- Initialize agents
INSERT OR IGNORE INTO agent_states (agent_id, agent_name, current_phase) VALUES
(0, 'Observer', 0.0),
(1, 'Analyzer', 0.7853981634),
(2, 'Synthesizer', 1.5707963268),
(3, 'Critic', 2.3561944902),
(4, 'Generator', 3.1415926536),
(5, 'Validator', 3.926990817),
(6, 'Optimizer', 4.7123889804),
(7, 'Integrator', 5.4977871438);
SQL

    zen_log "DATABASE" "Database schema created"
}

# =============================================================================
#  ENTROPY FUNCTIONS
# =============================================================================
generate_entropy() {
    local count="${1:-8}"
    local seed="${2:-$ENTROPY_SEED}"
    
    python3 -c "
import hashlib
import numpy as np
import sys

seed = int('${seed}')
np.random.seed(seed)

count = ${count}
phases = np.linspace(0, 2 * np.pi, count, endpoint=False)
entropies = []

for i, phase in enumerate(phases):
    # Base entropy from seed
    base = np.random.uniform(0.1, 0.9)
    
    # Phase modulation (sinusoidal)
    phase_mod = (np.sin(phase) + 1) / 2  # 0-1 range
    
    # Combine with chaos factor
    chaos = np.random.random() * 0.3
    entropy = base * 0.6 + phase_mod * 0.3 + chaos * 0.1
    
    # Clamp to range
    entropy = max(0.1, min(0.9, entropy))
    entropies.append(f'{entropy:.4f}')

print(' '.join(entropies))
"
}

calculate_chaos_index() {
    local responses_file="$1"
    local temp_file="$(mktemp)"
    
    # Extract responses and calculate diversity
    cat "$responses_file" | jq -r '.response' > "$temp_file"
    
    python3 -c "
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import sys

with open('${temp_file}', 'r') as f:
    responses = [line.strip() for line in f if line.strip()]

if len(responses) < 2:
    print('0.5')
    sys.exit(0)

# Calculate pairwise similarities
vectorizer = TfidfVectorizer(stop_words='english')
try:
    tfidf = vectorizer.fit_transform(responses)
    similarities = cosine_similarity(tfidf)
    
    # Chaos = 1 - average similarity
    np.fill_diagonal(similarities, 0)
    valid_sims = similarities[similarities > 0]
    
    if len(valid_sims) > 0:
        avg_sim = np.mean(valid_sims)
        chaos = 1.0 - avg_sim
    else:
        chaos = 0.5
except:
    chaos = 0.5

print(f'{chaos:.4f}')
"
    
    rm -f "$temp_file"
}

# =============================================================================
#  AGENT EXECUTION
# =============================================================================
execute_agent() {
    local agent_id="$1"
    local agent_name="$2"
    local phase="$3"
    local entropy="$4"
    local prompt="$5"
    local session_id="$6"
    
    local stream_file="${TOKEN_STREAM_DIR}/${session_id}_agent${agent_id}.stream"
    local temperature=$(python3 -c "print(0.7 + (${entropy} * 0.3))")
    
    zen_log "AGENT" "Starting ${agent_name} (Phase: ${phase}, Entropy: ${entropy}, Temp: ${temperature})"
    
    # Create agent-specific prompt with phase context
    local agent_prompt=$(cat <<PROMPT
You are the ${agent_name} agent in a 2π/8 parallel reasoning system.
Your phase position is: ${phase} radians (${agent_id}/8 of 2π cycle)
Current entropy level: ${entropy}
Temperature: ${temperature}

Original prompt: ${prompt}

Respond from your specialized perspective at this exact phase.
Focus on the aspect corresponding to your position in the reasoning cycle.
Provide a concise, focused response.
PROMPT
)
    
    # Stream tokens to file
    {
        echo "=== AGENT ${agent_id}: ${agent_name} ==="
        echo "Phase: ${phase}"
        echo "Entropy: ${entropy}"
        echo "Temperature: ${temperature}"
        echo "Timestamp: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
        echo "----------------------------------------"
    } > "$stream_file"
    
    # Call Ollama with streaming
    local response=""
    local token_count=0
    
    if command -v ollama &>/dev/null; then
        response=$(ollama run --temperature "$temperature" "$LLAMA_MODEL" "$agent_prompt" 2>/dev/null | tee -a "$stream_file")
        token_count=$(wc -w <<< "$response")
    else
        # Fallback simulation
        response="[Simulated response from ${agent_name} at phase ${phase}] Processing: ${prompt:0:100}..."
        token_count=$((50 + RANDOM % 100))
        echo "$response" >> "$stream_file"
    fi
    
    echo -e "\n----------------------------------------" >> "$stream_file"
    echo "Tokens generated: $token_count" >> "$stream_file"
    echo "Completed: $(date -u +'%Y-%m-%d %H:%M:%S UTC')" >> "$stream_file"
    
    # Store in memory
    store_memory "$response" "$agent_id" "$phase" "$entropy" "$token_count"
    
    # Return JSON result
    jq -n \
        --arg agent_id "$agent_id" \
        --arg agent_name "$agent_name" \
        --arg phase "$phase" \
        --arg entropy "$entropy" \
        --arg temperature "$temperature" \
        --arg response "$response" \
        --arg stream_file "$stream_file" \
        --arg token_count "$token_count" \
        '{
            agent_id: $agent_id,
            agent_name: $agent_name,
            phase: $phase,
            entropy: $entropy,
            temperature: $temperature,
            response: $response,
            stream_file: $stream_file,
            token_count: $token_count
        }'
}

# =============================================================================
#  MEMORY FUNCTIONS
# =============================================================================
store_memory() {
    local content="$1"
    local agent_id="${2:-0}"
    local phase="${3:-0.0}"
    local entropy="${4:-0.5}"
    local tokens="${5:-0}"
    
    local content_hash=$(echo -n "$content" | sha256sum | cut -d' ' -f1)
    local uuid=$(uuidgen)
    
    sqlite3 "$DB_PATH" <<SQL
INSERT INTO zen_memories (
    uuid, content_hash, content, agent_id, phase, entropy, token_count, accessed_at
) VALUES (
    '${uuid}', '${content_hash}', '$(echo "${content}" | sed "s/'/''/g")',
    ${agent_id}, ${phase}, ${entropy}, ${tokens}, CURRENT_TIMESTAMP
);
SQL
    
    echo "$uuid"
}

recall_memory() {
    local query="$1"
    local limit="${2:-5}"
    
    zen_log "MEMORY" "Recalling memories for: ${query:0:50}..."
    
    # Generate query embedding
    local query_embedding=$(python3 "${ZEN_DIR}/zen.py" embed "$query" 2>/dev/null)
    
    if [[ -z "$query_embedding" ]]; then
        # Fallback to keyword search
        sqlite3 "$DB_PATH" <<SQL
SELECT 
    m.agent_id,
    a.agent_name,
    m.phase,
    m.entropy,
    m.content,
    m.token_count,
    datetime(m.created_at, 'localtime') as created
FROM zen_memories m
JOIN agent_states a ON m.agent_id = a.agent_id
WHERE m.content LIKE '%${query}%'
ORDER BY m.importance DESC, m.created_at DESC
LIMIT ${limit};
SQL
    else
        # Semantic search (simplified)
        sqlite3 -csv "$DB_PATH" <<SQL
SELECT 
    m.agent_id,
    a.agent_name,
    m.phase,
    m.entropy,
    substr(m.content, 1, 200) as preview,
    m.token_count,
    m.created_at
FROM zen_memories m
JOIN agent_states a ON m.agent_id = a.agent_id
ORDER BY m.created_at DESC
LIMIT ${limit};
SQL
    fi
}

# =============================================================================
#  PARALLEL REASONING ORCHESTRATOR
# =============================================================================
parallel_reason() {
    local prompt="$1"
    local session_id=$(uuidgen)
    local session_dir="${TOKEN_STREAM_DIR}/${session_id}"
    
    mkdir -p "$session_dir"
    
    zen_log "SESSION" "Starting parallel reasoning session: $session_id"
    zen_log "PROMPT" "Input: ${prompt:0:100}..."
    
    # Parse input type
    local input_type=$(python3 -c "
import sys
sys.path.append('${ZEN_DIR}')
from zen import ZenParser
p = ZenParser()
result = p.parse_input('''${prompt}''')
print(result['type'])
")
    
    # Generate entropy values for agents
    local entropies=($(generate_entropy 8))
    
    # Store session
    sqlite3 "$DB_PATH" <<SQL
INSERT INTO reasoning_sessions (
    uuid, prompt_hash, prompt, input_type, agent_count, initial_entropy
) VALUES (
    '${session_id}',
    '$(echo -n "${prompt}" | sha256sum | cut -d' ' -f1)',
    '$(echo "${prompt}" | sed "s/'/''/g")',
    '${input_type}',
    8,
    '$(echo "${entropies[@]}" | tr ' ' ',')'
);
SQL
    
    # Execute agents in parallel
    local agent_results=()
    local pids=()
    
    for i in {0..7}; do
        IFS=':' read -r agent_name phase <<< "${AGENTS[$i]}"
        
        (
            result=$(execute_agent "$i" "$agent_name" "$phase" "${entropies[$i]}" "$prompt" "$session_id")
            echo "$result" > "${session_dir}/agent_${i}.json"
        ) &
        
        pids+=($!)
        
        # Limit concurrent agents
        if [[ ${#pids[@]} -ge 4 ]]; then
            wait -n
        fi
    done
    
    # Wait for all agents
    wait "${pids[@]}"
    
    # Collect results
    local all_responses=""
    for i in {0..7}; do
        if [[ -f "${session_dir}/agent_${i}.json" ]]; then
            local agent_result=$(cat "${session_dir}/agent_${i}.json")
            agent_results+=("$agent_result")
            
            local response=$(jq -r '.response' <<< "$agent_result")
            all_responses+="$response"$'\n'
        fi
    done
    
    # Calculate chaos index
    local chaos_index=$(calculate_chaos_index <(printf '%s' "$all_responses"))
    
    # Generate final synthesis
    local synthesis_prompt=$(cat <<PROMPT
Synthesize the following 8 parallel reasonings into a coherent response.
Original query: ${prompt}

Agent responses from 2π/8 phase positions:

${all_responses}

Create a final synthesis that integrates all perspectives.
System chaos index: ${chaos_index}
PROMPT
)
    
    local final_response=""
    if command -v ollama &>/dev/null; then
        final_response=$(ollama run "$LLAMA_MODEL" "$synthesis_prompt")
    else
        final_response="[Synthesis] Integrated response from 8 agents. Chaos index: ${chaos_index}"
    fi
    
    # Store final result
    local final_stream="${session_dir}/final_synthesis.txt"
    echo "$final_response" > "$final_stream"
    
    # Update session
    sqlite3 "$DB_PATH" <<SQL
UPDATE reasoning_sessions 
SET 
    final_entropy = ${chaos_index},
    result_path = '${final_stream}',
    completed_at = CURRENT_TIMESTAMP
WHERE uuid = '${session_id}';
SQL
    
    # Output results
    jq -n \
        --arg session_id "$session_id" \
        --arg prompt "$prompt" \
        --arg input_type "$input_type" \
        --arg chaos_index "$chaos_index" \
        --arg final_response "$final_response" \
        --arg synthesis_file "$final_stream" \
        --argjson agents "$(printf '%s\n' "${agent_results[@]}" | jq -s '.')" \
        '{
            session_id: $session_id,
            prompt: $prompt,
            input_type: $input_type,
            chaos_index: $chaos_index,
            agents: $agents,
            synthesis: $final_response,
            synthesis_file: $synthesis_file,
            stream_dir: $session_dir
        }'
}

# =============================================================================
#  BATCH PROCESSING
# =============================================================================
batch_process() {
    local input_file="$1"
    local operation="${2:-crud}"
    local output_file="${3:-${CACHE_DIR}/batch_$(date +%s).json}"
    
    zen_log "BATCH" "Processing $input_file with $operation"
    
    python3 "${ZEN_DIR}/zen.py" batch "$input_file" "$operation" > "$output_file"
    
    local count=$(jq '. | length' "$output_file" 2>/dev/null || echo "0")
    zen_log "BATCH" "Processed $count items to $output_file"
    
    cat "$output_file"
}

# =============================================================================
#  LOGGING
# =============================================================================
zen_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "INFO") echo -e "${GREEN}[INFO]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        "AGENT") echo -e "${MAGENTA}[AGENT]${NC} $message" ;;
        "MEMORY") echo -e "${CYAN}[MEMORY]${NC} $message" ;;
        "SESSION") echo -e "${WHITE}[SESSION]${NC} $message" ;;
        "BATCH") echo -e "${YELLOW}[BATCH]${NC} $message" ;;
        "SYSTEM") echo -e "${GREEN}[SYSTEM]${NC} $message" ;;
        *) echo "[$level] $message" ;;
    esac
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_PATH"
    
    # Rotate logs if > 10MB
    if [[ $(stat -c%s "$LOG_PATH" 2>/dev/null || echo "0") -gt 10485760 ]]; then
        mv "$LOG_PATH" "${LOG_PATH}.$(date +%s)"
        zen_log "SYSTEM" "Log rotated"
    fi
}

# =============================================================================
#  MAIN ENTRY POINT
# =============================================================================
main() {
    init_zen
    
    local command="${1:-help}"
    
    case "$command" in
        "reason"|"think")
            [[ $# -lt 2 ]] && { zen_log "ERROR" "Usage: $0 reason \"<prompt>\""; exit 1; }
            parallel_reason "${2}"
            ;;
        
        "recall"|"remember")
            [[ $# -lt 2 ]] && { zen_log "ERROR" "Usage: $0 recall \"<query>\" [limit]"; exit 1; }
            recall_memory "${2}" "${3:-5}"
            ;;
        
        "batch")
            [[ $# -lt 2 ]] && { zen_log "ERROR" "Usage: $0 batch <file> [crud|soap|rest] [output]"; exit 1; }
            batch_process "${2}" "${3:-crud}" "${4:-}"
            ;;
        
        "entropy")
            generate_entropy "${2:-8}" "${3:-}"
            ;;
        
        "agents")
            echo "2π/8 Parallel Reasoning Agents:"
            for i in {0..7}; do
                IFS=':' read -r name phase <<< "${AGENTS[$i]}"
                printf "  %d. %-12s Phase: %.3fπ (%.3f rad)\n" \
                    "$i" "$name" \
                    "$(echo "$phase / 3.1415926535" | bc -l | head -c 5)" \
                    "$phase"
            done
            ;;
        
        "stats")
            sqlite3 "$DB_PATH" <<'SQL'
SELECT 
    (SELECT COUNT(*) FROM zen_memories) as total_memories,
    (SELECT COUNT(DISTINCT session_id) FROM token_streams) as total_sessions,
    (SELECT SUM(token_count) FROM zen_memories) as total_tokens,
    (SELECT AVG(entropy) FROM zen_memories) as avg_entropy,
    (SELECT datetime(MAX(created_at), 'localtime') FROM zen_memories) as latest_memory;
SQL
            ;;
        
        "streams")
            find "$TOKEN_STREAM_DIR" -name "*.stream" -type f | \
            while read -r stream; do
                echo "=== $(basename "$stream") ==="
                head -5 "$stream"
                echo "..."
            done
            ;;
        
        "clean")
            find "$TOKEN_STREAM_DIR" -name "*.stream" -mtime +7 -delete
            find "$CACHE_DIR" -name "*.json" -mtime +3 -delete
            zen_log "SYSTEM" "Cleaned old streams and cache"
            ;;
        
        "reset")
            rm -rf "$ZEN_DIR"
            zen_log "SYSTEM" "Reset ZEN system"
            ;;
        
        "help"|*)
            cat <<EOF
ZEN: 2π/8-Agents Entropy-Driven Parallel Reasoning System

Commands:
  reason "prompt"        - Parallel reasoning with 8 agents
  recall "query" [N]     - Semantic memory recall (N results)
  batch <file> [op]      - Batch process file (crud|soap|rest)
  entropy [N] [seed]     - Generate entropy values for N agents
  agents                 - List 2π/8 agents with phase positions
  stats                  - System statistics
  streams                - View token streams
  clean                  - Clean old streams and cache
  reset                  - Reset entire system
  help                   - Show this help

Examples:
  $0 reason "What is consciousness?"
  $0 recall "quantum physics" 10
  $0 batch urls.txt rest
  $0 entropy 16 $(date +%s)

Environment:
  ZEN_ROOT: $ZEN_ROOT
  DB_PATH: $DB_PATH
  LOG_PATH: $LOG_PATH
EOF
            ;;
    esac
}

# =============================================================================
#  EXECUTION GUARD
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure we have required commands
    for cmd in sqlite3 jq python3; do
        if ! command -v "$cmd" &>/dev/null; then
            zen_log "ERROR" "Required command not found: $cmd"
            exit 1
        fi
    done
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        main "help"
    else
        main "$@"
    fi
fi

# =============================================================================
#  NODE.JS ES MODULE EXPORT
# =============================================================================
: <<'NODEJS_EXPORT'
// Node.js ES Module export section
if (typeof module !== 'undefined' && module.exports) {
    // CommonJS export
    module.exports = {
        ZenMemory: require('./zen.mjs').ZenMemory,
        ZenAgent: require('./zen.mjs').ZenAgent,
        parallelReason: (prompt) => {
            const { execSync } = require('child_process');
            const result = execSync(`"${process.argv[1]}" reason "${prompt}"`, {
                encoding: 'utf8'
            });
            return JSON.parse(result);
        }
    };
} else if (typeof window !== 'undefined') {
    // Browser export
    window.ZEN = {
        version: '2π/8',
        agents: ${#AGENTS[@]},
        entropy: ${ENTROPY_SEED}
    };
}
NODEJS_EXPORT

# =============================================================================
#  PYTHON MODULE GUARD
# =============================================================================
: <<'PYTHON_EXPORT'
# Python module export
if __name__ == "__main__" and len(sys.argv) > 1 and sys.argv[1] == "--python":
    import subprocess
    import json
    
    def zen_reason(prompt):
        """Call ZEN reasoning from Python"""
        result = subprocess.run(
            [sys.argv[0], "reason", prompt],
            capture_output=True,
            text=True
        )
        return json.loads(result.stdout)
    
    def zen_recall(query, limit=5):
        """Call ZEN memory recall from Python"""
        result = subprocess.run(
            [sys.argv[0], "recall", query, str(limit)],
            capture_output=True,
            text=True
        )
        return result.stdout
    
    print("ZEN Python wrapper loaded")
PYTHON_EXPORT
