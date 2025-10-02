#!/bin/bash
OUTPUT_FILE=~/ollama_batch.json
PROMPTS=("Hello world" "Summarize AI news" "Explain blockchain in simple terms")

echo "[" > $OUTPUT_FILE
for i in "${!PROMPTS[@]}"; do
    RESPONSE=$(ollama query 2244 "${PROMPTS[$i]}" --json)
    echo "$RESPONSE" >> $OUTPUT_FILE
    if [ $i -lt $((${#PROMPTS[@]}-1)) ]; then
        echo "," >> $OUTPUT_FILE
    fi
done
echo "]" >> $OUTPUT_FILE
