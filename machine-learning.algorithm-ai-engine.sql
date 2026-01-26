CREATE TABLE states (
  id INTEGER PRIMARY KEY,
  genesis_hash TEXT,
  parent_hash TEXT,
  state_hash TEXT,
  timestamp INTEGER,
  model TEXT,
  entropy REAL
);

CREATE TABLE tokens (
  id INTEGER PRIMARY KEY,
  state_hash TEXT,
  token TEXT,
  token_index INTEGER,
  md5 TEXT,
  sha256 TEXT
);

CREATE TABLE vectors (
  id INTEGER PRIMARY KEY,
  token_sha256 TEXT,
  embedding BLOB
);

