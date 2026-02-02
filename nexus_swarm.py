#!/usr/bin/env python3
import asyncio
import hashlib
import json
import os
import time
import uuid
import socket
import sqlite3
from typing import Dict, List, Any, AsyncGenerator, Optional, Tuple
import aiohttp
from datetime import datetime
import math

from rich.console import Console
from rich.live import Live
from rich.panel import Panel
from rich.layout import Layout
from rich.text import Text
from rich.table import Table
from rich import box

# --- Configuration ---
MANDATORY_MODEL = "glm-4.7:cloud"
DEFAULT_OFFLINE_MODEL = "core:latest"

PARALLEL_MODELS = [
    "core:latest", "loop:latest", "wave:latest", "sign:latest", 
    "line:latest", "cube:latest", "coin:latest", "work:latest"
]
OLLAMA_API = "http://localhost:11434/api/generate"
MEMORY_FILE = "agent_memory.json"

console = Console()

# --- Connectivity Check ---

def check_connectivity(host="8.8.8.8", port=53, timeout=3):
    """Checks for active internet connection."""
    try:
        socket.setdefaulttimeout(timeout)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
        return True
    except socket.error:
        return False

# --- Hashing Protocols ---

def generate_genesis_hash(prompt: str) -> str:
    """Creates the SHA256 Root Hash for the entire session."""
    payload = f"{prompt}-{time.time()}-{uuid.uuid4()}"
    return hashlib.sha256(payload.encode()).hexdigest()

def generate_origin_hash(agent_name: str, genesis_hash: str) -> str:
    """Creates the MD5 Branch Hash for a specific agent's reasoning stream."""
    payload = f"{agent_name}-{genesis_hash}-{time.time()}"
    return hashlib.md5(payload.encode()).hexdigest()

def generate_prompt_hash(prompt: str) -> str:
    return hashlib.sha256(prompt.strip().lower().encode()).hexdigest()

def calculate_entropy(content: str) -> float:
    if not content: return 0.0
    prob = [float(content.count(c)) / len(content) for c in dict.fromkeys(list(content))]
    entropy = -sum([p * math.log(p) / math.log(2.0) for p in prob])
    return entropy

# --- Memory System ---

class MindmapMemory:
    def __init__(self, filepath: str, db_path: str = "ai/.db/ai_memory.db"):
        self.filepath = filepath
        self.db_path = db_path
        self.data = self._load()

    def _load(self) -> Dict:
        default_data = {"genesis_index": {}, "prompt_index": {}, "mindmap_correlations": []}
        if not os.path.exists(self.filepath):
            return default_data
        try:
            with open(self.filepath, 'r') as f:
                data = json.load(f)
                if "prompt_index" not in data: data["prompt_index"] = {}
                return data
        except:
            return default_data

    def save(self):
        with open(self.filepath, 'w') as f:
            json.dump(self.data, f, indent=2)

    def log_genesis(self, genesis_hash: str, prompt: str, prompt_hash: str):
        if "genesis_index" not in self.data: self.data["genesis_index"] = {}
        self.data["genesis_index"][genesis_hash] = {
            "prompt": prompt,
            "timestamp": datetime.now().isoformat(),
            "agents": {}
        }
        self.data["prompt_index"][prompt_hash] = genesis_hash
        self.save()

    def log_agent_stream(self, genesis_hash: str, agent: str, origin_hash: str, content: str):
        if genesis_hash in self.data["genesis_index"]:
            self.data["genesis_index"][genesis_hash]["agents"][agent] = {
                "origin_hash": origin_hash,
                "token_count": len(content.split()),
                "entropy": calculate_entropy(content),
                "content": content
            }
            self.save()

    def get_cached_result(self, prompt_hash: str) -> Optional[str]:
        if prompt_hash in self.data.get("prompt_index", {}):
            genesis_hash = self.data["prompt_index"][prompt_hash]
            agents = self.data["genesis_index"].get(genesis_hash, {}).get("agents", {})
            return agents.get("final_synthesis", {}).get("content", None)
        return None
        
    def lookup_project_context(self, prompt: str) -> str:
        """Scans prompt for filenames and retrieves indexed content/optimizations."""
        if not os.path.exists(self.db_path):
            return ""
            
        context_buffer = []
        try:
            conn = sqlite3.connect(self.db_path)
            c = conn.cursor()
            
            # Simple heuristic: split prompt and look for exact filename matches in DB
            # This is efficient for "Analyze nexus_swarm.py"
            words = prompt.split()
            potential_files = [w for w in words if '.' in w]
            
            for fname in potential_files:
                # We search for paths ending with the filename
                c.execute("SELECT path, entropy, optimization_status, suggested_content, sha256 FROM project_index WHERE path LIKE ?", (f"%{fname}",))
                row = c.fetchone()
                if row:
                    path, entropy, status, suggestion, sha = row
                    content_to_use = suggestion if (status != "OPTIMAL" and suggestion) else f"[Content of {path}]"
                    
                    context_buffer.append(f"\n--- PROJECT FILE DETECTED: {path} ---")
                    context_buffer.append(f"Metrics: Entropy={entropy:.2f}, SHA256={sha[:8]}")
                    context_buffer.append(f"Status: {status}")
                    if status != "OPTIMAL":
                         context_buffer.append("NOTE: This file has pending optimizations in the index.")
                    # context_buffer.append(content_to_use[:1000]) # Limit context size
            
            conn.close()
        except Exception as e:
            return f"[DB Access Error: {e}]"
            
        return "\n".join(context_buffer)

# --- Async Streaming Engine ---

async def query_model_stream(
    session: aiohttp.ClientSession, 
    model: str, 
    prompt: str, 
    system: str = ""
) -> AsyncGenerator[str, None]:
    """Yields tokens from the model."""
    payload = {
        "model": model,
        "prompt": prompt,
        "system": system,
        "stream": True
    }
    try:
        async with session.post(OLLAMA_API, json=payload) as resp:
            if resp.status != 200:
                yield f"[Error {resp.status}]"
                return
            
            async for line in resp.content:
                if line:
                    try:
                        data = json.loads(line)
                        if "response" in data:
                            yield data["response"]
                        if data.get("done", False):
                            break
                    except:
                        pass
    except Exception as e:
        yield f"[Ex: {str(e)}]"

# --- UI Layout ---

def make_agent_grid(agent_data: Dict[str, Dict[str, str]]) -> Table:
    """
    Renders the Agent Grid with MD5 Hash Tags.
    agent_data structure: { "core": {"hash": "a1b2...", "content": "..."} }
    """
    table = Table(box=box.ROUNDED, expand=True, show_header=True, header_style="bold cyan")
    table.add_column("Agent / Origin Hash (MD5)", style="yellow", width=25)
    table.add_column("Token Stream (Trace)", no_wrap=False)
    
    for agent, data in agent_data.items():
        origin_hash_short = data['hash'][:8]
        content_preview = data['content'][-250:].replace("\n", " ") if data['content'] else "[Queued...]"
        
        agent_label = f"{agent}\n[dim]#{origin_hash_short}[/dim]"
        table.add_row(agent_label, content_preview)
    return table

def make_layout() -> Layout:
    layout = Layout()
    layout.split(
        Layout(name="header", size=4),
        Layout(name="main"),
        Layout(name="footer", size=10)
    )
    return layout

# --- Main Swarm Logic ---

async def run_swarm(prompt: str):
    memory = MindmapMemory(MEMORY_FILE)
    
    # 0. Connectivity & Selection
    is_online = check_connectivity()
    active_gatekeeper = MANDATORY_MODEL if is_online else DEFAULT_OFFLINE_MODEL
    active_synthesizer = MANDATORY_MODEL if is_online else DEFAULT_OFFLINE_MODEL
    
    # 1. Acceleration / Cache Check
    prompt_hash = generate_prompt_hash(prompt)
    cached = memory.get_cached_result(prompt_hash)
    if cached:
        console.print(Panel(cached, title="⚡ MEMORY RECALL (Accelerated)", border_style="bold yellow"))
        return

    # 2. Genesis Initialization
    genesis_hash = generate_genesis_hash(prompt)
    
    # Data Structures for UI & Logic
    # agent_outputs[short_name] = {'hash': md5, 'content': str}
    agent_outputs: Dict[str, Dict[str, str]] = {
        model.split(':')[0]: {"hash": generate_origin_hash(model, genesis_hash), "content": ""} 
        for model in PARALLEL_MODELS
    }
    
    gatekeeper_data = {"hash": generate_origin_hash("gatekeeper", genesis_hash), "content": ""}
    synthesis_data = {"hash": generate_origin_hash("synthesis", genesis_hash), "content": ""}
    
    status_msg = f"Network: {'ONLINE' if is_online else 'OFFLINE'} | Genesis: {genesis_hash[:8]}"

    layout = make_layout()

    def update_ui():
        # Header: Genesis & Gatekeeper
        header_text = f"ROOT: {genesis_hash}\nGATEKEEPER ({active_gatekeeper}) [#{gatekeeper_data['hash'][:8]}]: {gatekeeper_data['content'][-150:]}"
        layout["header"].update(Panel(header_text, title="GENESIS CONTROL", border_style="blue"))
        
        # Main: Parallel Streams
        layout["main"].update(Panel(make_agent_grid(agent_outputs), title="2π ENTROPY SWARM (Parallel Reasoning)", border_style="green"))
        
        # Footer: Status & Synthesis
        syn_preview = synthesis_data['content'][-400:] if synthesis_data['content'] else status_msg
        layout["footer"].update(Panel(syn_preview, title=f"FUSION INDEX ({active_synthesizer})", border_style="magenta"))

    # 3. Execution Loop
    with Live(layout, refresh_per_second=12, console=console) as live:
        memory.log_genesis(genesis_hash, prompt, prompt_hash)
        
        # --- Project Context Lookup ---
        project_context = memory.lookup_project_context(prompt)
        if project_context:
            console.print(Panel(project_context, title="📂 PROJECT INDEX RECALL", border_style="cyan"))
            # Augment prompt with context
            prompt = f"{prompt}\n\n[SYSTEM CONTEXT FROM INDEX]:\n{project_context}"
        
        async with aiohttp.ClientSession() as session:
            
            # --- PHASE A: GATEKEEPER STRATEGY ---
            status_msg = "Phase A: Gatekeeper Strategy..."
            update_ui()
            
            gate_sys = "You are the NEXUS Gatekeeper. Analyze the prompt naturally. Define a strategy."
            async for chunk in query_model_stream(session, active_gatekeeper, prompt, system=gate_sys):
                gatekeeper_data["content"] += chunk
                update_ui()
            
            memory.log_agent_stream(genesis_hash, "gatekeeper", gatekeeper_data["hash"], gatekeeper_data["content"])

            # --- PHASE B: PARALLEL SWARM (MD5 Tagged) ---
            status_msg = "Phase B: Parallel Reasoning (MD5 Tagged)..."
            update_ui()

            async def run_single_agent(model_name):
                short = model_name.split(':')[0]
                # Injecting the Genesis Hash into the context so the agent knows its root
                agent_context = (
                    f"GENESIS ROOT: {genesis_hash}\n"
                    f"YOUR ORIGIN ID: {agent_outputs[short]['hash']}\n"
                    f"STRATEGY: {gatekeeper_data['content']}\n"
                    f"TASK: Reasoning for '{prompt}'"
                )
                async for chunk in query_model_stream(session, model_name, agent_context, system="Provide verbose reasoning."):
                    agent_outputs[short]["content"] += chunk
                    # update_ui() # Implicitly handled by main loop refresh
            
            await asyncio.gather(*[run_single_agent(m) for m in PARALLEL_MODELS])
            
            # Log all agents
            for short, data in agent_outputs.items():
                memory.log_agent_stream(genesis_hash, short, data["hash"], data["content"])

            # --- PHASE C: REROOTING & FUSION ---
            status_msg = "Phase C: Rerooting & Final Fusion..."
            update_ui()
            
            # Constructing the Fusion Index
            fusion_context = "SOURCE MATERIAL (Indexed by MD5):\n"
            for short, data in agent_outputs.items():
                fusion_context += f"--- AGENT {short.upper()} [ID: {data['hash']}] ---\n{data['content']}\n\n"
            
            syn_sys = (
                "You are the NEXUS Synthesizer. "
                "Synthesize the MD5-indexed source material into a single, valid, human-like final answer. "
                "Resolve conflicts by weighting the reasoning quality."
            )
            
            async for chunk in query_model_stream(session, active_synthesizer, fusion_context, system=syn_sys):
                synthesis_data["content"] += chunk
                update_ui()
                
            memory.log_agent_stream(genesis_hash, "final_synthesis", synthesis_data["hash"], synthesis_data["content"])
            status_msg = "✅ SEQUENCE COMPLETE."
            update_ui()

    # Final Output
    console.print(Panel(synthesis_data["content"], title="FINAL FUSION ANSWER", border_style="bold magenta"))
    console.print(f"[dim]Genesis Hash: {genesis_hash}[/dim]")

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        console.print("[bold red]Usage:[/bold red] ./nexus_swarm.py \"Your Prompt Here\"")
        sys.exit(1)
    
    prompt = sys.argv[1]
    try:
        asyncio.run(run_swarm(prompt))
    except KeyboardInterrupt:
        console.print("\n[bold red]Swarm Interrupted.[/bold red]")