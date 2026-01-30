#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "[NEXUS] Installer starting at $ROOT"

#############################################
# 1) DEPENDENCY CHECK + INSTALL (Debian/WSL)
#############################################
ensure_dep() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[NEXUS] Installing dependency: $1"
    sudo apt-fast install -y "$1" || sudo apt install -y "$1"
  fi
}

echo "[NEXUS] Checking system dependencies..."
ensure_dep jq
ensure_dep curl
ensure_dep git
ensure_dep sed
ensure_dep awk
ensure_dep docker.io

# Ollama is installed manually by user — only check existence
if ! command -v ollama >/dev/null 2>&1; then
  echo "[WARN] Ollama not found in PATH — skipping"
else
  echo "[NEXUS] Ollama detected"
fi


#############################################
# 2) CREATE UNIFIED PROJECT STRUCTURE
#############################################
create_dir() {
  mkdir -p "$ROOT/$1"
  echo "  created: $1"
}

echo "[NEXUS] Creating unified CODERS-AI + NEXUS project tree..."

create_dir agents
create_dir agents/core
create_dir agents/loop
create_dir agents/wave
create_dir agents/coin
create_dir agents/code

create_dir orchestrator
create_dir orchestrator/manifest
create_dir orchestrator/genesis
create_dir orchestrator/assemble
create_dir orchestrator/logs
create_dir orchestrator/tmp
create_dir orchestrator/chunks

create_dir snippets
create_dir snippets/html
create_dir snippets/js
create_dir snippets/css

create_dir templates
create_dir dist
create_dir src


#############################################
# 3) INSTALL ORCHESTRATOR ENGINE
#############################################
if [ -f "$ROOT/orchestrator/nexus-orchestrator-v1.sh" ]; then
  echo "[NEXUS] Orchestrator already installed → skipping"
else
  echo "[NEXUS] Installing NEXUS Orchestrator v1..."

  cat > "$ROOT/orchestrator/nexus-orchestrator-v1.sh" <<'EOF'
#!/usr/bin/env bash
# Placeholder — the full orchestrator code is stored in canvas editor.
# This installer only prepares the folder structure.
echo "[NEXUS] Orchestrator placeholder executed (replace with canvas version)"
EOF

  chmod +x "$ROOT/orchestrator/nexus-orchestrator-v1.sh"
fi


#############################################
# 4) WRITE INITIAL GENESIS HASH
#############################################
GENESIS="$ROOT/orchestrator/genesis/genesis.sha256"

if [ ! -f "$GENESIS" ]; then
  echo "[NEXUS] Creating genesis hash…"
  date +%s | sha256sum | awk '{print $1}' > "$GENESIS"
else
  echo "[NEXUS] Genesis hash already exists → $GENESIS"
fi


#############################################
# 5) INSTALL MAIN CODERS-AI LAUNCHER
#############################################
if [ ! -f "$ROOT/main.sh" ]; then
  echo "[NEXUS] Writing CODERS-AI main.sh"
  cat > "$ROOT/main.sh" <<'EOF'
#!/usr/bin/env bash
set -e

CMD="$1"
ROOT="$(cd "$(dirname "$0")" && pwd)"
ORCH="$ROOT/orchestrator/nexus-orchestrator-v1.sh"

case "$CMD" in
  init)
    echo "[AI] init → scanning and building manifest"
    "$ORCH" scan
    ;;

  build)
    echo "[AI] build → assembling (templating) content"
    "$ORCH" assemble-template
    ;;

  run)
    echo "[AI] run → launching output in dist/"
    if [ -f "$ROOT/dist/index.html" ]; then
      xdg-open "$ROOT/dist/index.html" || true
    else
      echo "[ERR] No dist/index.html found — build first."
    fi
    ;;

  watch)
    echo "[AI] watch → live reassemble every 2s"
    while true; do
      "$ORCH" assemble-template >/dev/null 2>&1
      sleep 2
    done
    ;;

  auto)
    echo "[AI] auto → scan + build + run"
    "$ORCH" scan
    "$ORCH" assemble-template
    xdg-open "$ROOT/dist/index.html" || true
    ;;

  *)
    echo "Usage: ./main.sh {init|build|run|watch|auto}"
    exit 0
    ;;
esac
EOF

  chmod +x "$ROOT/main.sh"
fi


#############################################
# 6) CREATE GLOBAL "ai" COMMAND SYMLINK
#############################################
if [ ! -L "$HOME/bin/ai" ]; then
  mkdir -p "$HOME/bin"
  ln -sf "$ROOT/main.sh" "$HOME/bin/ai"
  echo "[NEXUS] Created global launcher: ~/bin/ai"
else
  echo "[NEXUS] Global launcher already exists"
fi


#############################################
# 7) FINAL MESSAGE
#############################################
echo ""
echo "[NEXUS] Installation complete."
echo "You can now run:"
echo ""
echo "    ai init"
echo "    ai build"
echo "    ai run"
echo "    ai watch"
echo "    ai auto"
echo ""
echo "[NEXUS] Ready."

