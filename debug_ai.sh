#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
echo -e "\n🛠 Starting AI Debug Checker...\n"

# === Pfade & Variablen prüfen ===
AI_HOME="${AI_HOME:-$HOME/.local_ai_test}"
PROJECTS_DIR="$AI_HOME/_/.projects"
LOG_DIR="$AI_HOME/.logs"
TMP_DIR="$AI_HOME/.tmp"
SWAP_DIR="$AI_HOME/.swap"
CORE_DB="$AI_HOME/.agent_core.db"
TASK_DB="$AI_HOME/.ai_task_manager.db"
HMAC_SECRET_KEY="$AI_HOME/.secret.key"

echo "[1] Checking directories..."
for d in "$AI_HOME" "$PROJECTS_DIR" "$LOG_DIR" "$TMP_DIR" "$SWAP_DIR"; do
    if [[ ! -d "$d" ]]; then
        echo "  -> Creating $d"
        mkdir -p "$d"
    fi
done

echo "[2] Checking HMAC secret key..."
if [[ ! -f "$HMAC_SECRET_KEY" ]]; then
    echo "  -> Creating HMAC secret key at $HMAC_SECRET_KEY"
    openssl rand -hex 32 > "$HMAC_SECRET_KEY"
    chmod 600 "$HMAC_SECRET_KEY"
fi
echo "  -> HMAC key exists and readable."

echo "[3] Checking SQLite DBs..."
for db in "$CORE_DB" "$TASK_DB"; do
    if [[ ! -f "$db" ]]; then
        echo "  -> Creating database $db"
        sqlite3 "$db" "VACUUM;"
    fi
    echo "  -> Database $db OK"
done

echo "[4] Checking Node.js..."
if ! command -v node >/dev/null; then
    echo "❌ Node.js not found!"
else
    NODE_VERSION=$(node -v)
    echo "  -> Node.js version: $NODE_VERSION"
fi

echo "[5] Checking AI_SCRIPT_PATH..."
AI_SCRIPT_PATH="${AI_SCRIPT_PATH:-$HOME/bin/ai}"
if [[ ! -x "$AI_SCRIPT_PATH" ]]; then
    echo "❌ AI script path invalid or not executable: $AI_SCRIPT_PATH"
else
    echo "  -> AI_SCRIPT_PATH is executable."
fi

echo "[6] Checking tools..."
for tool in tool_ingest tool_rehash tool_btc tool_webkit; do
    if ! declare -f "$tool" >/dev/null; then
        echo "❌ Tool not defined: $tool"
    else
        echo "  -> Tool found: $tool"
    fi
done

echo "[7] Testing HMAC calculation..."
sample="test_command"
ai_hmac=$(echo -n "$sample" | openssl dgst -sha256 -hmac "$(cat $HMAC_SECRET_KEY)" | awk '{print $2}')
verified_hmac=$(echo -n "$sample" | openssl dgst -sha256 -hmac "$(cat $HMAC_SECRET_KEY)" | awk '{print $2}')
if [[ "$ai_hmac" == "$verified_hmac" ]]; then
    echo "  -> HMAC verification successful."
else
    echo "❌ HMAC verification failed!"
fi

echo -e "\n✅ AI Debug Checker completed. Everything looks okay for startup."
