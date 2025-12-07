#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ORCH="$ROOT/orchestrator/nexus-orchestrator-v2.sh"
DIST="$ROOT/dist"
LOGS="$ROOT/orchestrator/logs"
GENESIS="$ROOT/orchestrator/genesis/genesis.sha256"

mkdir -p "$DIST" "$LOGS"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

#####################################
# VERIFY ORCHESTRATOR
#####################################
if [ ! -f "$ORCH" ]; then
    echo "[ERR] Orchestrator not found at $ORCH"
    echo "Run ./installer.sh first"
    exit 1
fi

#####################################
# COMMANDS
#####################################
CMD="${1:-}"

case "$CMD" in
  init)
    log "[AI] init → scanning snippets and templates"
    "$ORCH" scan
    ;;

  build)
    log "[AI] build → assembling templates into dist/"
    "$ORCH" assemble-template
    if [ -f "$GENESIS" ]; then
        log "[AI] current genesis hash: $(cat "$GENESIS")"
    fi
    ;;

  run)
    log "[AI] run → opening dist/index.html"
    if [ -f "$DIST/index.html" ]; then
        xdg-open "$DIST/index.html" >/dev/null 2>&1 || open "$DIST/index.html" >/dev/null 2>&1 || echo "[WARN] Unable to auto-open file"
    else
        echo "[ERR] dist/index.html not found — run 'ai build' first"
        exit 1
    fi
    ;;

  watch)
    log "[AI] watch → live assembly every 2 seconds"
    while true; do
        "$ORCH" assemble-template >/dev/null 2>&1
        sleep 2
    done
    ;;

  auto)
    log "[AI] auto → scan + build + run"
    "$ORCH" scan
    "$ORCH" assemble-template
    if [ -f "$DIST/index.html" ]; then
        xdg-open "$DIST/index.html" >/dev/null 2>&1 || open "$DIST/index.html" >/dev/null 2>&1 || echo "[WARN] Unable to auto-open file"
    fi
    ;;

  *)
    echo "Usage: $0 {init|build|run|watch|auto}"
    exit 0
    ;;
esac

