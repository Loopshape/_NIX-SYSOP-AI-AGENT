#!/usr/bin/env bash
# ai.sh — Autonomous agent orchestrator (auto-detect Ollama API support)

LOG_DIR="$HOME/_/ai/logs"
OLLAMA_API="http://127.0.0.1:11434"

mkdir -p "$LOG_DIR"

declare -A AGENT_MODEL=(
    [CUBE]="gemma3:1b"
    [CORE]="deepseek-v3.1:671b-cloud"
    [LOOP]="loop:latest"
    [LINE]="line:latest"
    [WAVE]="qwen3-vl:2b"
    [COIN]="stable-code:latest"
    [CODE]="phi:2.7b"
    [WORK]="deepseek-v3.1:671b-cloud"
)

info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }

resolve_model() {
    local agent="$1"
    local model="${AGENT_MODEL[$agent]}"
    if ! ollama list | grep -q "^$model"; then
        warn "Model '$model' not found locally. Selecting fallback..."
        model=$(ollama list | awk 'NR==2 {print $1}')
    fi
    echo "$model"
}

# Detect which Ollama endpoint is supported
detect_endpoint() {
    local model="$1"
    if ollama generate --model "$model" --prompt "test" >/dev/null 2>&1; then
        echo "generate"
    elif ollama embed --model "$model" --text "test" >/dev/null 2>&1; then
        echo "embed"
    elif ollama chat --model "$model" --message "test" >/dev/null 2>&1; then
        echo "chat"
    else
        warn "No supported API found for $model. Defaulting to generate"
        echo "generate"
    fi
}

agent_pidfile() { echo "$LOG_DIR/$1.pid"; }

start_agent() {
    local agent="$1"
    local model
    model=$(resolve_model "$agent")
    local endpoint
    endpoint=$(detect_endpoint "$model")
    local pidfile
    pidfile=$(agent_pidfile "$agent")

    info "Starting agent $agent -> model $model (endpoint: $endpoint)"
    
    nohup bash -c "\
        while true; do \
            case '$endpoint' in \
                generate) \
                    ollama generate --model '$model' --prompt '$agent agent: heartbeat' >> '$LOG_DIR/$agent.log' ;; \
                embed) \
                    ollama embed --model '$model' --text '$agent agent: heartbeat' >> '$LOG_DIR/$agent.log' ;; \
                chat) \
                    ollama chat --model '$model' --message '$agent agent: heartbeat' >> '$LOG_DIR/$agent.log' ;; \
            esac; \
            sleep 1; \
        done" >> "$LOG_DIR/$agent.log" 2>&1 &

    echo $! > "$pidfile"
    info "$agent started (pid $(cat "$pidfile"))"
}

stop_agent() {
    local agent="$1"
    local pidfile
    pidfile=$(agent_pidfile "$agent")
    if [ -f "$pidfile" ]; then
        local pid
        pid=$(cat "$pidfile")
        if ps -p "$pid" >/dev/null 2>&1; then
            info "Stopping $agent (pid $pid)"
            kill "$pid" >/dev/null 2>&1 || true
            sleep 1
            if ps -p "$pid" >/dev/null 2>&1; then
                warn "$agent did not stop; killing -9"
                kill -9 "$pid" >/dev/null 2>&1 || true
            fi
        fi
        rm -f "$pidfile"
    fi
}

start_all_agents() { for agent in "${!AGENT_MODEL[@]}"; do start_agent "$agent"; done; }
stop_all_agents() { for agent in "${!AGENT_MODEL[@]}"; do stop_agent "$agent"; done; }

status() {
    printf "%-6s %-8s %-6s\n" "AGENT" "PID" "STATE"
    for agent in "${!AGENT_MODEL[@]}"; do
        local pidfile
        pidfile=$(agent_pidfile "$agent")
        local pid state
        if [ -f "$pidfile" ]; then
            pid=$(cat "$pidfile")
            if ps -p "$pid" >/dev/null 2>&1; then
                state="UP"
            else
                state="DOWN"
            fi
        else
            pid="-"
            state="DOWN"
        fi
        printf "%-6s %-8s %-6s\n" "$agent" "$pid" "$state"
    done
}

tail_agent() {
    local agent="$1"
    local logfile="$LOG_DIR/$agent.log"
    if [ ! -f "$logfile" ]; then
        echo "[ERROR] Log for agent '$agent' not found!"
        return 1
    fi
    tail -f "$logfile"
}

case "$1" in
    start) start_all_agents ;;
    stop) stop_all_agents ;;
    restart) stop_all_agents && start_all_agents ;;
    status) status ;;
    tail)
        if [ -z "$2" ]; then
            echo "Usage: $0 tail <AGENT>"
            exit 1
        fi
        tail_agent "$2"
        ;;
    *) echo "Usage: $0 {start|stop|restart|status|tail <AGENT>}"; exit 1 ;;
esac

