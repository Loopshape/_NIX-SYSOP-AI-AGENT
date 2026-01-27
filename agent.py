#!/bin/env python3

import json
import os
import sys
import time

# Robustness fix: Ensure the standard streams handle potential encoding issues
if sys.stdout.encoding != 'utf-8':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

class LearningAgent:
    def __init__(self, memory_file="agent_memory.json"):
        self.memory_file = memory_file
        self.spectrum_data = {}
        self.load_memory()

    def load_memory(self):
        """QUADRANT: DEFINE & SORT - Explicit UTF-8 loading"""
        if os.path.exists(self.memory_file):
            try:
                with open(self.memory_file, 'r', encoding='utf-8') as f:
                    self.spectrum_data = json.load(f)
            except (UnicodeDecodeError, json.JSONDecodeError):
                print("[!] Memory corruption detected. Re-initializing Spectrum.")
                self.initialize_default_memory()
        else:
            self.initialize_default_memory()

    def initialize_default_memory(self):
        self.spectrum_data = {
            "greetings": ["hello", "hi", "hey", "greetings"],
            "identity": {"name": "Nexus-1", "purpose": "Adaptive Learning Agent"},
            "concepts": {} 
        }
        self.save_memory()

    def save_memory(self):
        """QUADRANT: SORT - Explicit UTF-8 saving"""
        with open(self.memory_file, 'w', encoding='utf-8') as f:
            json.dump(self.spectrum_data, f, indent=4, ensure_ascii=False)

    def robust_input(self, prompt):
        """ADAPT: Handles terminal encoding errors gracefully"""
        try:
            return input(prompt)
        except UnicodeDecodeError:
            print("\n[!] Input Encoding Error. Re-routing through binary buffer...")
            # Fallback for systems with broken terminal locales
            return sys.stdin.buffer.readline().decode('utf-8', errors='replace').strip()

    def analyze(self, user_input):
        """THE STARTING LINE: ANALYSIS"""
        print(f"\n[ANALYSIS] Scanning input: '{user_input}'")
        return user_input.lower().strip()

    def think_spectrum(self, clean_input):
        """THE CENTER: SPECTRUM - Reasoning between Define and Recognize"""
        print("[SPECTRUM] Processing through reasoning core...")
        time.sleep(0.4)
        
        # RECOGNIZE phase
        for concept, definition in self.spectrum_data["concepts"].items():
            if concept in clean_input:
                return "FOCUS", definition
        
        if any(word in clean_input for word in self.spectrum_data["greetings"]):
            return "ORDER", f"Hello! I am {self.spectrum_data['identity']['name']}. Recognition complete."
        
        return "QUEST", clean_input

    def run_loop(self):
        print("=== LEARNING AGENT ONLINE (Robust-Mode) ===")
        print("Schema: Define | Sort | Recognize | Order")

        while True:
            try:
                raw_input = self.robust_input("\nUSER > ")
                if not raw_input: continue
                if raw_input.lower() in ['exit', 'quit']: break

                # 1. ANALYSIS
                processed = self.analyze(raw_input)

                # 2. SPECTRUM / RECOGNIZE
                mode, result = self.think_spectrum(processed)

                # 3. OUTPUT FORKS (ADAPT & BUILD)
                if mode == "FOCUS":
                    print(f"[FOCUS] Accessing Specific Memory...")
                    print(f"AGENT >> {result}")

                elif mode == "ORDER":
                    print(f"[ORDER] Executing response protocol...")
                    print(f"AGENT >> {result}")

                elif mode == "QUEST":
                    print(f"[QUEST] Gap detected in current Spectrum.")
                    print(f"AGENT >> I don't recognize '{result}'. How would you DEFINE this?")
                    
                    new_definition = self.robust_input(f"TEACH AGENT > ")
                    
                    # 4. LEARN / SORT
                    print(f"[LEARN] Updating Knowledge Graph...")
                    self.spectrum_data["concepts"][result] = new_definition
                    self.save_memory()
                    print(f"[SORT] Persistence successful.")

            except KeyboardInterrupt:
                break
        print("\n[SHUTDOWN] Saving state... Goodbye.")

if __name__ == "__main__":
    agent = LearningAgent()
    agent.run_loop()
