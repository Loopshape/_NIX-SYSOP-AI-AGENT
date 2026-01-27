#!/usr/bin/env bash
# ~/.local_ai/init_db.sh

DB="$HOME/.local_ai/ai_modules.db"

sqlite3 "$DB" <<'SQL'
-- Create table to store modules as BLOBs
CREATE TABLE IF NOT EXISTS modules (
    name TEXT PRIMARY KEY,
    script BLOB NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create index for quick lookup
CREATE INDEX IF NOT EXISTS idx_modules_name ON modules(name);
SQL
