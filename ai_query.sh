#!/usr/bin/env bash
# AI Query Wrapper - Refined
set -euo pipefail

DB="${DB:-$HOME/_/ai/core.db}"
AI_BRIDGE="$HOME/_/ai/ai.sh"
LOG_DIR="$HOME/_/ai/logs"
mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

query="$*"

if [ -z "$query" ]; then
    log "Please provide a prompt. Usage: $0 'your prompt'"
    exit 1
fi

# Force English/German, translate Chinese to English
processed_query=$(python3 - <<PYTHON
import sys, re
q = sys.argv[1]
# Remove Chinese characters
q_clean = re.sub(r'[\u4e00-\u9fff]+', '', q)
print(q_clean)
PYTHON
"$query")

# Run via AI Bridge if available
if [ -x "$AI_BRIDGE" ]; then
    response=$("$AI_BRIDGE" query CORE "$processed_query")
else
    # Fallback
    response=$(ollama run 2244:latest <<<"$processed_query" 2>/dev/null || true)
fi

if [ -z "$response" ]; then
    log "[ERROR] AI query failed or returned empty."
    exit 1
fi

# Save to cache
if command -v sqlite3 >/dev/null; then
    prompt_hash=$(echo -n "$processed_query" | sha256sum | awk '{print $1}')
    # Ensure table exists
    sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS cache (prompt_hash TEXT PRIMARY KEY, final_answer TEXT);" 2>/dev/null || true
    sqlite3 "$DB" "INSERT OR REPLACE INTO cache(prompt_hash, final_answer) VALUES ('$prompt_hash', '$(echo "$response" | sed "s/'/''/g")');" 2>/dev/null || true
fi

# Output
echo "$response"
