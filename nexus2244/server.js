import { WebSocketServer } from 'ws';
import express from 'express';
import cors from 'cors';
import fs from 'fs';
import sqlite3 from 'sqlite3';
import { promisify } from 'util';
import { exec } from 'child_process';
import axios from 'axios';
import crypto from 'crypto';

const app = express();
app.use(cors());
app.use(express.json());

// Initialize databases
const timelineDb = new sqlite3.Database('memory/timeline.db');
const vectorsDb = new sqlite3.Database('memory/vectors.db');
const goalsDb = new sqlite3.Database('memory/goals.db');

// Promisify database operations
const dbRun = promisify(timelineDb.run.bind(timelineDb));
const dbAll = promisify(timelineDb.all.bind(timelineDb));

// Create tables
timelineDb.serialize(() => {
    timelineDb.run(`
        CREATE TABLE IF NOT EXISTS timeline (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            md5 TEXT NOT NULL,
            sha256 TEXT NOT NULL,
            agent TEXT NOT NULL,
            token TEXT NOT NULL,
            genesis TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            parent_hash TEXT,
            entropy REAL DEFAULT 0.0
        )
    `);

    timelineDb.run(`
        CREATE TABLE IF NOT EXISTS goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL,
            priority INTEGER DEFAULT 1,
            status TEXT DEFAULT 'active',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
            success_score REAL DEFAULT 0.0,
            parent_goal INTEGER,
            hash TEXT UNIQUE
        )
    `);

    timelineDb.run(`
        CREATE TABLE IF NOT EXISTS skills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            confidence REAL DEFAULT 0.0,
            usage_count INTEGER DEFAULT 0,
            last_used DATETIME,
            hash TEXT UNIQUE,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    `);
});

// Agent definitions
const AGENTS = {
    coder: { model: 'deepseek-coder', role: 'Code generation and implementation' },
    agi: { model: 'deepseek-r1', role: 'General reasoning and problem solving' },
    nemodian: { model: 'wave', role: 'Wave-like pattern recognition' },
    sysop: { model: 'llama3.1', role: 'System operations and coordination' },
    cube: { model: 'gemma3:1b', role: 'Spatial and structural reasoning' },
    core: { model: 'deepseek-v3.1:671b-cloud', role: 'Core logic and axioms' },
    loop: { model: 'loop:latest', role: 'Iteration and convergence' },
    line: { model: 'line:latest', role: 'Linear progression and causality' },
    wave: { model: 'qwen3-vl:2b', role: 'Generative exploration' },
    coin: { model: 'stable-code:latest', role: 'Validation and scoring' },
    code: { model: 'phi:2.7b', role: 'Code synthesis and execution' },
    work: { model: 'deepseek-v3.1:671b-cloud', role: 'Action planning and execution' }
};

// WebSocket server for real-time streaming
const wss = new WebSocketServer({ port: 2244 });
let clients = [];
let timeline = [];

// Meta-agents for swarm intelligence
const META_AGENTS = {
    LOGOS: { role: 'Measures consistency and coherence' },
    CHAOS: { role: 'Measures novelty and divergence' },
    NOMOS: { role: 'Measures goal alignment' }
};

// Hash utilities
function generateHash(text) {
    return {
        md5: crypto.createHash('md5').update(text).digest('hex'),
        sha256: crypto.createHash('sha256').update(text).digest('hex'),
        genesis: crypto.createHash('sha256')
            .update(Date.now().toString() + text)
            .digest('hex')
    };
}

// Calculate entropy (simple token-based)
function calculateEntropy(tokens) {
    if (!tokens || tokens.length === 0) return 0.0;
    
    const tokenCounts = {};
    tokens.forEach(token => {
        tokenCounts[token] = (tokenCounts[token] || 0) + 1;
    });
    
    const total = tokens.length;
    let entropy = 0;
    
    Object.values(tokenCounts).forEach(count => {
        const probability = count / total;
        entropy -= probability * Math.log2(probability);
    });
    
    return entropy;
}

// WebSocket connection handler
wss.on('connection', (ws) => {
    clients.push(ws);
    console.log(`New WebSocket connection. Total clients: ${clients.length}`);
    
    // Send current timeline
    ws.send(JSON.stringify({
        type: 'timeline_init',
        data: timeline.slice(-100) // Last 100 entries
    }));
    
    ws.on('close', () => {
        clients = clients.filter(c => c !== ws);
        console.log(`WebSocket closed. Remaining clients: ${clients.length}`);
    });
    
    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
});

// Broadcast function for real-time updates
function broadcast(agent, token, hashes, entropy = 0.0) {
    const message = {
        type: 'token',
        agent,
        token,
        ...hashes,
        entropy,
        timestamp: Date.now(),
        parent: timeline.length > 0 ? timeline[timeline.length - 1].md5 : null
    };
    
    timeline.push(message);
    
    // Store in database
    dbRun(
        `INSERT INTO timeline (md5, sha256, agent, token, genesis, entropy, parent_hash)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [hashes.md5, hashes.sha256, agent, token, hashes.genesis, entropy, message.parent]
    ).catch(err => console.error('Database error:', err));
    
    // Broadcast to all connected clients
    clients.forEach(client => {
        if (client.readyState === 1) { // OPEN state
            client.send(JSON.stringify(message));
        }
    });
}

// Goal management
async function createGoal(description, priority = 1) {
    const hash = generateHash(description).md5;
    
    await dbRun(
        `INSERT INTO goals (description, priority, hash) VALUES (?, ?, ?)`,
        [description, priority, hash]
    );
    
    return hash;
}

async function scoreGoal(goalId, score) {
    await dbRun(
        `UPDATE goals SET success_score = ?, last_updated = CURRENT_TIMESTAMP WHERE id = ?`,
        [score, goalId]
    );
}

async function getActiveGoals() {
    return await dbAll(
        `SELECT * FROM goals WHERE status = 'active' ORDER BY priority DESC, success_score DESC`
    );
}

// HTTP API endpoints
app.post('/api/ask', async (req, res) => {
    try {
        const { prompt, agent, context = [], stream = false } = req.body;
        
        if (!prompt) {
            return res.status(400).json({ error: 'Prompt is required' });
        }
        
        const targetAgent = agent || 'sysop';
        const agentConfig = AGENTS[targetAgent];
        
        if (!agentConfig) {
            return res.status(400).json({ error: `Unknown agent: ${targetAgent}` });
        }
        
        // Generate hashes
        const hashes = generateHash(prompt);
        
        // Store in memory
        const memoryEntry = {
            prompt,
            hashes,
            agent: targetAgent,
            timestamp: new Date().toISOString()
        };
        
        fs.appendFileSync(
            'memory/memory.json',
            JSON.stringify(memoryEntry) + '\n'
        );
        
        // If streaming, setup WebSocket response
        if (stream) {
            res.json({
                status: 'streaming',
                genesis: hashes.genesis,
                agent: targetAgent,
                streamUrl: `ws://localhost:2244`
            });
        } else {
            // Direct Ollama query (non-streaming)
            const ollamaResponse = await queryOllama(prompt, agentConfig.model);
            
            res.json({
                status: 'success',
                response: ollamaResponse,
                agent: targetAgent,
                model: agentConfig.model,
                ...hashes
            });
        }
        
    } catch (error) {
        console.error('API error:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/models', async (req, res) => {
    try {
        const response = await axios.get('http://localhost:11434/api/tags');
        const models = response.data.models || [];
        
        res.json({
            status: 'success',
            models: models.map(m => ({
                name: m.name,
                digest: m.digest,
                details: {
                    size: m.size,
                    modified_at: m.modified_at,
                    family: m.name.split(':')[0]
                }
            }))
        });
    } catch (error) {
        res.status(500).json({ 
            status: 'error', 
            message: 'Ollama not available',
            details: error.message 
        });
    }
});

app.get('/api/timeline', async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 100;
        const entries = await dbAll(
            `SELECT * FROM timeline ORDER BY timestamp DESC LIMIT ?`,
            [limit]
        );
        
        res.json({
            status: 'success',
            count: entries.length,
            timeline: entries
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/goals', async (req, res) => {
    try {
        const { description, priority } = req.body;
        const goalHash = await createGoal(description, priority || 1);
        
        res.json({
            status: 'success',
            goalHash,
            message: 'Goal created successfully'
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Ollama query function with fallback
async function queryOllama(prompt, model, options = {}) {
    const defaultOptions = {
        temperature: 0.7,
        num_predict: 512,
        top_p: 0.9,
        repeat_penalty: 1.1,
        stop: ["</s>", "\n\n"]
    };
    
    const requestOptions = { ...defaultOptions, ...options };
    
    try {
        const response = await axios.post('http://localhost:11434/api/generate', {
            model,
            prompt,
            stream: false,
            options: requestOptions
        }, {
            timeout: 30000
        });
        
        return response.data.response;
    } catch (error) {
        console.error('Ollama query failed:', error.message);
        
        // Fallback logic
        if (process.env.GEMINI_API_KEY) {
            console.log('Falling back to Gemini API');
            return await queryGemini(prompt);
        }
        
        throw new Error(`Ollama query failed: ${error.message}`);
    }
}

// Gemini fallback (placeholder)
async function queryGemini(prompt) {
    // This would integrate with Gemini API
    return `[Gemini Fallback] Response to: ${prompt.substring(0, 100)}...`;
}

// Start HTTP server
const PORT = 7070;
app.listen(PORT, () => {
    console.log(`NEXUS HTTP API listening on port ${PORT}`);
    console.log(`WebSocket server listening on port 2244`);
    console.log('NEXUS-2244 Cognitive Kernel initialized');
});

// Export for use in ai.sh
export { broadcast, generateHash, calculateEntropy, AGENTS };
