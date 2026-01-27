#!/usr/bin/env python3
# nexus_hybrid_orchestrator.py
# DeskPro400G + S20 FE hybrid AI orchestrator

import asyncio
import subprocess
import psutil
from pathlib import Path
import aiofiles
import time
import os

# -------------------------------
# CONFIG
# -------------------------------

DESKPRO_MAX_RAM_GB = 6
MAX_CONCURRENT_DESKPRO_AGENTS = 3
STREAM_DIR = Path("/mnt/sdcard/nexus_streams")
STREAM_DIR.mkdir(exist_ok=True, parents=True)

# Map agents to preferred host: "deskpro" or "android"
AGENT_HOST_MAP = {
    "Cube": "deskpro",
    "Core": "deskpro",
    "Loop": "deskpro",
    "Coin": "deskpro",
    "Line": "deskpro",
    "Wave": "android",
    "Sign": "android",
    "Work": "android",
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

# DeskPro heavy models
HEAVY_MODELS = {"llama3:latest", "core:latest"}

# Android Termux SSH target
ANDROID_HOST = "127.0.0.1"  # USB tethering loopback
ANDROID_USER = "u0_a123"    # adjust to Termux UID
ANDROID_SSH_PORT = 8022      # forward port if needed

# -------------------------------
# UTILITIES
# -------------------------------

def log_info(msg):
    print(f"[INFO] {msg}")

def choose_host(agent_name):
    """Decide if agent runs on DeskPro or Android"""
    return AGENT_HOST_MAP.get(agent_name, "deskpro")

async def run_ollama_deskpro(agent_name, task_input, stream_file: Path):
    """Run Ollama agent locally"""
    model_name = AGENT_MODEL_MAP[agent_name]
    log_info(f"[DeskPro:{agent_name}] Running {model_name}")
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
            print(f"[DeskPro:{agent_name}] {decoded}")
    await proc.wait()
    log_info(f"[DeskPro:{agent_name}] Finished.")

async def run_ollama_android(agent_name, task_input, stream_file: Path):
    """Run Ollama agent on Android via SSH (Termux)"""
    model_name = AGENT_MODEL_MAP[agent_name]
    log_info(f"[Android:{agent_name}] Running {model_name}")
    
    ssh_cmd = [
        "ssh",
        "-p", str(ANDROID_SSH_PORT),
        f"{ANDROID_USER}@{ANDROID_HOST}",
        f"ollama run {model_name} --prompt '{task_input}'"
    ]
    proc = await asyncio.create_subprocess_exec(
        *ssh_cmd,
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
            print(f"[Android:{agent_name}] {decoded}")
    await proc.wait()
    log_info(f"[Android:{agent_name}] Finished.")

# -------------------------------
# ORCHESTRATOR
# -------------------------------

async def orchestrate_task(task_input, agents=None):
    if agents is None:
        agents = list(AGENT_MODEL_MAP.keys())

    deskpro_sem = asyncio.Semaphore(MAX_CONCURRENT_DESKPRO_AGENTS)
    tasks = []

    for agent in agents:
        stream_file = STREAM_DIR / f"{agent}_{int(time.time())}.log"
        host = choose_host(agent)

        async def agent_runner(agent=agent, stream_file=stream_file, host=host):
            if host == "deskpro":
                async with deskpro_sem:
                    await run_ollama_deskpro(agent, task_input, stream_file)
            else:
                await run_ollama_android(agent, task_input, stream_file)

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

