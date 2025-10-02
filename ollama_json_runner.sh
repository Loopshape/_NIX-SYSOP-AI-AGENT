#!/usr/bin/env bash
# Ollama JSON bidirectional runner

set -euo pipefail

MODEL="2244"
INPUT_FILE="$HOME/ollama_input.json"
OUTPUT_FILE="$HOME/ollama_output.json"

echo "[*] Starting Ollama JSON runner for model $MODEL"
echo "[*] Watching $INPUT_FILE for prompts..."

while true; do
    if [ -f "$INPUT_FILE" ]; then
        # Read prompt and parameters from input.json
        PROMPT=$(jq -r '.prompt // empty' "$INPUT_FILE")
        TEMPERATURE=$(jq -r '.parameters.temperature // 0.7' "$INPUT_FILE")
        MAX_TOKENS=$(jq -r '.parameters.max_tokens // 500' "$INPUT_FILE")

        if [ -n "$PROMPT" ]; then
            echo "[*] Running Ollama with prompt: $PROMPT"

            # Run Ollama and save output JSON
            ollama run "$MODEL" \
                --prompt "$PROMPT" \
                --temperature "$TEMPERATURE" \
                --max-tokens "$MAX_TOKENS" \
                --json > "$OUTPUT_FILE"

            echo "[✔] Output written to $OUTPUT_FILE"

            # Optionally, remove input file after processing
            rm "$INPUT_FILE"
        fi
    fi
    sleep 1
done
