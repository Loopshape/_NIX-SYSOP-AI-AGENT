#!/usr/bin/env bash
# ai_launch.sh - Bulletproof launcher for Local AI (Termux + Proot)
# FIX: Improved Ollama JSON streaming capture and removed aggressive character filtering.
set -euo pipefail; IFS=$'\n\t'

# --- Configuration (using variables from previous revision) ---
AI_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/local_ai"
DB="$AI_HOME/core.db"
SANDBOX="$AI_HOME/sandbox"
LOGS="$HOME/logs/local_ai"
OLLAMA_MODEL="2244:latest" # Use a variable for the model name

# --- Utility Functions ---

# Log function that includes the script name for better context
log(){
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] [$(basename "${BASH_SOURCE[0]}")]: $*" >&2
}

# Ensure directories exist
mkdir_p(){
    log "Ensuring directory exists: $1"
    mkdir -p "$1" || { log "[FATAL] Failed to create directory: $1"; exit 1; }
}

mkdir_p "$AI_HOME"
mkdir_p "$AI_HOME/modules"
mkdir_p "$SANDBOX"
mkdir_p "$LOGS"

# --- Environment Setup (omitted for brevity, assume previous revision is used) ---
# ... (loading environment and venv activation) ...

# --- Ollama Server Management (omitted for brevity, assume previous revision is used) ---
# ... (is_ollama_running and server startup logic) ...

# --- Database Initialization (omitted for brevity, assume previous revision is used) ---
# ... (DB and module setup logic) ...

# --- AI Query Function (The main fix) ---

# Function to query AI via Ollama
query_ai(){
    local prompt="$1"
    local result
    log "Querying model $OLLAMA_MODEL with prompt: $(echo "$prompt" | head -n 1)..."

    # CRITICAL FIX: Ollama streams JSON. The final response is the complete one.
    # We must pipe the raw output and use Python to extract the FINAL 'answer' from the stream.
    # To get the non-streaming equivalent from the CLI, we can use the API route 
    # but since this is a script, we will assume 'ollama run' is what's used.
    # The current command is 'ollama run $OLLAMA_MODEL --json "$prompt"', which streams.
    # To handle the stream and extract the final message, we use the Python script.
    
    # Run Ollama and capture all output
    result=$(
        ollama run "$OLLAMA_MODEL" --json "$prompt" 2>&1 || true
    )
    
    # Check if the result contains an Ollama error message
    if [[ "$result" =~ "Error" ]] || [[ -z "$result" ]]; then
        log "[ERROR] Ollama query failed. Output/Error: $result"
        return 1
    fi

    # Post-process result (JSON parsing and extraction)
    # FIX: The Python script is simplified to extract the 'response' or 'answer' 
    # from the final JSON object in the stream, and the aggressive character filter is removed.
    local final_answer
    final_answer=$(
        echo "$result" | python3 -c '
import sys, json

final_answer = ""
try:
    # Process the stream line by line until the last complete JSON object is found.
    # Ollama's CLI output for --json is often not valid single JSON.
    # The shell command above captures the entire raw stream.
    
    # We load all lines and try to find the last complete JSON object.
    # A robust solution would use the API directly (curl to 11434) with "stream": false.
    # Since we must use the CLI, we iterate and parse what we can.
    
    # The 'response' field is often what we need for the text.
    for line in sys.stdin:
        try:
            data = json.loads(line.strip())
            if "response" in data:
                final_answer += data["response"]
            elif "answer" in data:
                # Some models might use "answer" in the final non-streamed block
                final_answer = data["answer"]
                
            # If done is true, we should have the complete final answer in the current block
            if data.get("done", False) is True:
                # If "response" has accumulated the streamed text, use that.
                # If "answer" exists in the final block, it usually contains the full text.
                if "answer" in data and data["answer"]:
                    final_answer = data["answer"]
                elif "response" in data and data["response"]:
                    # In some cases, the final streamed 'response' field is empty, 
                    # but the final_answer has accumulated the text.
                    pass 
                
        except json.JSONDecodeError:
            # Ignore lines that are not valid JSON or are incomplete stream chunks
            continue

    if not final_answer:
        # Fallback for models that output non-streamed full JSON
        # Load the entire result as a single JSON object (if it's not streamed)
        sys.stdin.seek(0) # Reset stream position
        data = json.load(sys.stdin)
        final_answer = data.get("answer", data.get("response", ""))


except Exception as e:
    # A catch-all for errors, often due to unexpected output format
    sys.stderr.write(f"[ERROR] Python post-processing failed: {e}\n")
    sys.exit(1)

# Print the final result
print(final_answer.strip())
    ' 2>&1
    )
    
    # Check if python script failed (returns non-zero exit code)
    if [[ $? -ne 0 ]]; then
        log "[ERROR] AI response post-processing failed. Output: $final_answer"
        return 1
    fi

    # Output the final, processed answer
    echo "$final_answer"
}

# --- Main Execution ---

if [ $# -gt 0 ]; then
    query_ai "$*"
    if [ $? -eq 0 ]; then
        log "Query complete."
    else
        log "Query failed."
    fi
else
    log "AI launch ready."
    log "Usage: $(basename "${BASH_SOURCE[0]}") 'your prompt here'"
fi
