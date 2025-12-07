#!/usr/bin/env bash
# ai.sh - Autonomous Orchestration Launcher
set -euo pipefail
IFS=$'\n\t'

# ---------------- CONFIG ----------------
BASE_DIR="${BASE_DIR:-$HOME/_/ai/local-core}"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/ai_projects}"

# ---------------- ARGUMENTS ----------------
VERBOSE=false
PROMPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) VERBOSE=true; shift ;;
        *) PROMPT="$1"; shift ;;
    esac
done

if [[ -z "$PROMPT" ]]; then
    echo "Usage: $0 [--verbose] <prompt>"
    exit 1
fi

# ---------------- PROJECT FOLDER ----------------
TS=$(date +%s)
PROJECT_FOLDER="$PROJECTS_DIR/nemodian-qfai-$TS"
mkdir -p "$PROJECT_FOLDER"
$VERBOSE && echo "[ai.sh] Project folder: $PROJECT_FOLDER"

# ---------------- AGENT EXECUTION ----------------
AGENTS=("core" "loop" "wave" "coin" "code")
for agent in "${AGENTS[@]}"; do
    AGENT_JS="$BASE_DIR/agents/$agent.js"
    if [[ ! -f "$AGENT_JS" ]]; then
        echo "[ai.sh] Warning: agent $agent.js not found, skipping"
        continue
    fi
    $VERBOSE && echo "[ai.sh] Running agent: $agent"
    node "$AGENT_JS" "$PROMPT" "$PROJECT_FOLDER/$agent.json"
done

# ---------------- FUSION ORCHESTRATION ----------------
$VERBOSE && echo "[ai.sh] Starting orchestration / fusion"
node "$BASE_DIR/generate.js" "$PROJECT_FOLDER"

# ---------------- FINAL OUTPUT ----------------
FINAL_ANSWER="$PROJECT_FOLDER/final_answer.txt"
$VERBOSE && echo "[ai.sh] Final answer is saved at: $FINAL_ANSWER"
cat "$FINAL_ANSWER"

