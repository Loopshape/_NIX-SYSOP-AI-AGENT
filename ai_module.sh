#!/usr/bin/env bash
# ~/.bin/ai_module - manage AI modules in SQLite
set -euo pipefail
IFS=$'\n\t'

AI_HOME="${HOME}/.local_ai"
DB="$AI_HOME/core.db"

log(){ echo "[$(date '+%H:%M:%S')] $*"; }

# Ensure DB exists
if [ ! -f "$DB" ]; then
    log "[ERROR] Database not found at $DB"
    exit 1
fi

usage() {
    echo "Usage: ai_module <command> [args]"
    echo "Commands:"
    echo "  list                       List all modules"
    echo "  view <name>                Show module code"
    echo "  add <name> <file>          Add new module from file"
    echo "  update <name> <file>       Update existing module from file"
    echo "  remove <name>              Remove module"
}

# List modules
list_modules() {
    sqlite3 "$DB" "SELECT name FROM modules;" | while read -r name; do
        echo "- $name"
    done
}

# View module code
view_module() {
    local name="$1"
    local code
    code=$(sqlite3 "$DB" "SELECT code_blob FROM modules WHERE name='$name';" | xxd -r -p)
    if [ -z "$code" ]; then
        log "[ERROR] Module '$name' not found"
        exit 1
    fi
    echo "$code"
}

# Add or update module
upsert_module() {
    local name="$1"
    local file="$2"
    if [ ! -f "$file" ]; then
        log "[ERROR] File '$file' does not exist"
        exit 1
    fi
    local blob
    blob=$(xxd -p -c 256 "$file")
    sqlite3 "$DB" <<SQL
INSERT OR REPLACE INTO modules(name, code_blob)
VALUES('$name', X'$blob');
SQL
    log "[OK] Module '$name' saved"
}

# Remove module
remove_module() {
    local name="$1"
    sqlite3 "$DB" "DELETE FROM modules WHERE name='$name';"
    log "[OK] Module '$name' removed"
}

# Main
if [ $# -lt 1 ]; then
    usage
    exit 1
fi

cmd="$1"
shift || true

case "$cmd" in
    list) list_modules ;;
    view) view_module "$1" ;;
    add) upsert_module "$1" "$2" ;;
    update) upsert_module "$1" "$2" ;;
    remove) remove_module "$1" ;;
    *) usage ;;
esac
