CREATE TABLE memory (
  id INTEGER PRIMARY KEY,
  hash TEXT,
  agent TEXT,
  prompt TEXT,
  response TEXT,
  entropy REAL,
  ts DATETIME DEFAULT CURRENT_TIMESTAMP
);

