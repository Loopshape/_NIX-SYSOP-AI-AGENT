#!/usr/bin/env bash
# ~/.bin/ai — CLI with SQLite self-check + syntax-highlighted output

set -euo pipefail
IFS=$'\n\t'

AI_HOME="$HOME/.local_ai"
DB="$AI_HOME/core.db"
PYTHON_BIN="python3"

mkdir -p "$AI_HOME"

# --- Ensure SQLite core DB exists ---
init_db() {
    if [ ! -f "$DB" ]; then
        sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS mindflow(
            id INTEGER PRIMARY KEY,
            session_id TEXT,
            loop_id INTEGER,
            model_name TEXT,
            output TEXT,
            rank INTEGER,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );"
        sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS task_logs(
            id INTEGER PRIMARY KEY,
            tool_used TEXT,
            args TEXT,
            output_summary TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );"
        sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS cache(
            prompt_hash TEXT PRIMARY KEY,
            final_answer TEXT
        );"
    else
        # In case some table is missing
        sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS mindflow(
            id INTEGER PRIMARY KEY,
            session_id TEXT,
            loop_id INTEGER,
            model_name TEXT,
            output TEXT,
            rank INTEGER,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );"
        sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS task_logs(
            id INTEGER PRIMARY KEY,
            tool_used TEXT,
            args TEXT,
            output_summary TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );"
        sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS cache(
            prompt_hash TEXT PRIMARY KEY,
            final_answer TEXT
        );"
    fi
}

# --- Syntax Highlighting via Python rich ---
highlight_output() {
    local text="$1"
    local lang="$2"

    "$PYTHON_BIN" - <<EOF
import sys
from rich.console import Console
from rich.syntax import Syntax

console = Console()
output = """$text"""
syntax = Syntax(output, "$lang", theme="monokai", line_numbers=True)
console.print(syntax)
EOF
}

# --- Run AI prompt ---
run_ai() {
    local prompt="$1"
    local response lang

    # Example logic: replace with your AI call
    if [[ "$prompt" =~ "capital of Germany" ]]; then
        response="The capital of Germany is Berlin."
        lang="text"
    elif [[ "$prompt" =~ "def " ]]; then
        response="def greet(name):\n    return f'Hello, {name}!'"
        lang="python"
    else
        response="$prompt"
        lang="text"
    fi

    highlight_output "$response" "$lang"

    # Log to cache
    local hash
    hash=$(echo -n "$prompt" | sha256sum | awk '{print $1}')
    sqlite3 "$DB" "INSERT OR REPLACE INTO cache(prompt_hash, final_answer) VALUES ('$hash', '$response');"
}

# --- Main ---
if [ $# -lt 1 ]; then
    echo "Usage: ai 'your prompt'"
    exit 1
fi

init_db
run_ai "$*"