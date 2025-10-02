#!/usr/bin/env bash
# Batch JSON Ollama runner

set -euo pipefail

MODEL="2244"
INPUT_FILE="$HOME/ollama_input_batch.json"
OUTPUT_FILE="$HOME/ollama_output_batch.json"

echo "[*] Starting Ollama JSON batch runner for model $MODEL"
echo "[*] Watching $INPUT_FILE for new batch prompts..."

while true; do
    if [ -f "$INPUT_FILE" ]; then
        echo "[*] Detected batch input file: $INPUT_FILE"

        # Initialize output JSON array
        echo "[" > "$OUTPUT_FILE"

        # Count total prompts
        TOTAL=$(jq 'length' "$INPUT_FILE")
        INDEX=0

        # Loop through each prompt object
        jq -c '.[]' "$INPUT_FILE" | while read -r item; do
            PROMPT=$(echo "$item" | jq -r '.prompt')
            TEMPERATURE=$(echo "$item" | jq -r '.parameters.temperature // 0.7')
            MAX_TOKENS=$(echo "$item" | jq -r '.parameters.max_tokens // 500')

            echo "[*] Running prompt: $PROMPT"

            RESPONSE_JSON=$(ollama run "$MODEL" \
                --prompt "$PROMPT" \
                --temperature "$TEMPERATURE" \
                --max-tokens "$MAX_TOKENS" \
                --json)

            # Add comma between elements if not last
            INDEX=$((INDEX + 1))
            if [ $INDEX -lt $TOTAL ]; then
                echo "$RESPONSE_JSON," >> "$OUTPUT_FILE"
            else
                echo "$RESPONSE_JSON" >> "$OUTPUT_FILE"
            fi
        done

        # Close JSON array
        echo "]" >> "$OUTPUT_FILE"

        echo "[✔] Batch output written to $OUTPUT_FILE"

        # Remove input file after processing
        rm "$INPUT_FILE"
    fi
    sleep 1
done
