#!/usr/bin/env bash
# == Gemini-CLI Installer: NEXUS AI Full Deploy ==
# Author: 2244-1
# Purpose: Deploy persistent AI cockpit with Ollama pool, HTML5 dashboard, SQLite memory, and Tampermonkey integration

set -e
echo "=== NEXUS AI Full Installer (Gemini-CLI) ==="

# --- 1. Setup Directory ---
read -p "Install location (default ~/nexus): " NEXUS_HOME
NEXUS_HOME=${NEXUS_HOME:-$HOME/nexus}
mkdir -p "$NEXUS_HOME"/{ai,js,css,db}
cd "$NEXUS_HOME"

# --- 2. Create SQLite Memory DB ---
echo "[1/7] Creating persistent memory DB..."
cat > db/nexus_memory.sql <<'SQL'
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
SQL

sqlite3 db/nexus.db < db/nexus_memory.sql

# --- 3. Copy AI Bash Launcher ---
echo "[2/7] Installing AI launcher..."
cat > ai/ai.sh <<'BASH'
#!/usr/bin/env bash
set -e
export NEXUS_HOME="$HOME/nexus"
cd "$NEXUS_HOME"

# Launch all components
node js/nexus.mjs &
python3 ai_memory.py &
ollama serve &

wait
BASH
chmod +x ai/ai.sh

# --- 4. Install Node.js NEXUS Kernel ---
echo "[3/7] Installing Node.js kernel..."
cat > js/nexus.mjs <<'JS'
import { spawn } from "child_process";
import crypto from "crypto";
import { writeFileSync } from "fs";

export const agents = ["CORE","CUBE","LOOP","SIGN","LINE","COIN","WORK","CODE"];

export function hash(x){
  return crypto.createHash("sha256").update(x).digest("hex");
}

export async function runAgent(model, prompt, genesis){
  const h = hash(genesis+prompt+Date.now());
  return new Promise(resolve=>{
    const p = spawn("ollama", ["run", model], {stdio:["pipe","pipe","pipe"]});
    let output="";
    p.stdout.on("data", d=>{
      output += d.toString();
    });
    p.stdin.write(prompt+"\n");
    p.stdin.end();
    p.on("close",()=> resolve({state:h,output}));
  });
}
JS

# --- 5. Install Python Memory Engine ---
echo "[4/7] Installing Python vector memory engine..."
cat > ai/ai_memory.py <<'PY'
import sqlite3, hashlib
from sentence_transformers import SentenceTransformer
model = SentenceTransformer("all-MiniLM-L6-v2")
db = sqlite3.connect("db/nexus.db")

def store(token):
    sha = hashlib.sha256(token.encode()).hexdigest()
    emb = model.encode(token).tobytes()
    db.execute("INSERT INTO vectors VALUES (NULL,?,?)",(sha,emb))
    db.commit()
PY

# --- 6. Tampermonkey Dashboard Script ---
echo "[5/7] Installing Tampermonkey AI Dashboard..."
cat > ai/nexus_dashboard.user.js <<'JS'
// ==UserScript==
// @name         NEXUS 2244-1 Daemon v7.1
// @namespace    https://webtracon.ai/
// @version      7.1
// @match        *://*/*
// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// @grant        GM_download
// @grant        unsafeWindow
// @connect      localhost
// @run-at       document-end
// ==/UserScript==
// Paste the full v7.1 Tampermonkey script here...
JS

# --- 7. Install Node Modules ---
echo "[6/7] Installing Node.js dependencies..."
npm init -y
npm install ws three

# --- 8. Start AI ---
echo "[7/7] Launching NEXUS AI..."
echo "Run '$NEXUS_HOME/ai/ai.sh' to start the NEXUS AI cockpit."
echo "Web Dashboard (Tampermonkey) injects automatically on browser pages."

