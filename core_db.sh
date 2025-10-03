DB="$HOME/_NIX-SYSOP-AI-AGENT-by-Aris-Arjuna-Noorsanto/core.db"

sqlite3 "$DB" <<'SQL'
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS mindflow (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    loop_id INTEGER NOT NULL,
    model_name TEXT NOT NULL,
    output TEXT,
    rank INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_mindflow_created_at ON mindflow(created_at);

CREATE TABLE IF NOT EXISTS task_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tool_used TEXT NOT NULL,
    args TEXT,
    output_summary TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_task_logs_created_at ON task_logs(created_at);

CREATE TABLE IF NOT EXISTS cache (
    prompt_hash TEXT PRIMARY KEY,
    final_answer TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_cache_created_at ON cache(created_at);

CREATE TABLE IF NOT EXISTS modules (
    name TEXT PRIMARY KEY,
    code_blob BLOB NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_modules_created_at ON modules(created_at);
SQL
