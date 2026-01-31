#!/usr/bin/env python3
import asyncio
import hashlib
import json
import os
import time
import uuid
from typing import Dict, List, Any
import aiohttp
from datetime import datetime

# --- Configuration ---
MANDATORY_MODEL = "glm-4.7:cloud"
PARALLEL_MODELS = ["core:latest", "loop:latest", "wave:latest", "sign:latest", 
                   "line:latest", "cube:latest", "coin:latest", "work:latest"]
OLLAMA_API = "http://localhost:11434/api/generate"
MEMORY_FILE = "agent_memory.json"

# --- Hashing & Entropy Utilities ---

def generate_genesis_hash(prompt: str) -> str:
    """Creates a unique genesis hash for the prompt."""
    payload = f"{prompt}-{time.time()}-{uuid.uuid4()}"
    return hashlib.sha256(payload.encode()).hexdigest()

def generate_origin_hash(content: str) -> str:
    """Creates an MD5 hash for content chunks/traceback."""
    return hashlib.md5(content.encode()).hexdigest()

def calculate_entropy(content: str) -> float:
    """Simple Shannon entropy approximation for text complexity."""
    if not content: return 0.0
    import math
    prob = [float(content.count(c)) / len(content) for c in dict.fromkeys(list(content))]
    entropy = -sum([p * math.log(p) / math.log(2.0) for p in prob])
    return entropy

# --- Memory System ---

class MindmapMemory:
    def __init__(self, filepath: str):
        self.filepath = filepath
        self.data = self._load()

    def _load(self) -> Dict:
        default_data = {"genesis_index": {}, "mindmap_correlations": []}
        if not os.path.exists(self.filepath):
            return default_data
        try:
            with open(self.filepath, 'r') as f:
                data = json.load(f)
                # Ensure keys exist
                if "genesis_index" not in data:
                    data["genesis_index"] = {}
                if "mindmap_correlations" not in data:
                    data["mindmap_correlations"] = []
                return data
        except:
            return default_data

    def save(self):
        with open(self.filepath, 'w') as f:
            json.dump(self.data, f, indent=2)

    def log_genesis(self, genesis_hash: str, prompt: str):
        self.data["genesis_index"][genesis_hash] = {
            "prompt": prompt,
            "timestamp": datetime.now().isoformat(),
            "agents": {}
        }
        self.save()

    def update_agent_progress(self, genesis_hash: str, agent: str, output: str, origin_hash: str):
        if genesis_hash in self.data["genesis_index"]:
            self.data["genesis_index"][genesis_hash]["agents"][agent] = {
                "origin_hash": origin_hash,
                "token_count": len(output.split()),
                "entropy": calculate_entropy(output)
            }
            self.save()

# --- Async Agent Execution ---

async def query_model(session: aiohttp.ClientSession, model: str, prompt: str, system: str = "") -> Dict:
    """Queries a single model."""
    payload = {
        "model": model,
        "prompt": prompt,
        "system": system,
        "stream": False
    }
    try:
        async with session.post(OLLAMA_API, json=payload) as resp:
            if resp.status == 200:
                data = await resp.json()
                return {
                    "model": model,
                    "response": data.get("response", ""),
                    "done": True
                }
            else:
                text = await resp.text()
                return {"model": model, "response": f"Error {resp.status}: {text}", "done": False}
    except Exception as e:
        return {"model": model, "response": f"Exception: {str(e)}", "done": False}

# --- Main Swarm Orchestrator ---

async def run_swarm(prompt: str):
    memory = MindmapMemory(MEMORY_FILE)
    genesis_hash = generate_genesis_hash(prompt)
    print(f"\n[SWARM] Genesis Hash Initiated: {genesis_hash}")
    print(f"[SWARM] Mandatory Gatekeeper: {MANDATORY_MODEL}")
    
    memory.log_genesis(genesis_hash, prompt)

    # Semaphore to prevent overloading Ollama (limit to 2 concurrent streams)
    sem = asyncio.Semaphore(2)

    async def protected_query(session, model, prompt, system=""):
        async with sem:
            return await query_model(session, model, prompt, system)

    async with aiohttp.ClientSession() as session:
        # 1. Cloud Gatekeeper (Mandatory)
        print(f"[CLOUD] {MANDATORY_MODEL} analyzing prompt structure...")
        cloud_res = await protected_query(session, MANDATORY_MODEL, prompt, 
                                      system="You are the Cloud Gatekeeper. Analyze this prompt and provide a high-level architectural strategy for the sub-agents. **MANDATORY:** You must use VERBOSE REASONING. key-steps: 1. Deconstruct the prompt. 2. Identify ambiguity. 3. Define agent roles. 4. Output the strategy.")
        
        cloud_strategy = cloud_res["response"]
        print(f"[CLOUD] Strategy defined. Origin Hash: {generate_origin_hash(cloud_strategy)}")
        memory.update_agent_progress(genesis_hash, "cloud_gatekeeper", cloud_strategy, generate_origin_hash(cloud_strategy))

        # 2. Parallel 8-Agent Bearing
        print(f"[SWARM] Deploying 2Pi/8-Agent Bearing...")
        tasks = []
        for agent in PARALLEL_MODELS:
            agent_name = agent.split(':')[0]
            # Personalized system prompts could go here, for now using the Cloud strategy as context
            agent_prompt = f"Context from Cloud Gatekeeper:\n{cloud_strategy}\n\nYour Task: Contribute to the solution for: '{prompt}' based on your specialized persona.\n\n**MANDATORY INSTRUCTION:**\n1. THINK FIRST: Start your response with a <thinking> section where you verbosely analyze the problem step-by-step.\n2. REASON: Explain *why* you are choosing a specific approach.\n3. ANSWER: Provide your contribution only after the reasoning phase."
            tasks.append(protected_query(session, agent, agent_prompt))

        results = await asyncio.gather(*tasks)

        # 3. Shifted Entropy Mindmap & Sorting
        print(f"[SWARM] Assembling Shifted Entropy Mindmap...")
        processed_results = []
        
        for res in results:
            content = res["response"]
            origin_hash = generate_origin_hash(content)
            sha_sort_key = hashlib.sha256(content.encode()).hexdigest()
            entropy = calculate_entropy(content)
            
            processed_results.append({
                "agent": res["model"],
                "content": content,
                "origin_hash": origin_hash,
                "sha_sort_key": sha_sort_key,
                "entropy": entropy
            })
            
            # Log to memory
            memory.update_agent_progress(genesis_hash, res["model"], content, origin_hash)

        # Sort by SHA256 (as requested for "sha256 sorting")
        # In a real "shifted entropy" system, we might sort by entropy, but the prompt asked for sha256 sorting.
        # We will use the hex string value for sorting to be deterministic.
        processed_results.sort(key=lambda x: x["sha_sort_key"])

        # 4. Fusion & Traceback
        print(f"[SWARM] Performing MD5 Traceback & Fusion...")
        final_fusion = []
        md5_chain = []
        
        print("\n--- SWARM CONSENSUS (Sorted by SHA256) ---\n")
        for item in processed_results:
            print(f"[{item['agent']}] (Entropy: {item['entropy']:.2f}) (MD5: {item['origin_hash'][:8]})...")
            md5_chain.append(item['origin_hash'])
            final_fusion.append(f"### Contribution from {item['agent']}\n{item['content']}")

        # 5. Final Answer Seeking
        combined_context = "\n".join(final_fusion)
        print(f"\n[SWARM] Seeking Final Answer via {MANDATORY_MODEL}...")
        
        final_res = await query_model(session, MANDATORY_MODEL, 
                                      f"Synthesize the following agent contributions (which include verbose reasoning) into a single, cohesive final answer.\n\n{combined_context}",
                                      system="You are the Final Synthesizer. Analyze the <thinking> steps of all agents. Synthesize their reasoning into a superior final answer. MANDATORY: Explain the consensus logic used.")
        
        print("\n" + "="*60)
        print("FINAL ANSWER")
        print("="*60 + "\n")
        print(final_res["response"])
        
        # Log final state
        memory.update_agent_progress(genesis_hash, "final_synthesis", final_res["response"], generate_origin_hash(final_res["response"]))
        print(f"\n[SWARM] Mission Complete. Genesis Hash {genesis_hash} archived.")

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: ./nexus_swarm.py \"Your Prompt Here\"")
        sys.exit(1)
    
    prompt = sys.argv[1]
    asyncio.run(run_swarm(prompt))
