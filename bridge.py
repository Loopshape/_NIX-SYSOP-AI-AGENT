# bridge.py
import json, sqlite3, hashlib
from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)
DB = "nexus.db"
INDEX = "memory.json"

def dream(conn):
    rows = conn.execute("""
    SELECT response FROM memory
    ORDER BY entropy DESC LIMIT 5
    """).fetchall()

    dream_prompt = "Summarize these memories into meaning:\n" + "\n".join(r[0] for r in rows)
    dream = ollama("core", dream_prompt)

    conn.execute("""
    INSERT INTO identity(statement,confidence)
    VALUES (?,?)
    """,(dream,0.5))

def sha(text):
    return hashlib.sha256(text.encode()).hexdigest()

def init():
    conn = sqlite3.connect(DB)
    conn.execute("""
    CREATE TABLE IF NOT EXISTS memory (
      id INTEGER PRIMARY KEY,
      hash TEXT,
      agent TEXT,
      prompt TEXT,
      response TEXT,
      entropy REAL,
      ts DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """)
    conn.close()

    try:
        open(INDEX)
    except:
        json.dump({}, open(INDEX,"w"))

init()

@app.route("/infer", methods=["POST"])
def infer():
    data = request.json
    prompt = data["prompt"]
    agent = data["agent"]
    genesis = data["genesis"]

    memory = json.load(open(INDEX))
    rowid = memory.get(genesis)

    context = ""
    if rowid:
        conn = sqlite3.connect(DB)
        cur = conn.execute("SELECT response FROM memory WHERE id=?", (rowid,))
        r = cur.fetchone()
        if r: context = r[0]
        conn.close()

    full_prompt = f"[{agent}]\n{context}\nUSER:{prompt}"

    result = subprocess.check_output([
        "ollama", "run", agent.lower(), full_prompt
    ]).decode()

    h = sha(prompt + result)

    conn = sqlite3.connect(DB)
    cur = conn.execute(
        "INSERT INTO memory (hash,agent,prompt,response,entropy) VALUES (?,?,?,?,?)",
        (h, agent, prompt, result, len(result))
    )
    rowid = cur.lastrowid
    conn.commit()
    conn.close()

    memory[genesis] = rowid
    json.dump(memory, open(INDEX,"w"), indent=2)

    return jsonify({
        "agent": agent,
        "hash": h,
        "response": result
    })

app.run(port=7777)

