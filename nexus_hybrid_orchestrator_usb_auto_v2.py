#!/usr/bin/env python3
# nexus_hybrid_orchestrator_usb_auto_v2.py

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

def log_warn(msg):
    print(f"[WARN] {msg}")

# -------------------------------
# ANDROID AUTO-DETECT
# -------------------------------

def detect_android_usb():
    try:
        result = subprocess.run(["adb", "devices"], capture_output=True, text=True, check=True)
        devices = [line.split()[0] for line in result.stdout.splitlines() if "\tdevice" in line]
        if not devices:
            log_warn("No Android devices detected. Offloading disabled.")
            return None
        device_id = devices[0]
        local_port = 8022
        subprocess.run(["adb", "-s", device_id, "forward", f"tcp:{local_port}", "tcp:8022"], check=True)
        log_info(f"Android detected: {device_id}, port forwarded to localhost:{local_port}")
        return {"host": "127.0.0.1", "port": local_port, "user": "u0_a123"}
    except Exception as e:
        log_warn(f"Android detection failed: {e}")
        return None

ANDROID_SSH = detect_android_usb()

# -------------------------------
# MODEL CHECK + DOWNLOAD
# -------------------------------

async def ensure_model_download(model_name, host="deskpro"):
    try:
        if host == "deskpro":
            result = subprocess.run(["ollama", "ls"], capture_output=True, text=True)
            if model_name not in result.stdout:
                log_info(f"Downloading model {model_name} on DeskPro...")
                subprocess.run(["ollama", "pull", model_name], check=True)
        elif host == "android" and ANDROID_SSH:
            ssh_cmd = [
                "ssh", "-p", str(ANDROID_SSH["port"]),
                f"{ANDROID_SSH['user']}@{ANDROID_SSH['host']}",
                f"ollama ls"
            ]
            result = subprocess.run(ssh_cmd, capture_output=True, text=True)
            if model_name not in result.stdout:
                log_info(f"Downloading model {model_name} on Android...")
                ssh_pull_cmd = [
                    "ssh", "-p", str(ANDROID_SSH["port"]),
                    f"{ANDROID_SSH['user']}@{ANDROID_SSH['host']}",
                    f"ollama pull {model_name}"
                ]
                subprocess.run(ssh_pull_cmd, check=True)
    except Exception as e:
        log_warn(f"Model check/download failed: {e}")

# -------------------------------
# SYSTEM LOAD CHECK
# -------------------------------

def get_deskpro_load():
    cpu = psutil.cpu_percent(interval=0.5)
    mem = psutil.virtual_memory().percent
    return 100 - max(cpu, mem)  # free capacity %

def get_android_load():
    if not ANDROID_SSH:
        return 0
    try:
        cmd = [
            "ssh", "-p", str(ANDROID_SSH["port"]),
            f"{ANDROID_SSH['user']}@{ANDROID_SSH['host']}",
            "top -b -n1 | head -5"
        ]
        output = subprocess.run(cmd, capture_output=True, text=True)
        match = re.search(r"Cpu\(s\):\s+(\d+\.\d+)", output.stdout)
        cpu = float(match.group(1)) if match else 50.0
        # Android RAM estimation (simplified)
        mem_match = re.search(r"Mem:\s+(\d+)k total,\s+(\d+)k free", output.stdout)
        mem = 50.0
        if mem_match:
            total = int(mem_match.group(1))
            free = int(mem_match.group(2))
            mem = 100 * free / total
        return 100 - max(cpu, mem)
    except:
        return 0

def choose_host_dynamic(agent_name):
    desk_load = get_deskpro_load()
    android_load = get_android_load()
    if android_load > desk_load and ANDROID_SSH:
        return "android"
    return "deskpro"

# -------------------------------
# RUN AGENT
# -------------------------------

async def run_ollama(agent_name, task_input, stream_file: Path):
    host = choose_host_dynamic(agent_name)
    model_name = AGENT_MODEL_MAP[agent_name]
    await ensure_model_download(model_name, host)

    log_info(f"[{host.capitalize()}:{agent_name}] Running {model_name}")

    if host == "deskpro":
        proc = await asyncio.create_subprocess_exec(
            "ollama", "run", model_name, "--prompt", task_input,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
    else:
        if not ANDROID_SSH:
            log_warn(f"[Android:{agent_name}] No device detected. Skipping.")
            return
        ssh_cmd = [
            "ssh", "-p", str(ANDROID_SSH["port"]),
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
            print(f"[{host}:{agent_name}] {decoded}")
    await proc.wait()
    log_info(f"[{host}:{agent_name}] Finished.")

# -------------------------------
# ORCHESTRATOR
# -------------------------------

async def orchestrate_task(task_input, agents=None):
    if agents is None:
        agents = list(AGENT_MODEL_MAP.keys())
    tasks = []
    for agent in agents:
        stream_file = STREAM_DIR / f"{agent}_{int(time.time())}.log"
        tasks.append(run_ollama(agent, task_input, stream_file))
    await asyncio.gather(*tasks)
    log_info("All agents completed task.")

# -------------------------------
# MAIN
# -------------------------------

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Text or URL to process")
    args = parser.parse_args()
    asyncio.run(orchestrate_task(args.input))

