#!/usr/bin/env bash
set -e
export NEXUS_HOME="$HOME/nexus"
cd "$NEXUS_HOME"

# Launch all components
node js/nexus.mjs &
python3 ai_memory.py &
ollama serve &

wait
