#!/usr/bin/env bash
# store_all_modules.sh
# Scan repo modules and store into SQLite DB
# Usage: ./store_all_modules.sh

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="${REPO_DIR:-$HOME/_NIX-SYSOP-AI-AGENT-by-Aris-Arjuna-Noorsanto}"
DB="${DB:-$HOME/.local_ai/ai_modules.db}"

if [[ ! -d "$REPO_DIR" ]]; then
    echo "[ERROR] Repo directory not found: $REPO_DIR"
    exit 1
fi

if [[ ! -f "$DB" ]]; then
    echo "[INFO] SQLite DB not found, creating: $DB"
    sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS modules (
    name TEXT PRIMARY KEY,
    script BLOB NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_modules_name ON modules(name);
SQL
fi

echo "[INFO] Scanning modules in $REPO_DIR..."
MODULES=($(find "$REPO_DIR" -maxdepth 1 -type f -name "*.sh"))

if [[ ${#MODULES[@]} -eq 0 ]]; then
    echo "[WARN] No .sh modules found in $REPO_DIR"
    exit 0
fi

for module_path in "${MODULES[@]}"; do
    module_name=$(basename "$module_path" .sh)
    echo "[INFO] Storing module: $module_name"

    # Store as BLOB
    sqlite3 "$DB" <<SQL
INSERT OR REPLACE INTO modules(name, script)
VALUES('$module_name', readfile('$module_path'));
SQL

done

echo "[INFO] All modules stored successfully in SQLite DB: $DB"
