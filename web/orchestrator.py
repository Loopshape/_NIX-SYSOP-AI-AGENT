#!/usr/bin/env python3
import os, subprocess, json, sys

OLLAMA = "/home/linuxbrew/.linuxbrew/bin/ollama"
AGENTS = ["core","loop","wave","coin","code"]

BASE_DIR = "/home/loop/_/ai_orchestrator"
RESULTS_DIR = os.path.join(BASE_DIR, "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

def run_agent(agent_name, prompt):
    try:
        result = subprocess.run(
            [OLLAMA, "run", agent_name, "--prompt", prompt],
            capture_output=True, text=True, check=True
        )
        return {"agent": agent_name, "output": result.stdout.strip()}
    except subprocess.CalledProcessError as e:
        return {"agent": agent_name, "error": e.stderr.strip() if e.stderr else str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"status":"error","agents":[],"html_output":None,"error":"Missing prompt"}))
        sys.exit(1)

    prompt = sys.argv[1]
    agents_output = [run_agent(agent, prompt) for agent in AGENTS]

    final_html_path = os.path.join(RESULTS_DIR, "final.html")
    with open(final_html_path, "w") as f:
        f.write(f"<!DOCTYPE html><html><head><meta charset='UTF-8'><title>AI Output</title></head>"
                f"<body><pre>{json.dumps(agents_output, indent=2)}</pre></body></html>")

    print(json.dumps({"status":"ok","agents":agents_output,"html_output":final_html_path}))

