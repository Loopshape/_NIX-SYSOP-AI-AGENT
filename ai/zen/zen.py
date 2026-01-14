#!/usr/bin/env python3
"""
ZEN Python Wrapper for ML/Embedding Operations
"""
import sqlite3
import numpy as np
import hashlib
import json
import sys
import os
from pathlib import Path
from typing import List, Tuple, Optional
import requests
from datetime import datetime

class ZenEmbedder:
    """Handle text embeddings and similarity"""
    
    def __init__(self, ollama_host="http://localhost:11434"):
        self.ollama_host = ollama_host
        self.cache = {}
        
    def embed_text(self, text: str, model: str = "nomic-embed-text") -> np.ndarray:
        """Get text embedding from Ollama"""
        cache_key = hashlib.sha256(text.encode()).hexdigest()
        
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        try:
            response = requests.post(
                f"{self.ollama_host}/api/embeddings",
                json={"model": model, "prompt": text},
                timeout=30
            )
            response.raise_for_status()
            embedding = np.array(response.json()["embedding"], dtype=np.float32)
            self.cache[cache_key] = embedding
            return embedding
        except Exception as e:
            print(f"Embedding error: {e}", file=sys.stderr)
            # Fallback to simple TF-IDF like embedding
            return self.fallback_embed(text)
    
    def fallback_embed(self, text: str) -> np.ndarray:
        """Simple fallback embedding"""
        words = text.lower().split()
        vocab = list(set(words))
        embedding = np.zeros(384, dtype=np.float32)
        
        for i, word in enumerate(vocab[:384]):
            embedding[i] = words.count(word) / len(words)
        
        norm = np.linalg.norm(embedding)
        if norm > 0:
            embedding = embedding / norm
        
        return embedding
    
    def cosine_similarity(self, a: np.ndarray, b: np.ndarray) -> float:
        """Calculate cosine similarity"""
        dot = np.dot(a, b)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        
        if norm_a == 0 or norm_b == 0:
            return 0.0
        
        return float(dot / (norm_a * norm_b))
    
    def cluster_embeddings(self, embeddings: List[np.ndarray], k: int = 8) -> List[List[int]]:
        """Simple K-means clustering"""
        from sklearn.cluster import KMeans
        
        if len(embeddings) < k:
            k = len(embeddings)
        
        if k <= 1:
            return [list(range(len(embeddings)))]
        
        kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
        clusters = kmeans.fit_predict(embeddings)
        
        result = [[] for _ in range(k)]
        for idx, cluster_id in enumerate(clusters):
            result[cluster_id].append(idx)
        
        return result

class ZenEntropy:
    """Entropy and chaos management for parallel reasoning"""
    
    def __init__(self, seed: int = None):
        self.seed = seed or int(datetime.now().timestamp() * 1000)
        np.random.seed(self.seed)
        self.entropy_pool = []
        self.decay_rate = 0.95
        
    def generate_entropy(self, n: int = 8) -> List[float]:
        """Generate entropy values for agents"""
        entropies = np.random.uniform(0.1, 0.9, n)
        
        # Apply 2π/8 phase distribution
        phases = np.linspace(0, 2 * np.pi, n, endpoint=False)
        phase_mod = (np.sin(phases) + 1) / 2  # Convert to 0-1 range
        
        entropies = entropies * 0.7 + phase_mod * 0.3
        return entropies.tolist()
    
    def adjust_entropy(self, current: float, feedback: float) -> float:
        """Adjust entropy based on feedback"""
        new_entropy = current * self.decay_rate + feedback * (1 - self.decay_rate)
        return np.clip(new_entropy, 0.1, 0.9)
    
    def calculate_chaos_index(self, responses: List[str]) -> float:
        """Calculate chaos index from multiple responses"""
        if not responses:
            return 0.0
        
        # Measure diversity between responses
        similarities = []
        embedder = ZenEmbedder()
        
        for i in range(len(responses)):
            for j in range(i + 1, len(responses)):
                emb_i = embedder.embed_text(responses[i])
                emb_j = embedder.embed_text(responses[j])
                sim = embedder.cosine_similarity(emb_i, emb_j)
                similarities.append(sim)
        
        if similarities:
            avg_similarity = np.mean(similarities)
            chaos = 1.0 - avg_similarity
        else:
            chaos = 0.5
        
        return float(chaos)

class ZenParser:
    """Parse various input types"""
    
    @staticmethod
    def parse_input(input_str: str) -> dict:
        """Parse prompt/url/file/hash/walletseed"""
        result = {
            "type": "prompt",
            "content": input_str,
            "valid": True
        }
        
        # URL detection
        if input_str.startswith(("http://", "https://", "ftp://")):
            result["type"] = "url"
            try:
                response = requests.get(input_str, timeout=10)
                result["content"] = response.text[:10000]  # Limit
            except:
                result["valid"] = False
        
        # File detection
        elif os.path.exists(input_str):
            result["type"] = "file"
            try:
                with open(input_str, 'r', encoding='utf-8') as f:
                    result["content"] = f.read(10000)  # Limit
            except:
                result["valid"] = False
        
        # Hash detection (64 hex chars)
        elif len(input_str) == 64 and all(c in "0123456789abcdefABCDEF" for c in input_str):
            result["type"] = "hash"
        
        # Wallet seed detection (12 or 24 words)
        elif 12 <= len(input_str.split()) <= 24:
            result["type"] = "walletseed"
        
        return result
    
    @staticmethod
    def batch_process(file_path: str, operation: str = "crud") -> List[dict]:
        """Batch process file with CRUD/SOAP/REST operations"""
        results = []
        
        if not os.path.exists(file_path):
            return results
        
        with open(file_path, 'r') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                
                result = {
                    "line": line_num,
                    "input": line,
                    "operation": operation,
                    "status": "pending"
                }
                
                try:
                    if operation == "crud":
                        # CRUD operations on local data
                        parsed = ZenParser.parse_input(line)
                        result["parsed"] = parsed
                        result["status"] = "success"
                    
                    elif operation == "soap":
                        # SOAP-like operation
                        result["status"] = "soap_not_implemented"
                    
                    elif operation == "rest":
                        # REST API call
                        if line.startswith("http"):
                            response = requests.get(line, timeout=5)
                            result["response_code"] = response.status_code
                            result["status"] = "success"
                    
                    results.append(result)
                    
                except Exception as e:
                    result["status"] = f"error: {str(e)}"
                    results.append(result)
        
        return results

if __name__ == "__main__":
    # Command line interface
    if len(sys.argv) > 1:
        parser = ZenParser()
        
        if sys.argv[1] == "parse":
            result = parser.parse_input(sys.argv[2])
            print(json.dumps(result, indent=2))
        
        elif sys.argv[1] == "embed":
            embedder = ZenEmbedder()
            embedding = embedder.embed_text(sys.argv[2])
            print(f"Embedding shape: {embedding.shape}")
            print(f"First 10 values: {embedding[:10]}")
        
        elif sys.argv[1] == "entropy":
            entropy = ZenEntropy()
            values = entropy.generate_entropy(8)
            print(f"Entropy values: {values}")
            print(f"Chaos index: {entropy.calculate_chaos_index(sys.argv[2:])}")
