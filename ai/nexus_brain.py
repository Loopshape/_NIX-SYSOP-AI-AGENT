import sqlite3
import json
import sys
import os
import time
import urllib.request

# --- CONFIGURATION (WSL1 BRIDGE) ---
OLLAMA_URL = os.getenv("NEXUS_OLLAMA_URL", "http://localhost:11434")
MODEL = "gemma3:1b"  # Slim-edition for WSL1 performance
DB_PATH = os.path.expanduser("~/.nexus/spectrum_memory.db")

class NexusBrain:
    def __init__(self):
        os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
        self.conn = sqlite3.connect(DB_PATH)
        self.cursor = self.conn.cursor()
        self._initialize_db()

    def _initialize_db(self):
        """QUADRANT: DEFINE - Setting the structure of reality"""
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS spectrum (
                id INTEGER PRIMARY KEY,
                concept TEXT UNIQUE,
                data TEXT,        -- JSON blob for flexible storage
                reasoning TEXT,   -- The "Thinking" captured during learning
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        self.conn.commit()

    def ollama_request(self, prompt, system=""):
        """THE SPECTRUM - Bridging local logic to LLM reasoning"""
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
            return f"Error connecting to Ollama: {e}"

    def recognize(self, input_text):
        """QUADRANT: RECOGNIZE - Searching SQLite for known patterns"""
        # Simple keyword match for this implementation
        self.cursor.execute("SELECT data, reasoning FROM spectrum WHERE concept LIKE ?", (f"%{input_text}%",))
        return self.cursor.fetchone()

    def learn(self, concept, data, reasoning):
        """QUADRANT: SORT - Indexing new knowledge with reasoning"""
        try:
            self.cursor.execute(
                "INSERT OR REPLACE INTO spectrum (concept, data, reasoning) VALUES (?, ?, ?)",
                (concept, json.dumps(data), reasoning)
            )
            self.conn.commit()
            return True
        except Exception as e:
            print(f"[!] Sort Error: {e}")
            return False

    def process(self, user_input):
        """The Complete Schema Flow: Analysis -> Spectrum -> Focus/Quest"""
        print(f"\n[ANALYSIS] Input: {user_input}")
        
        # 1. RECOGNIZE
        known = self.recognize(user_input)
        
        if known:
            # 2. FOCUS
            data, reason = known
            print(f"[FOCUS] Memory found.")
            return f"I recall this. Context: {reason}\nData: {data}"
        
        else:
            # 3. QUEST & SPECTRUM
            print(f"[QUEST] No direct match. Invoking Spectrum reasoning...")
            
            # Ask Ollama to define the unknown based on the visual schema
            system_prompt = "You are a Learning Agent. Analyze the input. If you don't know it, provide a concise definition and explain the logic of why this is important."
            thinking = self.ollama_request(user_input, system=system_prompt)
            
            # 4. LEARN & ORDER
            print(f"[LEARN] Synthesizing reasoning...")
            self.learn(user_input, {"status": "learned"}, thinking)
            
            return f"I have learned something new.\nREASONING: {thinking}"

# --- CLI ROUTER ---
if __name__ == "__main__":
    brain = NexusBrain()
    
    if len(sys.argv) > 1:
        # One-shot query mode for ai.sh
        query = " ".join(sys.argv[1:])
        print(brain.process(query))
    else:
        # Interactive Loop
        print(f"=== NEXUS BRAIN ONLINE (Model: {MODEL}) ===")
        while True:
            try:
                inp = input("\nNEXUS > ")
                if inp.lower() in ['exit', 'quit']: break
                print(brain.process(inp))
            except KeyboardInterrupt:
                break
