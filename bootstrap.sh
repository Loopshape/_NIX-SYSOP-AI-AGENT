#!/usr/bin/env bash
# ai_launch.sh - Bootstrap + Launch AI CLI
# Ensures deps (apt > brew > npm > pip > curl > wget), then runs ~/.bin/ai

set -euo pipefail
AI_HOME="$HOME/.local_ai"
BIN_DIR="$HOME/.bin"
AI_CLI="$BIN_DIR/ai"

log() { echo -e "[\033[92mAI-BOOT\033[0m] $*"; }

install_with_apt() {
    sudo apt-get update -y
    sudo apt-get install -y python3-full sqlite3 curl wget git build-essential \
        bash nodejs npm
}

install_with_brew() {
    if command -v brew >/dev/null 2>&1; then
        brew install python sqlite curl wget git node
    fi
}

install_with_pip() {
    pip install --upgrade pip
    pip install requests rich
}

bootstrap_deps() {
    log "Checking mandatory dependencies..."

    if ! command -v python3 >/dev/null 2>&1; then
        log "Installing Python3 via apt..."
        install_with_apt
    fi
    if ! command -v sqlite3 >/dev/null 2>&1; then
        log "Installing sqlite3..."
        install_with_apt
    fi
    if ! command -v curl >/dev/null 2>&1; then
        log "Installing curl..."
        install_with_apt
    fi
    if ! command -v wget >/dev/null 2>&1; then
        log "Installing wget..."
        install_with_apt
    fi
    if ! command -v node >/dev/null 2>&1; then
        log "Installing Node.js..."
        install_with_apt
    fi
}

prepare_ai_cli() {
    mkdir -p "$AI_HOME" "$BIN_DIR"
    if [ ! -f "$AI_CLI" ]; then
        log "Installing AI CLI script..."
        cp ./ai "$AI_CLI"
        chmod +x "$AI_CLI"
    else
        log "AI CLI already installed at $AI_CLI"
    fi
}

launch_ai() {
    if [ $# -eq 0 ]; then
        log "Usage: ai_launch.sh 'your prompt'"
        exit 1
    fi
    "$AI_CLI" "$@"
}

main() {
    log "🔍 Bootstrapping AI environment..."
    bootstrap_deps
    install_with_brew || true
    install_with_pip || true
    prepare_ai_cli
    launch_ai "$@"
}

main "$@"