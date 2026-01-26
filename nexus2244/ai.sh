#!/usr/bin/env bash
set -e
mkdir -p entropy memory

GENESIS=$(date +%s%N | sha256sum | cut -d' ' -f1)
PROMPT="$*"

echo "{ \"genesis\": \"$GENESIS\" }" > memory/memory.json

declare -A AGENTS
AGENTS[cube]="gemma3:1b"
AGENTS[core]="deepseek-v3.1:671b-cloud"
AGENTS[loop]="loop:latest"
AGENTS[line]="line:latest"
AGENTS[wave]="qwen3-vl:2b"
AGENTS[coin]="stable-code:latest"
AGENTS[code]="phi:2.7b"
AGENTS[work]="deepseek-v3.1:671b-cloud"

stream_agent() {
  name=$1
  model=$2
  
  # Ensure the stream file exists
  touch "entropy/$name.stream"
  
  ollama run "$model" "$PROMPT" | while read -r token; do
    echo -n "$token" >> "entropy/$name.stream"
    sha=$(echo -n "$token" | sha256sum | cut -d' ' -f1)
    md5=$(echo -n "$sha" | md5sum | cut -d' ' -f1)

    node -e "
      import {broadcast} from './server.js';
      broadcast('$name','$(echo -n "$token" | sed "s/'/\\'/g")','$sha','$GENESIS','$md5');
    " 2>/dev/null || true
  done

  if [ -f "entropy/$name.stream" ]; then
    cat "entropy/$name.stream" | python3 vector.js || true
  fi
}

for a in "${!AGENTS[@]}"; do
  stream_agent "$a" "${AGENTS[$a]}" &
done
wait
