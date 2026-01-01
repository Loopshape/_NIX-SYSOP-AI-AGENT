#!/bin/env python3

# Prerequisite: You must install Flask and Flask-CORS
# pip install Flask Flask-CORS

from flask import Flask, request, jsonify
from flask_cors import CORS
import time

app = Flask(__name__)
# Enable CORS for all routes, allowing your frontend (running on a different origin/port) 
# to communicate with this server. IMPORTANT for local development!
CORS(app) 

# --- Placeholder AI Model Logic ---
def run_ai_prediction(input_text):
    """
    Simulates a time-consuming AI inference process.
    Replace this function with your actual model loading and prediction logic.
    """
    print(f"Received input: {input_text}")
    
    # Simulate model processing time
    time.sleep(1.5) 

    # Generate a dummy response based on the input
    processed_text = input_text.upper().replace(' ', '-')
    confidence_score = 0.95 
    
    return {
        "output": f"Processed: {processed_text}",
        "status": "success",
        "score": confidence_score
    }
# --- End of Placeholder Logic ---


@app.route('/process', methods=['POST'])
def process_data():
    """
    API endpoint that accepts JSON input and returns the AI's result.
    """
    try:
        # Get JSON data from the incoming request
        data = request.get_json()
        input_query = data.get('query', '')
        
        if not input_query:
            return jsonify({"error": "No 'query' provided in the request body."}), 400

        # Run the simulated AI function
        ai_result = run_ai_prediction(input_query)
        
        # Return the structured result as JSON
        return jsonify({
            "result": ai_result['output'],
            "confidence": ai_result['score'],
            "server_time": time.time()
        })

    except Exception as e:
        print(f"Error during processing: {e}")
        return jsonify({"error": "An internal server error occurred."}), 500

if __name__ == '__main__':
    # Run the server on http://127.0.0.1:11435/
    print("Starting Flask AI Server on http://127.0.0.1:11435/")
    app.run(debug=True, port=11435)
