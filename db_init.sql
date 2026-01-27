-- AI Core Database Initialization
-- File: core_init.sql

-- Table: mindflow
CREATE TABLE IF NOT EXISTS mindflow (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    loop_id INTEGER,
    model_name TEXT,
    output TEXT,
    rank INTEGER,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mindflow_timestamp ON mindflow(timestamp);

-- Table: task_logs
CREATE TABLE IF NOT EXISTS task_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tool_used TEXT,
    args TEXT,
    output_summary TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_task_logs_timestamp ON task_logs(timestamp);

-- Table: cache
CREATE TABLE IF NOT EXISTS cache (
    prompt_hash TEXT PRIMARY KEY,
    final_answer BLOB,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cache_timestamp ON cache(timestamp);
