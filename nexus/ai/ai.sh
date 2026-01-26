#!/usr/bin/env bash
set -e
export NEXUS_HOME="/home/loop/_/nexus"
cd "$NEXUS_HOME"

# Launch all components
node js/nexus.mjs &
python3 ai/ai_memory.py &
ollama serve &

wait
