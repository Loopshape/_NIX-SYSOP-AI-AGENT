import requests
import json
import asyncio
import hashlib
from .entropy import calculate_entropy
from .persistence import save_memory

OLLAMA_URL = "http://localhost:11434/api/generate"
DEFAULT_MODEL = "llama3" # Or whatever is available

class Agent:
    def __init__(self, id, name, personality, specialty):
        self.id = id
        self.name = name
        self.personality = personality
        self.specialty = specialty

    async def reason(self, prompt, context=""):
        system_prompt = f"You are {self.name}, the {self.id} agent of the NEXUS-AI system. Personality: {self.personality}. Specialty: {self.specialty}. Respond according to your specialty."
        full_prompt = f"{system_prompt}\n\nContext: {context}\n\nTask: {prompt}"
        
        payload = {
            "model": DEFAULT_MODEL,
            "prompt": full_prompt,
            "stream": False
        }
        
        try:
            response = requests.post(OLLAMA_URL, json=payload, timeout=30)
            if response.status_code == 200:
                result = response.json().get('response', '')
                return {
                    "agent": self.id,
                    "response": result,
                    "entropy": calculate_entropy(result)
                }
        except Exception as e:
            return {"agent": self.id, "error": str(e)}
        return {"agent": self.id, "error": "Unknown failure"}

class AgentSwarm:
    def __init__(self):
        self.agents = [
            Agent('CORE', 'Core Intelligence', 'Logical and structured', 'General reasoning and coordination'),
            Agent('CUBE', 'Visual Architect', 'Spatial and geometric', '3D visualization and mapping'),
            Agent('LOOP', 'Iterative Optimizer', 'Refining and persistent', 'Optimization and self-improvement'),
            Agent('SIGN', 'Pattern Recon', 'Observant and symbolic', 'Pattern recognition and meaning'),
            Agent('LINE', 'Procedural Executor', 'Methodical and linear', 'Execution and workflow'),
            Agent('COIN', 'Probabilistic Analyst', 'Stochastic and analytical', 'Risk and probability'),
            Agent('WORK', 'Task Master', 'Efficiency-driven', 'Operational execution'),
            Agent('CODE', 'Digital Architect', 'Algorithmic and technical', 'Software and logic design')
        ]

    async def process(self, prompt, context=""):
        tasks = [agent.reason(prompt, context) for agent in self.agents]
        results = await asyncio.gather(*tasks)
        
        # Filter out errors
        valid_results = [r for r in results if 'error' not in r]
        
        if not valid_results:
            return {"error": "No valid agent responses"}

        # Multi-agent voting / consensus
        # For now, we use entropy-weighted selection or a final synthesis
        best_result = max(valid_results, key=lambda x: x['entropy'])
        
        # Save to memory
        resp_hash = hashlib.sha256((prompt + best_result['response']).encode()).hexdigest()
        save_memory(resp_hash, prompt, best_result['response'], best_result['agent'], "general", best_result['entropy'])
        
        return {
            "best": best_result,
            "swarm_results": valid_results,
            "hash": resp_hash
        }
