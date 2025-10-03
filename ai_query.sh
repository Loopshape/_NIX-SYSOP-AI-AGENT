# -----------------------
# AI Query
# -----------------------
query="$*"

if [ -z "$query" ]; then
    log "Please provide a prompt. Usage: ai 'your prompt'"
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

# Run Ollama model
response=$(ollama run 2244:latest <<<"$processed_query" 2>/dev/null || true)

if [ -z "$response" ]; then
    log "[ERROR] Ollama query failed or returned empty."
    exit 1
fi

# Save to cache
prompt_hash=$(echo -n "$processed_query" | sha256sum | awk '{print $1}')
sqlite3 "$DB" "INSERT OR REPLACE INTO cache(prompt_hash, final_answer) VALUES ('$prompt_hash', '$response');"

# Output
echo "$response"
