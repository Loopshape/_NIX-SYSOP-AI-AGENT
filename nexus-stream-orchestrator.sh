#!/usr/bin/env bash
# NEXUS Stream Orchestrator: Stream + Load-balancer + Ollama model management

set -euo pipefail
export AI_MEMORY_DIR="$HOME/.ai_memory"
export OLLAMA_HOST="http://localhost:11435"

QUEUE_FILE="./nexus_stream_queue.json"
LOG_FILE="./nexus_stream.log"

# Monitor model downloads
function check_model() {
    local model=$1
    local status=$(ollama ls | grep "$model" || echo "missing")
    if [[ "$status" == "missing" ]]; then
        echo "[INFO] Pulling model $model..."
        ollama pull "$model" &
    fi
}

# Push stream chunk to queue
function enqueue_chunk() {
    local file=$1
    local hash=$(sha256sum "$file" | awk '{print $1}')
    jq --arg f "$file" --arg h "$hash" '.queue += [{"file":$f,"hash":$h,"status":"pending"}]' "$QUEUE_FILE" > tmp.$$.json && mv tmp.$$.json "$QUEUE_FILE"
}

# Assign task to agent based on load
function dispatch_task() {
    local agent=$1
    local model=$2
    local chunk_file=$3

    echo "[DISPATCH] Agent: $agent, Model: $model, File: $chunk_file"
    ollama generate "$model" --file "$chunk_file" --stream >> "$LOG_FILE" &
}

# Main loop
while true; do
    # Check essential models
    check_model "whisper"
    check_model "qwen2.5-vl"
    check_model "deepseek-r1"

    # Fetch next chunk
    NEXT=$(jq -r '.queue[] | select(.status=="pending") | .file' "$QUEUE_FILE" | head -n1 || echo "")
    if [[ -n "$NEXT" ]]; then
        # Determine agent & model based on file type
        case "$NEXT" in
            *.wav|*.mp3) AGENT="Wave"; MODEL="whisper" ;;
            *.mp4|*.png|*.jpg) AGENT="Cube"; MODEL="qwen2.5-vl" ;;
            *.txt|*.json) AGENT="Loop"; MODEL="deepseek-r1" ;;
            *) AGENT="Core"; MODEL="core:latest" ;;
        esac

        # Dispatch task
        dispatch_task "$AGENT" "$MODEL" "$NEXT"

        # Mark as in-progress
        jq --arg f "$NEXT" '(.queue[] | select(.file==$f)).status="in-progress"' "$QUEUE_FILE" > tmp.$$.json && mv tmp.$$.json "$QUEUE_FILE"
    fi

    sleep 0.5
done

