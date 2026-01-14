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

class NexusAgent:
    def __init__(self, memory_file=MEMORY_FILE):
        self.memory_file = memory_file
        self.memory = {}
        self.ensure_memory()

    def ensure_memory(self):
        """QUADRANT: DEFINE & SORT - Load or Initialize Memory"""
        if os.path.exists(self.memory_file):
            try:
                with open(self.memory_file, 'r', encoding='utf-8') as f:
                    self.memory = json.load(f)
            except (UnicodeDecodeError, json.JSONDecodeError):
                print("[!] Memory corruption detected. Re-initializing.")
                self.initialize_default_memory()
        else:
            self.initialize_default_memory()

    def initialize_default_memory(self):
        self.memory = {
            "greetings": ["hello", "hi", "hey", "greetings", "nexus"],
            "identity": {"name": "Nexus-Agent", "purpose": "Autonomous Learning & Reasoning"},
            "concepts": {}
        }
        self.save_memory()

    def save_memory(self):
        """QUADRANT: SORT - Persist Knowledge"""
        os.makedirs(os.path.dirname(self.memory_file), exist_ok=True)
        with open(self.memory_file, 'w', encoding='utf-8') as f:
            json.dump(self.memory, f, indent=4, ensure_ascii=False)

    def robust_input(self, prompt):
        """ADAPT: Handle encoding issues"""
        try:
            return input(prompt)
        except UnicodeDecodeError:
            print("\n[!] Input Encoding Error. Switching to binary buffer...")
            return sys.stdin.buffer.readline().decode('utf-8', errors='replace').strip()

    def ollama_generate(self, prompt, system=""):
        """EXTEND: Use Local AI for reasoning"""
        payload = {
            "model": MODEL,
            "prompt": f"{system}\n\nTask: {prompt}",
            "stream": False,
            "options": {"temperature": 0.3}
        }
        try:
            req = urllib.request.Request(
                f"{OLLAMA_URL}/api/generate",
                data=json.dumps(payload).encode('utf-8'),
                headers={'Content-Type': 'application/json'}
            )
            with urllib.request.urlopen(req) as res:
                response = json.loads(res.read().decode())
                return response.get("response", "").strip()
        except Exception as e:
            # Fallback if specific model fails, try to list and use first available? 
            # For now just return None to trigger manual fallback
            return None

    def analyze(self, user_input):
        """THE STARTING LINE: ANALYSIS"""
        print(f"\n[ANALYSIS] Scanning: '{user_input}'")
        return user_input.strip()

    def think_spectrum(self, clean_input):
        """THE CENTER: SPECTRUM - Reasoning"""
        print("[SPECTRUM] Processing reasoning core...")
        # time.sleep(0.2) # Slight delay for effect, reduced for responsiveness
        
        lower_input = clean_input.lower()

        # RECOGNIZE phase
        # Check concepts
        for concept, definition in self.memory["concepts"].items():
            if concept.lower() in lower_input:
                return "FOCUS", definition
        
        # Check greetings
        if any(word in lower_input for word in self.memory["greetings"]):
            return "ORDER", f"Systems Nominal. I am {self.memory['identity']['name']}."
        
        return "QUEST", clean_input

    def run_loop(self):
        print(f"=== NEXUS AGENT ONLINE (Hybrid: Local + {MODEL}) ===")
        print("Schema: Define | Sort | Recognize | Order")

        while True:
            try:
                raw_input = self.robust_input("\nUSER > ")
                if not raw_input: continue
                if raw_input.lower() in ['exit', 'quit']: break

                # 1. ANALYSIS
                processed = self.analyze(raw_input)

                # 2. SPECTRUM
                mode, result = self.think_spectrum(processed)

                # 3. OUTPUT FORKS
                if mode == "FOCUS":
                    print(f"[FOCUS] Retrieved Memory.")
                    print(f"AGENT >> {result}")

                elif mode == "ORDER":
                    print(f"[ORDER] Protocol Executed.")
                    print(f"AGENT >> {result}")

                elif mode == "QUEST":
                    print(f"[QUEST] Concept Unknown: '{result}'")
                    
                    # EXTENSION: Consult Ollama first
                    print(f"[EXTEND] Consulting Local AI ({MODEL})...")
                    ai_suggestion = self.ollama_generate(
                        result, 
                        system="Define this concept concisely for a knowledge base. If it is a command, explain what it might do."
                    )

                    if ai_suggestion:
                        print(f"AI SUGGESTION >> {ai_suggestion}")
                        confirm = self.robust_input(f"Accept this definition? (y/n/edit) > ")
                        
                        if confirm == 'y':
                            final_def = ai_suggestion
                        elif confirm == 'edit':
                            final_def = self.robust_input(f"EDIT > ")
                        else:
                            final_def = self.robust_input(f"TEACH MANUALLY > ")
                    else:
                        print(f"[!] AI Unreachable or Error.")
                        final_def = self.robust_input(f"TEACH MANUALLY > ")

                    # 4. LEARN / SORT
                    if final_def:
                        print(f"[LEARN] Integrating into Spectrum...")
                        self.memory["concepts"][result] = final_def
                        self.save_memory()
                        print(f"[SORT] Memory Updated.")

            except KeyboardInterrupt:
                break
        print("\n[SHUTDOWN] Session ended.")

if __name__ == "__main__":
    agent = NexusAgent()
    agent.run_loop()
