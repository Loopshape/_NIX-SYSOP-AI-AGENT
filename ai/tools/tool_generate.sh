#!/usr/bin/env bash
set -euo pipefail

PROMPT="$*"
[ -z "$PROMPT" ] && {
  echo "[tool_generate] missing prompt" >&2
  exit 1
}

BASE_DIR="$HOME/_/ai/generated"
TS=$(date +%s)
OUT_DIR="$BASE_DIR/gen_$TS"

mkdir -p "$OUT_DIR"

MANIFEST="$OUT_DIR/_manifest.json"
RAW="$OUT_DIR/_raw.txt"

MODEL="${AI_MODEL:-deepseek-r1}"

# ---------------------------
# System instruction
# ---------------------------
read -r -d '' SYSTEM <<'EOF'
You are an autonomous code generator.
You MUST:
- Decide file names
- Decide language
- Output ONLY valid code blocks
- Use format:

===FILE:<path>===
<code>

No explanations.
No markdown.
EOF

# ---------------------------
# Generate
# ---------------------------
ollama run "$MODEL" <<EOF >"$RAW"
$SYSTEM

TASK:
$PROMPT
EOF

# ---------------------------
# Parse + write files
# ---------------------------
current=""
while IFS= read -r line; do
  if [[ "$line" =~ ^===FILE:(.+)=== ]]; then
    current="$OUT_DIR/${BASH_REMATCH[1]}"
    mkdir -p "$(dirname "$current")"
    : >"$current"
    continue
  fi
  [ -n "$current" ] && echo "$line" >>"$current"
done <"$RAW"

# ---------------------------
# Manifest
# ---------------------------
jq -n \
  --arg prompt "$PROMPT" \
  --arg model "$MODEL" \
  --arg dir "$OUT_DIR" \
  '{
     prompt: $prompt,
     model: $model,
     output_dir: $dir,
     generated_at: now
   }' >"$MANIFEST"

echo "[tool_generate] OK → $OUT_DIR"

