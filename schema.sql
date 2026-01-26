CREATE TABLE memory(
 id INTEGER PRIMARY KEY,
 hash TEXT,
 agent TEXT,
 prompt TEXT,
 response TEXT,
 entropy REAL,
 consensus REAL,
 contradiction REAL,
 weight REAL DEFAULT 1,
 ts DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE meta(genesis TEXT, logos REAL, chaos REAL, nomos REAL);
CREATE TABLE emotion(genesis TEXT, confidence REAL, anxiety REAL, drive REAL);
CREATE TABLE curiosity(topic TEXT, score REAL);
CREATE TABLE goals(goal TEXT, weight REAL);
CREATE TABLE identity(hash TEXT, statement TEXT, confidence REAL);
CREATE TABLE survival(risk REAL, action TEXT);
CREATE TABLE selfprompt(prompt TEXT, fitness REAL);

