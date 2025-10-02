#!/usr/bin/env bash
set -euo pipefail

echo "[*] Starting Ollama JSON automation installer..."

# Base directory for Ollama runners
RUNNER_DIR="$HOME/ollama_runner"
mkdir -p "$RUNNER_DIR"

# ----------------------
# 1️⃣ Single-prompt runner
# ----------------------
cat > "$RUNNER_DIR/single_runner.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
MODEL="2244"
INPUT_FILE="$HOME/ollama_runner/input.json"
OUTPUT_FILE="$HOME/ollama_runner/output.json"
echo "[*] Starting Ollama single-prompt runner..."
while true; do
    if [ -f "$INPUT_FILE" ]; then
        PROMPT=$(jq -r '.prompt // empty' "$INPUT_FILE")
        TEMPERATURE=$(jq -r '.parameters.temperature // 0.7' "$INPUT_FILE")
        MAX_TOKENS=$(jq -r '.parameters.max_tokens // 500' "$INPUT_FILE")
        if [ -n "$PROMPT" ]; then
            echo "[*] Running prompt: $PROMPT"
            ollama run "$MODEL" --prompt "$PROMPT" --temperature "$TEMPERATURE" --max-tokens "$MAX_TOKENS" --json > "$OUTPUT_FILE"
            echo "[✔] Output written to $OUTPUT_FILE"
            rm "$INPUT_FILE"
        fi
    fi
    sleep 1
done
SH

chmod +x "$RUNNER_DIR/single_runner.sh"

# ----------------------
# 2️⃣ Batch runner
# ----------------------
cat > "$RUNNER_DIR/batch_runner.sh" <<'SH'
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
            RESPONSE_JSON=$(ollama run "$MODEL" --prompt "$PROMPT" --temperature "$TEMPERATURE" --max-tokens "$MAX_TOKENS" --json)
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
SH

chmod +x "$RUNNER_DIR/batch_runner.sh"

# ----------------------
# 3️⃣ Start with pm2
# ----------------------
echo "[*] Starting pm2 processes..."
pm2 start "$RUNNER_DIR/single_runner.sh" --name ollama-single
pm2 start "$RUNNER_DIR/batch_runner.sh" --name ollama-batch
pm2 save

# ----------------------
# 4️⃣ Termux:Boot integration
# ----------------------
BOOT_DIR="$HOME/.termux/boot"
mkdir -p "$BOOT_DIR"
cat > "$BOOT_DIR/ollama-boot.sh" <<'SH'
#!/data/data/com.termux/files/usr/bin/env bash
sleep 5
pm2 resurrect
echo "[✔] pm2 restored, Ollama runners are active"
SH
chmod +x "$BOOT_DIR/ollama-boot.sh"

echo "[✅] Ollama JSON automation installer completed!"
echo "[*] Directories: $RUNNER_DIR"
echo "[*] Input files: input.json (single), input_batch.json (batch)"
echo "[*] Output files: output.json (single), output_batch.json (batch)"
echo "[*] pm2 processes saved and will auto-start at boot via Termux:Boot"
