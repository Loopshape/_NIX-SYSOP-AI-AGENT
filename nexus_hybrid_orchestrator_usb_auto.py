#!/usr/bin/env python3
# nexus_hybrid_orchestrator_usb_auto.py

import asyncio
import subprocess
import psutil
from pathlib import Path
import aiofiles
import time
import os
import re

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

HEAVY_MODELS = {"llama3:latest", "core:latest"}

# -------------------------------
# UTILITIES
# -------------------------------

def log_info(msg):
    print(f"[INFO] {msg}")

def choose_host(agent_name):
    return AGENT_HOST_MAP.get(agent_name, "deskpro")

# -------------------------------
# AUTO-DETECT AND PORT FORWARDING
# -------------------------------

def detect_android_usb():
    """Detect Android device over USB-C and return SSH details"""
    log_info("Detecting Android device via USB-C...")
    try:
        result = subprocess.run(["adb", "devices"], capture_output=True, text=True, check=True)
        devices = [line.split()[0] for line in result.stdout.splitlines() if "\tdevice" in line]
        if not devices:
            log_info("No Android devices detected. Offloading disabled.")
            return None
        device_id = devices[0]
        log_info(f"Found Android device: {device_id}")
        # Forward a local port to Termux SSH
        local_port = 8022
        subprocess.run(["adb", "-s", device_id, "forward", f"tcp:{local_port}", "tcp:8022"], check=True)
        log_info(f"Port forwarding set up: localhost:{local_port} -> Android:8022")
        return {"host": "127.0.0.1", "port": local_port, "user": "u0_a123"}  # Termux default UID
    except Exception as e:
        log_info(f"Android detection failed: {e}")
        return None

ANDROID_SSH = detect_android_usb()

# -------------------------------
# RUN AGENT FUNCTIONS
# -------------------------------

async def run_ollama_deskpro(agent_name, task_input, stream_file: Path):
    model_name = AGENT_MODEL_MAP[agent_name]
    log_info(f"[DeskPro:{agent_name}] Running {model_name}")
    proc = await asyncio.create_subprocess_exec(
        "ollama", "run", model_name, "--prompt", task_input,
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
    if ANDROID_SSH is None:
        log_info(f"[Android:{agent_name}] No device detected. Skipping.")
        return
    model_name = AGENT_MODEL_MAP[agent_name]
    log_info(f"[Android:{agent_name}] Running {model_name} via SSH")
    ssh_cmd = [
        "ssh",
        "-p", str(ANDROID_SSH["port"]),
        f"{ANDROID_SSH['user']}@{ANDROID_SSH['host']}",
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

