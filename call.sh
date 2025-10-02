# Save Ollama output as JSON
#ollama query 2244 "Summarize today's news" --json > ~/ollama_output.json

{
  "prompt": "Summarize today's AI news",
  "parameters": {
    "temperature": 0.7,
    "max_tokens": 500
  }
}
