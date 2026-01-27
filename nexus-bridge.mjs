#!/usr/bin/env node
import http from 'http';

/**
 * NEXUS - Sentient-Grade Autonomous Orchestrator
 * Implementing structured iteration, 2π readiness, and semantic convergence.
 */

const CONFIG = {
  PORT: 7070,
  OLLAMA_URL: 'http://127.0.0.1:11434',
  DEFAULT_MODEL: 'gemma3:1b',
  POLL_INTERVAL: 2000,
  MAX_CONVERGENCE_ITERATIONS: 3,
};

// --- AGENT REGISTRY (2π / 8 AGENTS) ---
const AGENTS = {
  CUBE: { 
    role: 'spatial reasoning, multidimensional abstraction', 
    framing: 'structure, topology, dimensions',
    model: 'cube' 
  },
  CORE: { 
    role: 'axioms, invariants, epistemic grounding', 
    framing: 'what must remain true',
    model: 'core' 
  },
  WAVE: { 
    role: 'generative synthesis, exploration', 
    framing: 'what could be',
    model: 'wave' 
  },
  LOOP: { 
    role: 'orchestration, recursion, convergence detection', 
    framing: 'iterate until stable',
    model: 'loop' 
  },
  SIGN: { 
    role: 'symbolic meaning, semiotics', 
    framing: 'what does this signify',
    model: 'sign' 
  },
  LINE: { 
    role: 'sequential logic, causality', 
    framing: 'step-by-step derivation',
    model: 'line' 
  },
  COIN: { 
    role: 'validation, polarity, scoring, truth thresholds', 
    framing: 'is this acceptable or false',
    model: 'coin' 
  },
  WORK: { 
    role: 'execution planning, synthesis into action', 
    framing: 'what must be done next',
    model: 'work' 
  },
};

const DEFAULT_AGENT = 'LOOP';

// --- SEMANTIC CONTINUUM (HASH / REHASH) ---
const SemanticRegistry = {
  hashes: new Map(),
  counter: 0,
};

function generateTemporalHash() {
  const ts = Date.now();
  const count = SemanticRegistry.counter++;
  return `hash-${ts}-${count}`;
}

// --- 2π READINESS LATCH ---
let readiness = {
  pi: false,
  twoPi: false,
};

async function probeOllama() {
  try {
    const res = await fetch(`${CONFIG.OLLAMA_URL}/api/tags`);
    if (res.ok) {
      const data = await res.json();
      const models = data.models.map(m => m.name);
      readiness.pi = true;
      const requiredModels = Object.values(AGENTS).map(a => a.model);
      readiness.twoPi = models.some(m => requiredModels.includes(m) || m.startsWith(CONFIG.DEFAULT_MODEL));
      return true;
    }
  } catch (e) {
    readiness.pi = false;
    readiness.twoPi = false;
  }
  return false;
}

setInterval(probeOllama, CONFIG.POLL_INTERVAL);

// --- OLLAMA INTERFACE ---

async function callOllama(agentName, prompt, options = {}) {
  const agent = AGENTS[agentName] || AGENTS[DEFAULT_AGENT];
  const model = options.useFallback ? CONFIG.DEFAULT_MODEL : agent.model;
  
  const systemPrompt = `Role: ${agent.role}. Framing: "${agent.framing}". Respond strictly in this persona. Output valid JSON only.`;
  const enrichedPrompt = `[CONTEXT: ${JSON.stringify(options.meta || {})}] [HASH: ${options.hash}] [REHASH: ${options.rehash}]
[FRAME: ${agent.framing}]

${prompt}`;

  try {
    const response = await fetch(`${CONFIG.OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: model,
        prompt: enrichedPrompt,
        system: systemPrompt,
        stream: false,
        format: 'json',
        options: { temperature: 0 } // Determinism
      })
    });

    if (!response.ok) {
        if (!options.useFallback && model !== CONFIG.DEFAULT_MODEL) {
            return callOllama(agentName, prompt, { ...options, useFallback: true });
        }
        throw new Error(`Ollama error: ${response.status}`);
    }
    
    const data = await response.json();
    return data.response;
  } catch (err) {
    if (!options.useFallback && model !== CONFIG.DEFAULT_MODEL) {
      return callOllama(agentName, prompt, { ...options, useFallback: true });
    }
    throw err;
  }
}

// --- CONVERGENCE & REFLECTION ---

async function detectConvergence(prompt, agentOutputs, meta, hash, rehash) {
    const analysisPrompt = `Compare these agent outputs for convergence, drift, or contradiction:\n${JSON.stringify(agentOutputs)}\n\nGoal: Detect if a stable truth has been reached.`;
    const loopResponse = await callOllama('LOOP', analysisPrompt, { meta, hash, rehash });
    
    // Parse LOOP's internal assessment
    try {
        const assessment = JSON.parse(loopResponse);
        return {
            stable: assessment.converged === true || assessment.status === 'stable',
            reason: assessment.analysis || 'Converged',
            assessment
        };
    } catch (e) {
        // Fallback simple detection if JSON parsing fails
        return { stable: true, reason: 'Implicit convergence' };
    }
}

// --- MAIN ORCHESTRATOR ---

async function handleAsk(req, res) {
  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', async () => {
    try {
      if (!readiness.twoPi) {
        res.writeHead(503, { 'Content-Type': 'application/json' });
        return res.end(JSON.stringify({ nexus: "ERROR", message: "2π readiness not achieved" }));
      }

      const payload = JSON.parse(body);
      const { prompt, agent, hash, meta } = payload;
      let { rehash } = payload;

      const currentHash = hash || generateTemporalHash();
      let currentIteration = 0;
      let stable = false;
      let finalResponse = "";
      let activeAgentsList = [];

      // Phase D: Semantic Routing Inference
      let activeAgents = [];
      if (agent) {
        activeAgents = [agent];
      } else if (hash && !rehash) {
        activeAgents = ['CORE', 'COIN'];
      } else if (!hash && rehash) {
        activeAgents = ['WAVE', 'SIGN'];
      } else if (hash && rehash) {
        activeAgents = ['LOOP'];
      } else {
        activeAgents = [DEFAULT_AGENT];
      }
      activeAgentsList = activeAgents;

      while (currentIteration < CONFIG.MAX_CONVERGENCE_ITERATIONS && !stable) {
          rehash = rehash || (currentIteration > 0 ? `rehash-${Date.now()}-${currentIteration}` : null);
          
          const tasks = activeAgents.map(a => callOllama(a, prompt, { hash: currentHash, rehash, meta }));
          const results = await Promise.all(tasks);
          const agentOutputs = activeAgents.reduce((acc, a, i) => ({ ...acc, [a]: results[i] }), {});

          if (activeAgents.length > 1) {
              const convergence = await detectConvergence(prompt, agentOutputs, meta, currentHash, rehash);
              stable = convergence.stable;
              
              if (!stable) {
                  currentIteration++;
                  rehash = `rehash-iteration-${currentIteration}`;
                  // If we drift, maybe expand agents for next iteration
                  if (!activeAgents.includes('WAVE')) activeAgents.push('WAVE');
                  continue;
              }
          } else {
              stable = true;
          }

          // Aggregation: WORK synthesizes final output
          const synthesisPrompt = `Synthesize these agent insights into a cohesive, deterministic response for the user:\n${JSON.stringify(agentOutputs)}`;
          finalResponse = await callOllama('WORK', synthesisPrompt, { hash: currentHash, rehash, meta });
      }

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        nexus: "OK",
        agent: activeAgentsList.join(','),
        model: activeAgentsList.map(a => AGENTS[a]?.model || CONFIG.DEFAULT_MODEL).join(','),
        hash: currentHash,
        rehash: rehash,
        phase: activeAgentsList.length,
        iterations: currentIteration,
        response: finalResponse
      }));

    } catch (err) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ nexus: "ERROR", message: err.message }));
    }
  });
}

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    return res.end();
  }

  if (req.method === 'POST' && req.url === '/api/ask') {
    handleAsk(req, res);
  } else {
    res.writeHead(404);
    res.end();
  }
});

server.listen(CONFIG.PORT, () => {
  console.log(`[NEXUS] Bridge online on :${CONFIG.PORT} (Sentient-Grade)`);
  probeOllama();
});