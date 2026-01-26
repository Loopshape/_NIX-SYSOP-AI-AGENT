CREATE TABLE emotion (
  id INTEGER PRIMARY KEY,
  genesis TEXT,
  confidence REAL,
  anxiety REAL,
  drive REAL,
  ts DATETIME DEFAULT CURRENT_TIMESTAMP
);

