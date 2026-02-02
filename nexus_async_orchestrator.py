#!/usr/bin/env python3
# nexus_async_orchestrator.py
# Optimized for DeskPro400G + S20 FE + MicroSD

import asyncio
import subprocess
import psutil
from pathlib import Path
import aiohttp
import aiofiles
import time
import os
from rich.console import Console

console = Console()

# -------------------------------
# CONFIG
# -------------------------------

STREAM_DIR = Path("/mnt/sdcard/nexus_streams")  # fallback MicroSD
STREAM_DIR.mkdir(exist_ok=True, parents=True)

# Ollama models available
MODELS = {
    "gemma3:1b": {"size_gb": 0.8},
    "wave:latest": {"size_gb": 0.8},
    "core:latest": {"size_gb": 0.8},
    "llama3:latest": {"size_gb": 4.7},
    "code:latest": {"size_gb": 0.8},
}

AGENT_MODEL_MAP = {
    "Cube": "core:latest",
    "Core": "core:latest",
    "Loop": "loop:latest",
    "Coin": "coin:latest",
    "Line": "line:latest",
    "Wave": "wave:latest",
    "Sign": "gemma3:1b",
    "Work": "code:latest",
}

MAX_RAM_USAGE_GB = 6  # leave headroom for OS & other processes
MAX_CONCURRENT_AGENTS = 4  # DeskPro constraint

# -------------------------------
# UTILITIES
# -------------------------------

def log_info(msg):
    console.log(f"[bold cyan][INFO][/bold cyan] {msg}")

def get_network_speed_mbps():
    # crude: returns download speed in Mbps
    try:
        import speedtest
        st = speedtest.Speedtest()
        return st.download() / 1e6
    except Exception:
        return 0.0

def choose_agent_weighted(agents):
    """Selects least-loaded agent based on RAM + model size + CPU"""
    scores = []
    free_ram = psutil.virtual_memory().available / (1024**3)
    cpu_load = psutil.cpu_percent(interval=0.1)
    for agent in agents:
        model_key = AGENT_MODEL_MAP[agent]
        model_size_gb = MODELS.get(model_key, {"size_gb":1})["size_gb"]
        score = free_ram / (model_size_gb + 0.1) - cpu_load/100
        scores.append((score, agent))
    scores.sort(reverse=True)
    return scores[0][1]

async def safe_model_pull(model_name: str):
    """Download Ollama model if missing and network allows"""
    exists = subprocess.run(["ollama", "ls"], capture_output=True, text=True)
    if model_name in exists.stdout:
        log_info(f"Model {model_name} exists locally, skipping download.")
        return
    speed = get_network_speed_mbps()
    if speed < 5:
        log_info(f"Network too slow ({speed:.1f} Mbps) for {model_name}, skipping download.")
        return
    log_info(f"Pulling model {model_name} ({speed:.1f} Mbps)...")
    await asyncio.create_subprocess_exec("ollama", "pull", model_name)

async def run_ollama_agent(agent_name, task_input, stream_file: Path):
    """Run agent in streaming mode, write line-by-line"""
    model_name = AGENT_MODEL_MAP[agent_name]
    log_info(f"[{agent_name}] Starting streaming with {model_name}")
    
    # ensure model is downloaded
    await safe_model_pull(model_name)

    proc = await asyncio.create_subprocess_exec(
        "ollama", "run", model_name,
        "--prompt", task_input,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )

    async with aiofiles.open(stream_file, "a") as f:
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
            decoded = line.decode("utf-8").strip()
            await f.write(decoded + "\n")
            print(f"[{agent_name}] {decoded}")

    await proc.wait()
    log_info(f"[{agent_name}] Finished task.")

# -------------------------------
# ORCHESTRATOR
# -------------------------------

async def orchestrate_task(task_input, agents=None):
    if agents is None:
        agents = list(AGENT_MODEL_MAP.keys())
    
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_AGENTS)
    tasks = []

    for agent in agents:
        stream_file = STREAM_DIR / f"{agent}_{int(time.time())}.log"
        
        async def agent_runner(agent=agent, stream_file=stream_file):
            async with semaphore:
                await run_ollama_agent(agent, task_input, stream_file)
        
        tasks.append(agent_runner())

    await asyncio.gather(*tasks)
    log_info("All agents completed task.")

# -------------------------------
# MAIN ENTRY
# -------------------------------

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Text or URL to process")
    args = parser.parse_args()

    asyncio.run(orchestrate_task(args.input))

