#!/bin/bash

echo "Fixing WSL Runtime AI System issues..."
echo "======================================"

# 1. Stop any running Ollama instances
pkill -f ollama 2>/dev/null || true

# 2. Reinstall Ollama with proper model
echo "Setting up Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
sleep 5

# Start Ollama in background
ollama serve &
OLLAMA_PID=$!
sleep 10

# 3. Pull a working model (llama2 is more likely to exist)
echo "Pulling llama2 model (this may take a while)..."
ollama pull llama2

# 4. Fix database issues
echo "Fixing database..."
DB_FILE="$HOME/.repository/wsl-runtime/ai_memory.db"
if [ -f "$DB_FILE" ]; then
    echo "Backing up old database..."
    mv "$DB_FILE" "${DB_FILE}.backup.$(date +%s)"
fi

# 5. Update the ai.sh script
echo "Updating AI script..."
chmod +x ~/_/ai/ai.sh

# 6. Test the system
echo "Testing the system..."
~/_/ai/ai.sh status

# 7. Create a simple test
echo "Running a simple test..."
~/_/ai/ai.sh reason "Test the system"

echo "======================================"
echo "Fix completed!"
echo "Now start the web interface:"
echo "cd ~/.repository/wsl-runtime && python3 -m http.server 8080"
echo ""
echo "Then access: http://localhost:8080"
echo ""
echo "To test AI: ~/_/ai/ai.sh reason \"Your question here\""

# Keep Ollama running
wait $OLLAMA_PID
