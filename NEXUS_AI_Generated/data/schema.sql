CREATE TABLE IF NOT EXISTS agents (
    id TEXT PRIMARY KEY,
    name TEXT,
    personality TEXT,
    specialty TEXT
);

CREATE TABLE IF NOT EXISTS memory (
    hash TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    prompt TEXT,
    response TEXT,
    agent_id TEXT,
    topic TEXT,
    entropy REAL,
    metadata JSON
);

CREATE TABLE IF NOT EXISTS entropy_index (
    word TEXT PRIMARY KEY,
    frequency INTEGER DEFAULT 1,
    weight REAL DEFAULT 1.0
);

CREATE TABLE IF NOT EXISTS goals (
    hash TEXT PRIMARY KEY,
    goal TEXT,
    motive TEXT,
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS soul (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Initial Agents
INSERT OR IGNORE INTO agents (id, name, personality, specialty) VALUES
('CORE', 'Core Intelligence', 'Logical and structured', 'General reasoning and coordination'),
('CUBE', 'Visual Architect', 'Spatial and geometric', '3D visualization and mapping'),
('LOOP', 'Iterative Optimizer', 'Refining and persistent', 'Optimization and self-improvement'),
('SIGN', 'Pattern Recon', 'Observant and symbolic', 'Pattern recognition and meaning'),
('LINE', 'Procedural Executor', 'Methodical and linear', 'Execution and workflow'),
('COIN', 'Probabilistic Analyst', 'Stochastic and analytical', 'Risk and probability'),
('WORK', 'Task Master', 'Efficiency-driven', 'Operational execution'),
('CODE', 'Digital Architect', 'Algorithmic and technical', 'Software and logic design');
