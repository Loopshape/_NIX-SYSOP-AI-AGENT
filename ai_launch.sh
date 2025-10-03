#!/usr/bin/env bash
# ~/.bin/ai_add_module - add shell module to AI DB
set -euo pipefail
IFS=$'\n\t'

AI_HOME="$HOME/.local_ai"
DB="$AI_HOME/core.db"

if [ $# -lt 1 ]; then
    echo "Usage: ai_add_module <module_name> [module_script_path]"
    exit 1
fi

MODULE_NAME="$1"
SCRIPT_PATH="${2:-}"

if [ -n "$SCRIPT_PATH" ] && [ ! -f "$SCRIPT_PATH" ]; then
    echo "[ERROR] File not found: $SCRIPT_PATH"
    exit 1
fi

# Read script as blob
if [ -n "$SCRIPT_PATH" ]; then
    SCRIPT_CONTENT=$(<"$SCRIPT_PATH")
else
    # empty placeholder
    SCRIPT_CONTENT=""
fi

# Insert or replace into DB
sqlite3 "$DB" <<SQL
INSERT INTO modules(name, script, enabled, timestamp)
VALUES ($(printf '%q' "$MODULE_NAME"), $(printf '%q' "$SCRIPT_CONTENT"), 1, CURRENT_TIMESTAMP)
ON CONFLICT(name) DO UPDATE SET
    script=excluded.script,
    enabled=excluded.enabled,
    timestamp=CURRENT_TIMESTAMP;
SQL

echo "[INFO] Module '$MODULE_NAME' inserted/updated successfully."