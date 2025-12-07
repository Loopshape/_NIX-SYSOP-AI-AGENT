#!/usr/bin/env bash
#
# ai-init v2.2 — WSL1-stable Ollama initializer
# ZERO-FAIL startup + agent-pool bootstrap
#

############################################
### PATHS + ENV
############################################
export OLLAMA_API_URL="http://127.0.0.1:11434/api"
export AGENTS=("CUBE" "CORE" "LOOP" "LINE" "WAVE" "COIN" "CODE" "WORK")

LOGROOT="$HOME/.ollama/log"
mkdir -p "$LOGROOT"


############################################
### 1) Kill stale Ollama BEFORE anything else
############################################
reset_ollama() {
    if pgrep -f "ollama serve" >/dev/null; then
        echo "[RESET] stale Ollama → killing"
        pkill -9 -f "ollama" 2>/dev/null
        sleep 1
    fi

    # also clear port blockers
    if ss -ltnp | grep -q 11434; then
        echo "[RESET] port 11434 blocked → force clearing"
        fuser -k 11434/tcp 2>/dev/null
        sleep 1
    fi
}


############################################
### 2) Start Ollama (IPv4 only)
############################################
start_ollama() {
    echo "[OLLAMA] booting"

    reset_ollama

    nohup ollama serve --host 127.0.0.1 \
        >>"$LOGROOT/ollama-serve.log" 2>&1 &

    sleep 1
}


############################################
### 3) Wait until API ready
############################################
wait_for_api() {
    echo -n "[OLLAMA] waiting for API "

    for i in {1..20}; do
        if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
            echo " → READY"
            return 0
        fi
        echo -n "."
        sleep 1
    done

    echo " → TIMEOUT"
    return 1
}


############################################
### 4) Agent Pool Registration
############################################
init_agents() {
    echo "[POOL] registering 2Pi/8-state pool"

    for agent in "${AGENTS[@]}"; do
        echo "[POOL] $agent → available"
        export "AGENT_${agent}=http://127.0.0.1:11434/api/generate"
    done
}


############################################
### EXECUTION PIPELINE
############################################
echo "[AI-INIT] v2.2 starting"

start_ollama
wait_for_api

if [ $? -eq 0 ]; then
    init_agents
    echo "[AI-INIT] COMPLETE — all agents online"
else
    echo "[AI-INIT] ERROR — Ollama failed to start"
fi

