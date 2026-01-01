#!/usr/bin/env bash
set -euo pipefail

PROMPT="$*"
MAX_DEPTH=5
DEPTH=0

MODEL="${AI_MODEL:-deepseek-r1}"
BASE="$HOME/_/ai/recursive"
mkdir -p "$BASE"

log() { echo "[recursive] $*"; }

run_step() {
  local prompt="$1"
  local depth="$2"
  local dir="$BASE/step_$depth"
  mkdir -p "$dir"

  log "DEPTH $depth"

  ollama run "$MODEL" <<EOF >"$dir/response.json"
You are an autonomous tool orchestrator.

RULES:
- Output ONLY valid JSON
- You may request tools
- If finished, set "done": true
- NEVER explain

PROMPT:
$prompt
EOF

  jq . "$dir/response.json" >/dev/null || {
    echo "[recursive] invalid json" >&2
    exit 1
  }

  jq -e '.done == true' "$dir/response.json" >/dev/null && {
    log "DONE at depth $depth"
    return 0
  }

  jq -c '.request_tools[]?' "$dir/response.json" | while read -r call; do
    tool=$(jq -r '.tool' <<<"$call")
    args=$(jq -r '.args' <<<"$call")

    log "CALL → $tool $args"

    "$HOME/_/ai/tools/$tool.sh" $args \
      >"$dir/$tool.out" 2>&1
  done
}

while [ "$DEPTH" -lt "$MAX_DEPTH" ]; do
  run_step "$PROMPT" "$DEPTH" || break
  PROMPT="Continue from previous state."
  DEPTH=$((DEPTH+1))
done

log "RECURSION HALTED"

