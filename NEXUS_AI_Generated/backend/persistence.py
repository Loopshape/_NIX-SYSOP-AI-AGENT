import sqlite3
import json
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '../data/nexus_memory.db')
SCHEMA_PATH = os.path.join(os.path.dirname(__file__), '../data/schema.sql')

def init_db():
    conn = sqlite3.connect(DB_PATH)
    with open(SCHEMA_PATH, 'r') as f:
        conn.executescript(f.read())
    conn.commit()
    conn.close()

def save_memory(hash_val, prompt, response, agent_id, topic, entropy, metadata=None):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT OR REPLACE INTO memory (hash, prompt, response, agent_id, topic, entropy, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', (hash_val, prompt, response, agent_id, topic, entropy, json.dumps(metadata) if metadata else None))
    conn.commit()
    conn.close()

def get_soul(key):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT value FROM soul WHERE key = ?', (key,))
    row = cursor.fetchone()
    conn.close()
    return row[0] if row else None

def save_soul(key, value):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('INSERT OR REPLACE INTO soul (key, value, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP)', (key, value))
    conn.commit()
    conn.close()

def update_entropy(word, freq_delta=1):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO entropy_index (word, frequency) VALUES (?, ?)
        ON CONFLICT(word) DO UPDATE SET frequency = frequency + ?
    ''', (word, freq_delta, freq_delta))
    conn.commit()
    conn.close()

def get_word_frequency(word):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT frequency FROM entropy_index WHERE word = ?', (word,))
    row = cursor.fetchone()
    conn.close()
    return row[0] if row else 0

if __name__ == "__main__":
    init_db()
