#!/usr/bin/env bash
set -e
mkdir -p entropy memory

GENESIS=$(date +%s%N | sha256sum | cut -d' ' -f1)
PROMPT="$*"

echo "{ \"genesis\": \"$GENESIS\" }" > memory/memory.json

declare -A AGENTS
AGENTS[coder]="deepseek-coder"
AGENTS[agi]="deepseek-r1"
AGENTS[nemodian]="wave"
AGENTS[sysop]="llama3.1"

stream_agent() {
  name=$1
  model=$2
  # Note: ollama must be running and have the models
  ollama run "$model" "$PROMPT" --stream | while read -r token; do
    echo "$token" >> entropy/$name.stream
    sha=$(echo -n "$token" | sha256sum | cut -d' ' -f1)
    md5=$(echo -n "$sha" | md5sum | cut -d' ' -f1)

    node -e "
      import {broadcast} from './server.js';
      broadcast('$name','$token','$sha','$GENESIS','$md5');
    "
  done

  cat entropy/$name.stream | python3 vector.js
}

# Start server in background? The prompt doesn't explicitly say how server.js runs, 
# but ai.sh calls broadcast. This implies server.js might need to be imported or run separately.
# Actually, the 'node -e' command imports from './server.js'. 
# This means server.js must export broadcast and also start the WebSocket server when imported.
# My server.js does start the server on import (it creates wss).

for a in "${!AGENTS[@]}"; do
  stream_agent "$a" "${AGENTS[$a]}" &
done
wait