#!/bin/env python3

import sys
import os
import time
from flask import Flask, request, jsonify
from flask_cors import CORS

# Add the current directory to sys.path so we can import from ai/
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from ai.nexus_brain import NexusBrain

app = Flask(__name__)
CORS(app) 

# Initialize the Brain
print("[SERVER] Initializing Nexus Psychologic Core...")
brain = NexusBrain()
print("[SERVER] Brain Online.")

@app.route('/process', methods=['POST'])
def process_data():
    """
    API endpoint that accepts JSON input and returns the Nexus Brain's structured thought process.
    """
    try:
        data = request.get_json()
        input_query = data.get('query', '')
        
        if not input_query:
            return jsonify({"error": "No 'query' provided."}), 400

        print(f"[SERVER] Processing: {input_query}")
        
        # Use the structured processing method
        result = brain.process_structured(input_query)
        
        return jsonify({
            "status": "success",
            "thoughts": result['thoughts'],
            "memory_context": result['memory_context'],
            "final_output": result['final_output'],
            "learned_concept": result['learned_concept'],
            "timestamp": time.time()
        })

    except Exception as e:
        print(f"[SERVER] Error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/status', methods=['GET'])
def status():
    return jsonify({"status": "online", "model": "Nexus-8"})

if __name__ == '__main__':
    port = 11435
    print(f"[SERVER] Starting Nexus Server on http://127.0.0.1:{port}/")
    app.run(debug=True, port=port, host='0.0.0.0')