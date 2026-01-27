#!/usr/bin/env bash
set -euo pipefail

DB="$HOME/.local_ai/ai_modules.db"
MODULES_DIR="$HOME/.local_ai/modules"

echo "[INFO] Backing up DB..."
cp "$DB" "${DB}.bak"

echo "[INFO] Opening SQLite..."
sqlite3 "$DB" <<'SQL'
-- Remove invalid entries
DELETE FROM modules WHERE script IS NULL OR script = '';
DELETE FROM modules WHERE path IS NULL OR path = '';

-- Check if table exists, if not create it
CREATE TABLE IF NOT EXISTS modules (
    name TEXT PRIMARY KEY,
    path TEXT,
    script TEXT
);

-- Compact DB
VACUUM;
SQL

echo "[INFO] Rescanning modules directory..."
for file in "$MODULES_DIR"/*.sh; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .sh)
    sqlite3 "$DB" <<SQL
INSERT OR REPLACE INTO modules(name,path,script)
VALUES('$name','$file','$(<"$file")');
SQL
    echo "[INFO] Stored module: $name"
done

echo "[INFO] DB self-healing completed."
