#!/usr/bin/env bash
set -euo pipefail

MODEL="2244"
INPUT_FILE="$HOME/ollama_runner/input_batch.json"
OUTPUT_FILE="$HOME/ollama_runner/output_batch.json"

echo "[*] Starting Ollama batch runner..."

while true; do
    if [ -f "$INPUT_FILE" ]; then
        echo "[*] Detected batch input file: $INPUT_FILE"

        echo "[" > "$OUTPUT_FILE"
        TOTAL=$(jq 'length' "$INPUT_FILE")
        INDEX=0

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

            INDEX=$((INDEX + 1))
            if [ $INDEX -lt $TOTAL ]; then
                echo "$RESPONSE_JSON," >> "$OUTPUT_FILE"
            else
                echo "$RESPONSE_JSON" >> "$OUTPUT_FILE"
            fi
        done

        echo "]" >> "$OUTPUT_FILE"
        echo "[✔] Batch output written to $OUTPUT_FILE"
        rm "$INPUT_FILE"
    fi
    sleep 1
done
