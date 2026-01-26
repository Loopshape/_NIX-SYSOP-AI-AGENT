import express from 'express';
import http from 'http';
import { WebSocketServer } from 'ws';
import sqlite3 from 'sqlite3';
import bodyParser from 'body-parser';
import fetch from 'node-fetch';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

const REST_PORT = 3000; // Matches worktask.txt
const OLLAMA_URL = 'http://localhost:11434/api/generate';

const db = new sqlite3.Database(path.join(__dirname, 'memory.db'));

app.use(bodyParser.json({ limit: '50mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// --- Database Schema ---

db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS memory (
        id TEXT PRIMARY KEY,
        parent TEXT,
        time INTEGER,
        agent TEXT,
        prompt TEXT,
        response TEXT,
        domdiff TEXT,
        entropy REAL,
        branch TEXT DEFAULT "main",
        type TEXT DEFAULT "interaction",
        data TEXT
    )`);
    
    // Phase 10: Goal Engine
    db.run(`CREATE TABLE IF NOT EXISTS goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        priority INTEGER,
        last_update INTEGER,
        success_score REAL
    )`);

    // Tools logging
    db.run(`CREATE TABLE IF NOT EXISTS tool_actions (
        action_hash TEXT PRIMARY KEY,
        memory_hash TEXT,
        tool_name TEXT,
        arguments TEXT,
        result TEXT
    )`);
});

// --- Helper Functions ---

function hash(x) {
    return crypto.createHash("sha256").update(x).digest("hex");
}

function runDb(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function(err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
}

function allDb(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.all(sql, params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
        });
    });
}

// --- Mind Files (Phase 14) ---
const MIND_FILES = ['mindmap.txt', 'mindset.txt', 'mindbend.txt'];
let mindContext = "";

function loadMindFiles() {
    mindContext = "";
    MIND_FILES.forEach(file => {
        const p = path.join(__dirname, '..', file); // Check root
        if (fs.existsSync(p)) {
            console.log(`[MIND] Loading ${file}`);
            mindContext += `
[${file.toUpperCase()}]
${fs.readFileSync(p, 'utf-8')}
`;
        }
    });
}
loadMindFiles();

// --- Agent Swarm ---

const AGENTS = {
    CORE: "Truth & consistency",
    CUBE: "Spatial & structure",
    LOOP: "Memory & time",
    SIGN: "Symbolism & meaning",
    LINE: "Logic & proofs",
    COIN: "Probabilities",
    WORK: "Execution",
    CODE: "Software"
};

async function callOllama(model, prompt) {
    try {
        const r = await fetch(OLLAMA_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ model, prompt, stream: false })
        });
        const j = await r.json();
        return j.response;
    } catch (e) {
        console.error("Ollama error:", e);
        return "Error calling Ollama";
    }
}

async function swarm(prompt) {
    // Phase 13: Rotation could be implemented here, but for now we do parallel voting
    const models = ["gemma:2b", "mistral", "llama3"]; // Adjust based on availability
    const agentNames = Object.keys(AGENTS);
    
    // Select a subset or all agents
    const activeAgents = agentNames; 
    
    const votes = [];
    
    // In a real swarm, we might parallelize this. For standard PCs, maybe limit concurrency.
    // For now, let's just use the 'CORE' agent + one random other to save time/compute, 
    // or use a single strong model with different personas.
    
    // We will use one model to simulate the agents to avoid overloading localhost
    const model = "gemma2:9b"; // Default robust model

    const agentPromises = activeAgents.map(async (agent) => {
        const systemPrompt = `You are ${agent} (${AGENTS[agent]}). ${mindContext}`;
        const fullPrompt = `${systemPrompt}

User Input: ${prompt}`;
        const response = await callOllama(model, fullPrompt);
        return { agent, response };
    });

    const results = await Promise.all(agentPromises);
    
    // Entropy-based selection (Phase 9/Swarm)
    // Simple heuristic: longest detailed response or consensus
    // Sorting by length as a proxy for detail/effort
    results.sort((a, b) => b.response.length - a.response.length);
    
    return results[0]; // Winner
}

let lastNode = null;

// --- API Endpoints ---

// 1. Event Loop (Main Entry)
app.post("/event", async (req, res) => {
    const { dom, diff, prompt } = req.body;
    console.log(`[EVENT] Prompt: ${prompt.substring(0,50)}...`);

    // 1. Swarm Reasoning
    const winner = await swarm(prompt);
    const response = winner.response;
    const agent = winner.agent;

    // 2. Metrics
    const entropy = (diff ? JSON.stringify(diff).length : 0) + response.length;
    const id = hash(Date.now() + response);

    // 3. Store Memory
    await runDb(
        `INSERT INTO memory (id, parent, time, agent, prompt, response, domdiff, entropy, branch) VALUES (?,?,?,?,?,?,?,?,?)`,
        [id, lastNode, Date.now(), agent, prompt, response, JSON.stringify(diff), entropy, "main"]
    );

    lastNode = id;

    // 4. Auto-Refactoring Check (Cognitive Evolution)
    if (response.includes("REFACTOR:")) {
        // Parse refactor command (simplified)
        // Expected format: REFACTOR: path/to/file \n```\ncontent\n```
    }

    res.json({ response, id, agent });
});

// 2. Memory Graph
app.get("/memory", async (req, res) => {
    const rows = await allDb("SELECT * FROM memory");
    res.json(rows);
});

// 3. Timeline
app.get("/timeline", async (req, res) => {
    const rows = await allDb("SELECT id, time, agent, entropy FROM memory ORDER BY time");
    res.json(rows);
});

// 4. Branching
app.post("/branch", (req, res) => {
    lastNode = req.body.id;
    res.json({ status: "branched", head: lastNode });
});

// 5. Training (Self-Correction)
app.post("/train", async (req, res) => {
    const { prompt, response, success } = req.body;
    await runDb("INSERT INTO memory (type, data) VALUES (?, ?)", ["training", JSON.stringify(req.body)]);
    res.json({ status: "learned" });
});

// 6. Refactoring (Autonomous)
app.post("/refactor", async (req, res) => {
    const { file, content } = req.body;
    try {
        const p = path.resolve(__dirname, '..', file); // Safety check needed in real prod
        fs.writeFileSync(p, content);
        await runDb("INSERT INTO memory (type, data) VALUES (?, ?)", ["refactor", JSON.stringify({ file, content })]);
        res.json({ status: "mutated" });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// 7. Export
app.get("/export", (req, res) => {
    res.download(path.join(__dirname, 'memory.db'));
});

// 8. Goals (Phase 10)
app.get("/goals", async (req, res) => {
    const goals = await allDb("SELECT * FROM goals ORDER BY priority DESC");
    res.json(goals);
});

app.post("/goals", async (req, res) => {
    const { description, priority } = req.body;
    await runDb("INSERT INTO goals (description, priority, last_update, success_score) VALUES (?, ?, ?, ?)",
        [description, priority, Date.now(), 0]);
    res.json({ status: "created" });
});

// --- WebSocket for Realtime Updates ---

wss.on('connection', (ws) => {
    console.log('[WS] Client connected');
    ws.on('message', (message) => {
        // Broadcast updates
        wss.clients.forEach(client => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
                client.send(message);
            }
        });
    });
});

server.listen(REST_PORT, () => {
    console.log(`[NEXUS-2244] Online on port ${REST_PORT}`);
    console.log(`[SYSTEM] Swarm Agents: ${Object.keys(AGENTS).join(", ")}`);
    console.log(`[SYSTEM] Mind Context Loaded: ${mindContext.length} chars`);
});