#!/bin/bash

# SysOp-AI: A self-contained AI orchestration framework.
# Manages complex tasks, code generation, and state persistence using local LLMs.

# --- Environment & Configuration ---
export AI_HOME="$HOME/_/.sysop-ai"
export TASKS_DIR="$AI_HOME/tasks"
export PROJECTS_DIR="$AI_HOME/projects"
export DB_DIR="$AI_HOME/.db"
export AI_DATA_DB="$DB_DIR/ai_data.db"
export BLOBS_DB="$DB_DIR/blobs.db"
export OLLAMA_BIN="ollama" # Assumes ollama is in PATH

# --- Utility Functions ---
function setup_environment() {
    mkdir -p "$AI_HOME" "$TASKS_DIR" "$PROJECTS_DIR" "$DB_DIR"
    if [ ! -f "$AI_DATA_DB" ]; then
        sqlite3 "$AI_DATA_DB" "
            CREATE TABLE IF NOT EXISTS memories (id INTEGER PRIMARY KEY, task_id TEXT, prompt TEXT, response TEXT, proof_state TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);
            CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY, event_type TEXT, message TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);
            CREATE TABLE IF NOT EXISTS schemas (id INTEGER PRIMARY KEY, name TEXT, type TEXT, definition TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);
        "
        log_event "INFO" "Initialized ai_data.db"
    fi
    if [ ! -f "$BLOBS_DB" ]; then
        sqlite3 "$BLOBS_DB" "CREATE TABLE IF NOT EXISTS blobs (id INTEGER PRIMARY KEY, project_name TEXT, file_path TEXT, content BLOB, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);"
        log_event "INFO" "Initialized blobs.db"
    fi
    if [ ! -d "$AI_HOME/.git" ]; then
        git init "$AI_HOME"
        git -C "$AI_HOME" checkout -b devel
        log_event "INFO" "Initialized Git repository in $AI_HOME"
    fi
}

function log_event() {
    local type="$1"
    local message="$2"
    echo "[$type] $(date): $message"
    sqlite3 "$AI_DATA_DB" "INSERT INTO events (event_type, message) VALUES ('$type', '$message');"
}

function show_help() {
    echo "SysOp-AI CLI"
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  run <prompt>        Run an AI task loop with the given prompt."
    echo "  import <url>        Pull external content for context."
    echo "  memories            Show past AI prompts/responses."
    echo "  events              Show event logs."
    echo "  blobs               List stored files."
    echo "  schemas             List/insert database schemas."
    echo "  status              Show environment and tool status."
    echo "  server              Manage the Python web server (start/stop)."
    echo "  wallet              CLI for wallet management."
    echo "  seed                CLI for seed phrase management."
    echo ""
    echo "Options:"
    echo "  --start             Start a new project session (interactive)."
    echo "  --stop              Stop the current project session."
    echo "  --project [type]    Generate a multi-file project (fullstack_web, data_pipeline, microservices)."
    echo "  --force             Force file generation."
}

# --- Main Logic ---
setup_environment

COMMAND="$1"
shift

case "$COMMAND" in
    run)
        log_event "TASK_START" "Prompt: $@"
        node orchestrator.js "$@"
        log_event "TASK_END" "Task finished."
        ;;
    import)
        URL="$1"
        CONTENT=$(curl -sL "$URL")
        log_event "IMPORT" "Imported content from $URL"
        echo "Imported content is now available in context. Use 'run' to process it."
        # Here you would typically pass this content to the orchestrator
        ;;
    memories)
        sqlite3 -header -column "$AI_DATA_DB" "SELECT id, task_id, substr(prompt, 1, 50) as prompt, substr(response, 1, 50) as response, timestamp FROM memories;"
        ;;
    events)
        sqlite3 -header -column "$AI_DATA_DB" "SELECT * FROM events ORDER BY timestamp DESC;"
        ;;
    blobs)
        sqlite3 -header -column "$BLOBS_DB" "SELECT id, project_name, file_path, length(content) as size, timestamp FROM blobs;"
        ;;
    schemas)
        sqlite3 -header -column "$AI_DATA_DB" "SELECT * FROM schemas;"
        ;;
    status)
        echo "SysOp-AI Status"
        echo "AI_HOME: $AI_HOME"
        echo "Ollama available: $(command -v $OLLAMA_BIN &> /dev/null && echo 'Yes' || echo 'No')"
        echo "SQLite available: $(command -v sqlite3 &> /dev/null && echo 'Yes' || echo 'No')"
        echo "NodeJS available: $(command -v node &> /dev/null && echo 'Yes' || echo 'No')"
        ;;
    server)
        if [ "$1" == "start" ]; then
            python3 webserver.py &
            echo "Web server started."
        elif [ "$1" == "stop" ]; then
            pkill -f webserver.py
            echo "Web server stopped."
        else
            echo "Usage: $0 server [start|stop]"
        fi
        ;;
    *)
        show_help
        ;;
esac