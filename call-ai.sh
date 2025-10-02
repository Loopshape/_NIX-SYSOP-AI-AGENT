#!/bin/env bash

# Save Ollama output as JSON
ollama query 2244 "Summarize today's news" --json > ~/ollama_output.json
