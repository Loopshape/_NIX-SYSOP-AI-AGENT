# ~/.bashrc: Executed by bash(1) for non-login shells.
# Refactored for WSL1 Debian + Ollama Slim-Edition + 2Pi/8-Agents (ZEN/AI)

# =============================================================================
# 1. INTERACTIVE CHECK
# =============================================================================
case $- in
    *i*) ;;
      *) return;;
esac

# =============================================================================
# 2. HISTORY & WINDOW SETTINGS
# =============================================================================
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# =============================================================================
# 3. PROMPT & COLOR SETTINGS
# =============================================================================
force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# =============================================================================
# 4. EXTERNAL TOOLS (Brew, NVM)
# =============================================================================
# Linuxbrew
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# =============================================================================
# 5. OLLAMA SLIM-EDITION STARTUP (WSL1 Optimization)
# =============================================================================
# Configuration for "Slim" Resource Usage on WSL1
export OLLAMA_HOST="http://localhost:11434"
export OLLAMA_KEEP_ALIVE="5m"  # Unload models quickly to save RAM
export OLLAMA_MAX_LOADED_MODELS="1" # Prevent OOM on WSL1

# Check if Ollama is running; if not, start it in background
if ! pgrep -x "ollama" > /dev/null; then
    echo "[System] Starting Ollama (Slim-Edition)..."
    # Start server with low VRAM overhead preference if possible (implicit in some versions)
    # Redirect logs to tmp to avoid console noise, but keep accessible
    nohup ollama serve > ~/.gemini/tmp/ollama.log 2>&1 &
    
    # Wait briefly for startup
    sleep 2
    if pgrep -x "ollama" > /dev/null; then
        echo "[System] Ollama active (PID: $(pgrep -x ollama))"
    else
        echo "[Warning] Ollama failed to start automatically."
    fi
else
    # echo "[System] Ollama is already running."
    :
fi

# =============================================================================
# 6. AI AGENT ENVIRONMENT (2Pi/8 Shifted Entropy)
# =============================================================================
export AI_DIR="$HOME/_/ai"
export PATH="$PATH:$AI_DIR"

# Agent Configuration
export ZEN_ROOT="$AI_DIR"
export TOKEN_STREAM_MODE="verbose"   # Enable verbose token streaming
export PARALLEL_REASONING_MODE="on"  # Enable concurrent thinking
export MAX_CONCURRENT_AGENTS="4"     # Limit parallel jobs for WSL1 stability

# Aliases
# Point 'ai' to the integrated v3.3 script
alias ai="$AI_DIR/ai.sh"
alias zen="$AI_DIR/ai.sh" 

# Status function
ai_status() {
    echo "=== AI System Status ==="
    echo "Ollama: $(pgrep -x ollama >/dev/null && echo 'Running' || echo 'Stopped')"
    echo "Agent Script: $(which ai)"
    echo "Token Stream: $TOKEN_STREAM_MODE"
    echo "Reasoning:    $PARALLEL_REASONING_MODE"
}

# Auto-complete for 'ai' command (basic)
complete -W "reason refactor batch scan analyze files recall stats cleanup export agents models help" ai

# =============================================================================
# 7. FINALIZATION
# =============================================================================
# If a local python env exists (from .profile), activate it for ZEN python deps
if [ -f ".env.local/bin/activate" ]; then
    source .env.local/bin/activate
fi
