#!/usr/bin/env python3
import sqlite3, sys, os

DB_FILE = os.path.expanduser("~/.local_ai/core.db")

def store_code(prompt, code, language):
    os.makedirs(os.path.dirname(DB_FILE), exist_ok=True)
    conn = sqlite3.connect(DB_FILE)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS code_cache(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            prompt TEXT UNIQUE,
            code_blob BLOB,
            language TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("INSERT OR REPLACE INTO code_cache(prompt, code_blob, language) VALUES (?, ?, ?)",
                (prompt, code.encode("utf-8"), language))
    conn.commit()
    conn.close()

def get_code(prompt):
    if not os.path.exists(DB_FILE):
        return None, None
    conn = sqlite3.connect(DB_FILE)
    cur = conn.cursor()
    cur.execute("SELECT code_blob, language FROM code_cache WHERE prompt=?", (prompt,))
    row = cur.fetchone()
    conn.close()
    if row:
        return row[0].decode("utf-8"), row[1]
    return None, None

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: ai_db.py {store|get} <prompt> [language] < [code]")
        sys.exit(1)
        
    action = sys.argv[1]
    prompt = sys.argv[2]
    if action=="store":
        code = sys.stdin.read()
        language = sys.argv[3] if len(sys.argv) > 3 else "text"
        store_code(prompt, code, language)
    elif action=="get":
        code, language = get_code(prompt)
        if code:
            print(code)
