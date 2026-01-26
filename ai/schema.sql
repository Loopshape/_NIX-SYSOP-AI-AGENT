-- NEXUS-2244 Cryptographic Memory Schema
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS memory (
    hash TEXT PRIMARY KEY,
    parent TEXT,
    time DATETIME DEFAULT CURRENT_TIMESTAMP,
    entropy REAL,
    prompt TEXT,
    agents JSON,
    result TEXT,
    branch_id TEXT,
    FOREIGN KEY(parent) REFERENCES memory(hash)
);

CREATE TABLE IF NOT EXISTS dom_snapshots (
    dom_hash TEXT PRIMARY KEY,
    url TEXT,
    title TEXT,
    html TEXT,
    text_content TEXT,
    memory_hash TEXT,
    time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(memory_hash) REFERENCES memory(hash)
);

CREATE TABLE IF NOT EXISTS tool_actions (
    action_hash TEXT PRIMARY KEY,
    memory_hash TEXT,
    tool_name TEXT,
    arguments JSON,
    result TEXT,
    time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(memory_hash) REFERENCES memory(hash)
);

CREATE TABLE IF NOT EXISTS agent_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    memory_hash TEXT,
    agent_name TEXT,
    prompt TEXT,
    response TEXT,
    response_time INTEGER,
    FOREIGN KEY(memory_hash) REFERENCES memory(hash)
);

CREATE TABLE IF NOT EXISTS branches (
    branch_id TEXT PRIMARY KEY,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    active_hash TEXT,
    FOREIGN KEY(active_hash) REFERENCES memory(hash)
);

-- Initial default branch
INSERT OR IGNORE INTO branches (branch_id, description) VALUES ('main', 'Primary cognitive timeline');
