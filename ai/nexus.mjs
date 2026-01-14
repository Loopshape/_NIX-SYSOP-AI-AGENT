import fs from 'fs';
import path from 'path';
import { execSync, spawn } from 'child_process';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import { fileURLToPath } from 'url';

// --- CONFIGURATION ---
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const AI_ROOT = process.env.AI_ROOT || path.join(process.env.HOME, '_/ai');
const NEXUS_DIR = path.join(process.env.HOME, '.nexus');
const OLLAMA_URL = process.env.NEXUS_OLLAMA_URL || 'http://localhost:11434';

// Pi/8 Agent Mapping (8 Agents for 8 sectors of the circle)
const AGENT_MAP = {
    CUBE: "gemma3:1b",           // Phase 0: Define
    CORE: "deepseek-v3.1:671b",  // Phase 1: Reasoning
    LOOP: "loop:latest",         // Phase 2: Recursion
    LINE: "line:latest",         // Phase 3: Analysis
    WAVE: "qwen3-vl:2b",         // Phase 4: Recognition
    COIN: "stable-code:latest",  // Phase 5: Order
    CODE: "phi:2.7b",            // Phase 6: Build
    WORK: "deepseek-v3.1:671b"   // Phase 7: Sort
};

class NexusOrchestrator {
    constructor() {
        this.db = null;
        this.phase = 0; // 0 to 7 (Pi/8 increments)
        this.cycle = 0;
    }

    async init() {
        if (!fs.existsSync(NEXUS_DIR)) fs.mkdirSync(NEXUS_DIR, { recursive: true });
        
        // Initialize SQLite Memory (The SORT/DEFINE Quadrants)
        this.db = await open({
            filename: path.join(NEXUS_DIR, 'spectrum.db'),
            driver: sqlite3.Database
        });

        await this.db.exec(`
            CREATE TABLE IF NOT EXISTS memory (
                id INTEGER PRIMARY KEY,
                concept TEXT UNIQUE,
                thought_graph TEXT,
                agent_origin TEXT,
                phase_angle REAL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log(`[NEXUS] Pi/8 Orchestrator Online. Core: ${OLLAMA_URL}`);
    }

    // --- THE SPECTRUM (Reasoning Bridge) ---
    async askOllama(agent, prompt) {
        const model = AGENT_MAP[agent];
        try {
            const response = await fetch(`${OLLAMA_URL}/api/generate`, {
                method: 'POST',
                body: JSON.stringify({ model, prompt, stream: false }),
            });
            const data = await response.json();
            return data.response;
        } catch (e) {
            return `Error: Agent ${agent} unreachable.`;
        }
    }

    // --- PI/8 PHASE LOGIC ---
    advancePhase() {
        this.phase = (this.phase + 1) % 8;
        if (this.phase === 0) this.cycle++;
        const angle = (this.phase * Math.PI) / 4; // Pi/4 (45 degrees) for 8 agents
        return angle;
    }

    // --- RECOGNIZE & LEARN (Memory Loop) ---
    async process(input) {
        console.log(`\n[ANALYSIS] Phase: ${this.phase} | Cycle: ${this.cycle}`);
        
        // 1. RECOGNIZE: Check SQLite first
        const existing = await this.db.get('SELECT * FROM memory WHERE concept = ?', [input]);
        
        if (existing) {
            console.log(`[FOCUS] Recognized from Phase ${existing.agent_origin}`);
            return `RECALL: ${existing.thought_graph}`;
        }

        // 2. QUEST: Spectrum Reasoning
        const activeAgent = Object.keys(AGENT_MAP)[this.phase];
        console.log(`[QUEST] Invoking Agent: ${activeAgent}`);
        
        const reasoning = await this.askOllama(activeAgent, 
            `Reflect on this input using your specific agent logic (${activeAgent}). Define it: ${input}`);

        // 3. LEARN & SORT: Commit to DB
        await this.db.run(
            'INSERT INTO memory (concept, thought_graph, agent_origin, phase_angle) VALUES (?, ?, ?, ?)',
            [input, reasoning, activeAgent, (this.phase * Math.PI) / 4]
        );

        this.advancePhase();
        return reasoning;
    }

    // --- TOOL: RECURSIVE ---
    async toolRecursive(task, depth = 0) {
        if (depth > 5) return "Recursion Halted: Max Depth.";
        console.log(`[LOOP] Recursion Depth: ${depth}`);
        const result = await this.process(task);
        // Self-loop logic based on results...
        return result;
    }
}

// --- CLI ROUTER (The ai.sh replacement) ---
const main = async () => {
    const nexus = new NexusOrchestrator();
    await nexus.init();

    const args = process.argv.slice(2);
    const command = args[0];

    switch (command) {
        case 'query':
            console.log(await nexus.process(args.slice(1).join(' ')));
            break;
        case 'loop':
            console.log("=== NEXUS HUMAN-LIKE PROMPT RELOOP ===");
            process.stdin.on('data', async (data) => {
                const input = data.toString().trim();
                if (input === 'exit') process.exit();
                const out = await nexus.process(input);
                console.log(`\nAGENT >> ${out}\nNEXUS > `);
            });
            break;
        case 'status':
            const count = await nexus.db.get('SELECT COUNT(*) as cnt FROM memory');
            console.log(`Agents: 8 | Pi/8 Phase: ${nexus.phase} | Memories: ${count.cnt}`);
            break;
        default:
            console.log("Usage: node nexus.mjs {query|loop|status} [input]");
    }
};

main();
