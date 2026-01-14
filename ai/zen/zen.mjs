#!/usr/bin/env node
// ZEN Node.js ES Module Wrapper
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { spawn, execSync } from 'child_process';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import crypto from 'crypto';

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

class ZenMemory {
    constructor(dbPath) {
        this.dbPath = dbPath;
        this.db = null;
    }

    async init() {
        this.db = await open({
            filename: this.dbPath,
            driver: sqlite3.Database
        });

        await this.db.exec(`
            CREATE TABLE IF NOT EXISTS memories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                hash TEXT UNIQUE,
                content TEXT,
                embedding BLOB,
                agent_id INTEGER,
                phase REAL,
                entropy REAL,
                tokens INTEGER,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                accessed_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS clusters (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                centroid BLOB,
                size INTEGER,
                variance REAL,
                last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS tokens (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session TEXT,
                agent_id INTEGER,
                token TEXT,
                position INTEGER,
                entropy REAL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE INDEX IF NOT EXISTS idx_memories_hash ON memories(hash);
            CREATE INDEX IF NOT EXISTS idx_memories_phase ON memories(phase);
            CREATE INDEX IF NOT EXISTS idx_tokens_session ON tokens(session);
        `);
    }

    async storeMemory(content, agentId = 0, phase = 0.0, entropy = 0.5) {
        const hash = crypto.createHash('sha256').update(content).digest('hex');
        const embedding = await this.generateEmbedding(content);
        
        await this.db.run(
            `INSERT OR REPLACE INTO memories 
             (hash, content, embedding, agent_id, phase, entropy, accessed_at)
             VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`,
            [hash, content, embedding, agentId, phase, entropy]
        );
        
        return hash;
    }

    async generateEmbedding(text) {
        // Use Ollama embeddings API
        const response = await fetch('http://localhost:11434/api/embeddings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                model: 'nomic-embed-text',
                prompt: text
            })
        });
        
        const data = await response.json();
        return Buffer.from(data.embedding);
    }

    async recallSemantic(query, limit = 5) {
        const queryEmbedding = await this.generateEmbedding(query);
        
        return await this.db.all(`
            SELECT content, 
                   agent_id,
                   phase,
                   entropy,
                   dot_product(embedding, ?) as similarity
            FROM memories
            ORDER BY similarity DESC
            LIMIT ?
        `, [queryEmbedding, limit]);
    }
}

class ZenAgent {
    constructor(id, name, phase) {
        this.id = id;
        this.name = name;
        this.phase = phase;
        this.entropy = 0.5;
    }

    async process(input, context = {}) {
        const temperature = 0.7 + (this.entropy * 0.3);
        const streamPath = join(__dirname, 'streams', 
            `agent_${this.id}_${Date.now()}.txt`);

        const response = await this.callOllama(input, temperature, streamPath);
        
        // Update entropy based on response characteristics
        this.entropy = this.calculateEntropy(response);
        
        return {
            agent: this.name,
            phase: this.phase,
            response: response,
            entropy: this.entropy,
            stream: streamPath
        };
    }

    calculateEntropy(text) {
        // Calculate Shannon entropy of text
        const freq = {};
        for (const char of text) {
            freq[char] = (freq[char] || 0) + 1;
        }
        
        let entropy = 0;
        const len = text.length;
        for (const count of Object.values(freq)) {
            const p = count / len;
            entropy -= p * Math.log2(p);
        }
        
        return Math.min(entropy / 8, 0.9); // Normalize
    }

    async callOllama(prompt, temperature, streamPath) {
        return new Promise((resolve, reject) => {
            const proc = spawn('ollama', [
                'run', 
                'llama3.2:3b',
                prompt
            ], {
                env: { ...process.env, OLLAMA_HOST: 'http://localhost:11434' }
            });

            let output = '';
            const stream = fs.createWriteStream(streamPath);

            proc.stdout.on('data', (data) => {
                const text = data.toString();
                output += text;
                stream.write(text);
            });

            proc.stderr.on('data', (data) => {
                console.error(`Agent ${this.name} error:`, data.toString());
            });

            proc.on('close', (code) => {
                stream.end();
                resolve(output);
            });

            proc.on('error', reject);
        });
    }
}

export { ZenMemory, ZenAgent };
