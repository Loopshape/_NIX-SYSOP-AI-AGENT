#!/usr/bin/env python3
import os, subprocess, json, sys

# === CONFIG ===
OLLAMA = "/home/linuxbrew/.linuxbrew/bin/ollama"  # absolute path
AGENTS = ["core", "loop", "wave", "coin", "code"]

BASE_DIR = "/home/loop/_/ai_orchestrator"
RESULTS_DIR = os.path.join(BASE_DIR, "results")
LOGS_DIR = os.path.join(BASE_DIR, "logs")
os.makedirs(RESULTS_DIR, exist_ok=True)
os.makedirs(LOGS_DIR, exist_ok=True)

# Helper: run one agent
def run_agent(agent_name, prompt):
    try:
        result = subprocess.run(
            [OLLAMA, "run", agent_name, "--prompt", prompt],
            capture_output=True,
            text=True,
            check=True
        )
        return {"agent": agent_name, "output": result.stdout.strip()}
    except subprocess.CalledProcessError as e:
        return {"agent": agent_name, "error": e.stderr.strip() if e.stderr else str(e)}
    except FileNotFoundError as e:
        return {"agent": agent_name, "error": str(e)}

# === MAIN ===
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({
            "status": "error",
            "agents": [],
            "html_output": None,
            "error": "Missing prompt"
        }))
        sys.exit(1)

    prompt = sys.argv[1]

    # Run all agents
    agents_output = [run_agent(agent, prompt) for agent in AGENTS]

    # Write final HTML
    final_html_path = os.path.join(RESULTS_DIR, "final.html")
    with open(final_html_path, "w") as f:
        f.write(
            "<!DOCTYPE html><html><head><meta charset='UTF-8'>"
            "<title>AI Output</title></head><body>"
            "<pre>" + json.dumps(agents_output, indent=2) + "</pre>"
            "</body></html>"
        )

    # Output JSON
    print(json.dumps({
        "status": "ok",
        "agents": agents_output,
        "html_output": final_html_path
    }))

