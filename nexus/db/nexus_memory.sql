CREATE TABLE IF NOT EXISTS states (
  id INTEGER PRIMARY KEY,
  genesis_hash TEXT,
  parent_hash TEXT,
  state_hash TEXT,
  timestamp INTEGER,
  model TEXT,
  entropy REAL
);
CREATE TABLE IF NOT EXISTS tokens (
  id INTEGER PRIMARY KEY,
  state_hash TEXT,
  token TEXT,
  token_index INTEGER,
  md5 TEXT,
  sha256 TEXT
);
CREATE TABLE IF NOT EXISTS vectors (
  id INTEGER PRIMARY KEY,
  token_sha256 TEXT,
  embedding BLOB
);
