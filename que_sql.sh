import sqlite3

DB_PATH = "/home/loop/.local_ai/core.db"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# Initialize tables safely
with open("core_init.sql", "r") as f:
    cur.executescript(f.read())

conn.commit()
conn.close()
