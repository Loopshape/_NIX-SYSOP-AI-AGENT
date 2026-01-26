#!/usr/bin/env python3

import json
import os
import sys
import time
import urllib.request

# --- CONFIGURATION ---
OLLAMA_URL = os.getenv("NEXUS_OLLAMA_URL", "http://localhost:11434")
# Use the CORE model from ai.sh or fallback
MODEL = "deepseek-v3.1:671b-cloud" 
MEMORY_FILE = os.path.expanduser("~/.nexus/agent_memory.json")

# Robust stdout for UTF-8
if sys.stdout.encoding != 'utf-8':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import json
import os
import sys
import time
import subprocess

class NexusAgent:
    def __init__(self):
        self.identity = "NEXUS 2244-1"
        self.orchestrator = os.path.join(os.path.dirname(__file__), "ai.sh")

    def run_query(self, prompt):
        print(f"[*] NEXUS Dispatch: {prompt[:50]}...")
        try:
            result = subprocess.run(['bash', self.orchestrator, 'reason', prompt], 
                                   capture_output=True, text=True)
            if result.returncode == 0:
                output = result.stdout
                json_start = output.find('{')
                if json_start != -1:
                    return json.loads(output[json_start:])
            return {"error": result.stderr}
        except Exception as e:
            return {"error": str(e)}

    def run_loop(self):
        print(f"=== {self.identity} AGENT INTERFACE ===")
        while True:
            try:
                inp = input("\nNEXUS > ")
                if inp.lower() in ['exit', 'quit']: break
                
                res = self.run_query(inp)
                if "error" in res:
                    print(f"[!] Error: {res['error']}")
                else:
                    coord = res.get("coordinator", {})
                    print(f"\nAGENT >> {coord.get('response', 'No response')}")
                    print(f"[Logos: {res.get('workers', [{}])[0].get('confidence', 'N/A')}]") # Simplified confidence display
            except KeyboardInterrupt:
                break

if __name__ == "__main__":
    agent = NexusAgent()
    agent.run_loop()

if __name__ == "__main__":
    agent = NexusAgent()
    agent.run_loop()
