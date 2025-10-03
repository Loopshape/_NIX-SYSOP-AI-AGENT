#!/usr/bin/env bash
# ai_launch.sh - Bootstrap + Self-Healing + Launch AI CLI with colored logging

set -euo pipefail
AI_HOME="$HOME/.local_ai"
BIN_DIR="$HOME/.bin"
AI_CLI="$BIN_DIR/ai"
REPO_DIR="$HOME/_NIX-SYSOP-AI-AGENT-by-Aris-Arjuna-Noorsanto"
LOG_DIR="$AI_HOME/logs"
LOG_FILE="$LOG_DIR/ai_boot.log"

mkdir -p "$LOG_DIR"

# --- ANSI colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
RESET="\033[0m"

log() {
    local type="$1"; shift
    local msg="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    case "$type" in
        info)  echo -e "${CYAN}[$timestamp] [INFO]${RESET} $msg" | tee -a "$LOG_FILE" ;;
        success) echo -e "${GREEN}[$timestamp] [OK]${RESET} $msg" | tee -a "$LOG_FILE" ;;
        warn)  echo -e "${YELLOW}[$timestamp] [WARN]${RESET} $msg" | tee -a "$LOG_FILE" ;;
        error) echo -e "${RED}[$timestamp] [ERROR]${RESET} $msg" | tee -a "$LOG_FILE" ;;
        *) echo -e "[$timestamp] $msg" | tee -a "$LOG_FILE" ;;
    esac
}

# ---- Dependencies ----
install_with_apt() {
    log info "Installing mandatory dependencies via apt..."
    sudo apt-get update -y
    sudo apt-get install -y python3-full sqlite3 curl wget git build-essential bash nodejs npm
}

install_with_brew() {
    command -v brew >/dev/null 2>&1 && brew install python sqlite curl wget git node
}

install_with_pip() {
    pip install --upgrade pip
    pip install requests rich
}

bootstrap_deps() {
    log info "Checking mandatory dependencies..."
    command -v python3 >/dev/null 2>&1 || install_with_apt
    command -v sqlite3 >/dev/null 2>&1 || install_with_apt
    command -v curl >/dev/null 2>&1 || install_with_apt
    command -v wget >/dev/null 2>&1 || install_with_apt
    command -v node >/dev/null 2>&1 || install_with_apt
}

# ---- Self-Healing CLI ----
prepare_ai_cli() {
    mkdir -p "$AI_HOME" "$BIN_DIR"
    if [ ! -f "$AI_CLI" ]; then
        log info "Copying AI CLI from repo..."
        cp "$REPO_DIR/ai" "$AI_CLI"
        chmod +x "$AI_CLI"
        log success "AI CLI installed"
    else
        if [ "$REPO_DIR/ai" -nt "$AI_CLI" ]; then
            log info "Updating AI CLI from repo..."
            cp "$REPO_DIR/ai" "$AI_CLI"
            chmod +x "$AI_CLI"
            log success "AI CLI updated"
        fi
    fi
}

# ---- Self-Healing Modules ----
update_modules() {
    mkdir -p "$AI_HOME/modules"
    for mod in blockchain nostr lightning termux proot url-parser snippet-assembler; do
        repo_mod="$REPO_DIR/modules/$mod.sh"
        local_mod="$AI_HOME/modules/$mod.sh"
        if [ ! -f "$local_mod" ] || [ "$repo_mod" -nt "$local_mod" ]; then
            log info "Updating module $mod..."
            cp "$repo_mod" "$local_mod"
            chmod +x "$local_mod"
            log success "Module $mod updated"
        fi
    done
}

# ---- Launch CLI ----
launch_ai() {
    if [ $# -eq 0 ]; then
        log warn "Usage: ai_launch.sh 'your prompt'"
        exit 1
    fi
    log info "Launching AI CLI with prompt: $*"
    "$AI_CLI" "$@"
    log success "AI CLI finished execution"
}

# ---- Main ----
main() {
    log info "🔍 Bootstrapping AI environment..."
    bootstrap_deps
    install_with_brew || true
    install_with_pip || true
    prepare_ai_cli
    update_modules
    launch_ai "$@"
}

main "$@"