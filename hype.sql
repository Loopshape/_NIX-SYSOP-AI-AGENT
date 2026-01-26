CREATE TABLE curiosity (
  id INTEGER PRIMARY KEY,
  topic TEXT,
  novelty REAL,
  uncertainty REAL,
  score REAL,
  ts DATETIME DEFAULT CURRENT_TIMESTAMP
);

