const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const sqlite3 = require('sqlite3').verbose();
const bodyParser = require('body-parser');
const fetch = require('node-fetch');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

const fileTools = require('./tools/file_tools');
const gitTools = require('./tools/git_tools');
const { sanitizeInput } = require('./tools/safety');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ port: 8765 });

const REST_PORT = 8081;
const OLLAMA_URL = 'http://localhost:11434/api/generate';

const db = new sqlite3.Database(path.join(__dirname, 'memory.db'));

app.use(bodyParser.json({ limit: '50mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// --- Database Helpers ---

function query(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.all(sql, params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
        });
    });
}

function run(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function(err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
}

// --- Agent Swarm Logic ---

async function callAgent(agentName, prompt, memoryContext) {
    const agentConfig = JSON.parse(fs.readFileSync(path.join(__dirname, 'agents', `${agentName}.json`)));
    const fullPrompt = `[SYSTEM_PROMPT]\n${agentConfig.system_prompt}\n\n[MEMORY_CONTEXT]\n${memoryContext}\n\n[CURRENT_CONTEXT]\n${prompt}\n\n[ANALYSIS_INSTRUCTIONS]\nProvide your specific analysis based on your role.`;

    const startTime = Date.now();
    try {
        const response = await fetch(OLLAMA_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                model: 'llama3', // Fallback to llama3 or specific model if configured
                prompt: fullPrompt,
                stream: false
            })
        });
        const data = await response.json();
        const duration = Date.now() - startTime;
        return { agent_name: agentName, response: data.response, time: duration };
    } catch (error) {
        console.error(`Error calling agent ${agentName}:`, error);
        return { agent_name: agentName, response: `Error: ${error.message}`, time: 0 };
    }
}

function calculateEntropy(responses) {
    // Simplified Shannon entropy based on response length divergence
    const lengths = responses.map(r => r.response.length);
    const sum = lengths.reduce((a, b) => a + b, 0);
    const probs = lengths.map(l => l / sum);
    let entropy = 0;
    probs.forEach(p => {
        if (p > 0) entropy -= p * Math.log2(p);
    });
    return entropy;
}

async function orchestrate(prompt, domContext = null) {
    console.log(`[ORCHESTRATOR] Processing prompt: ${prompt.substring(0, 50)}...`);
    
    // 1. Get memory context (last 5 hashes from main branch)
    const history = await query('SELECT result FROM memory WHERE branch_id = "main" ORDER BY time DESC LIMIT 5');
    const memoryContext = history.map(h => h.result).join('\n---\n');

    // 2. Call all 8 agents in parallel
    const agents = ['core', 'cube', 'loop', 'sign', 'line', 'coin', 'work', 'code'];
    const agentPromises = agents.map(name => callAgent(name, prompt, memoryContext));
    const responses = await Promise.all(agentPromises);

    // 3. Synthesis (CORE agent final pass)
    const synthesisPrompt = `Synthesize these agent responses into a final output:\n${responses.map(r => `${r.agent_name}: ${r.response}`).join('\n\n')}`;
    const synthesis = await callAgent('core', synthesisPrompt, '');

    // 4. Cryptographic Hashing
    const timestamp = new Date().toISOString();
    const entropy = calculateEntropy(responses);
    const hashData = JSON.stringify(responses) + timestamp;
    const hash = crypto.createHash('sha256').update(hashData).digest('hex');

    // 5. Parent pointer
    const lastMemory = await query('SELECT hash FROM memory ORDER BY time DESC LIMIT 1');
    const parentHash = lastMemory.length > 0 ? lastMemory[0].hash : null;

    // 6. Persistence
    await run(
        'INSERT INTO memory (hash, parent, entropy, prompt, agents, result, branch_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [hash, parentHash, entropy, prompt, JSON.stringify(responses), synthesis.response, 'main']
    );

    for (const res of responses) {
        await run(
            'INSERT INTO agent_logs (memory_hash, agent_name, prompt, response, response_time) VALUES (?, ?, ?, ?, ?)',
            [hash, res.agent_name, prompt, res.response, res.time]
        );
    }

    if (domContext && domContext.html) {
        const domHash = crypto.createHash('sha256').update(domContext.html).digest('hex');
        await run(
            'INSERT INTO dom_snapshots (dom_hash, url, title, html, text_content, memory_hash) VALUES (?, ?, ?, ?, ?, ?)',
            [domHash, domContext.url, domContext.title, domContext.html, domContext.text_content, hash]
        );
    }

    const result = {
        hash,
        parent: parentHash,
        entropy,
        result: synthesis.response,
        agents: responses
    };

    // Broadcast to all connected clients
    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({ type: 'NEW_MEMORY', data: result }));
        }
    });

    return result;
}

// --- REST API Endpoints ---

app.post('/api/orchestrate', async (req, res) => {
    try {
        const { prompt, domContext } = req.body;
        const result = await orchestrate(prompt, domContext);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/memory/:hash', async (req, res) => {
    try {
        const memories = await query('SELECT * FROM memory WHERE hash = ?', [req.params.hash]);
        if (memories.length === 0) return res.status(404).json({ error: 'Not found' });
        const agents = await query('SELECT * FROM agent_logs WHERE memory_hash = ?', [req.params.hash]);
        res.json({ ...memories[0], agent_details: agents });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/graph', async (req, res) => {
    try {
        const nodes = await query('SELECT hash, parent, entropy, time, prompt, branch_id FROM memory');
        res.json(nodes);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/tools/execute', async (req, res) => {
    const { tool, args, memory_hash } = req.body;
    let result;
    try {
        switch (tool) {
            case 'read_file': result = fileTools.read_file(args.path); break;
            case 'write_file': result = fileTools.write_file(args.path, args.content); break;
            case 'list_files': result = fileTools.list_files(args.path); break;
            case 'git_status': result = gitTools.git_status(args.path); break;
            case 'git_commit': result = gitTools.git_commit(args.path, args.message); break;
            default: throw new Error('Unknown tool');
        }
        
        const action_hash = crypto.createHash('sha256').update(JSON.stringify({ tool, args, timestamp: Date.now() })).digest('hex');
        await run(
            'INSERT INTO tool_actions (action_hash, memory_hash, tool_name, arguments, result) VALUES (?, ?, ?, ?, ?)',
            [action_hash, memory_hash, tool, JSON.stringify(args), JSON.stringify(result)]
        );
        
        res.json({ action_hash, result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// --- WebSocket Handling ---

wss.on('connection', (ws) => {
    console.log('[WS] Client connected');
    ws.on('message', async (message) => {
        try {
            const payload = JSON.parse(message);
            if (payload.type === 'DOM_STREAM') {
                console.log('[WS] Received DOM stream from', payload.data.url);
                // Optionally trigger auto-orchestration or just store
            }
        } catch (error) {
            console.error('[WS] Error processing message:', error);
        }
    });
});

server.listen(REST_PORT, () => {
    console.log(`[SERVER] REST API listening on port ${REST_PORT}`);
    console.log(`[SERVER] WebSocket listening on port 8765`);
});
