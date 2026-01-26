#!/bin/bash
# NEXUS-2244 Bootstrap Script

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Initializing NEXUS-2244 Cognition Engine...${NC}"

# 1. Environment Detection
if [ -d "/data/data/com.termux" ]; then
    ENV="Termux"
elif grep -q "Microsoft" /proc/version; then
    ENV="WSL"
else
    ENV="Linux"
fi
echo -e "Environment: ${GREEN}$ENV${NC}"

# 2. Dependency Check
echo -e "Checking dependencies..."
for cmd in node npm sqlite3 ollama; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is not installed.${NC}"
        exit 1
    fi
done

# 3. Install NPM Packages
if [ ! -d "node_modules" ]; then
    echo -e "Installing Node.js dependencies..."
    npm install
fi

# 4. Initialize Database
if [ ! -f "memory.db" ]; then
    echo -e "Initializing SQLite database..."
    sqlite3 memory.db < schema.sql
fi

# 5. Verify Ollama & Pull Models
echo -e "Verifying Ollama status..."
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo -e "${RED}Ollama is not running. Please start it with 'ollama serve'${NC}"
    # In some environments we might want to start it:
    # ollama serve &
    # sleep 5
fi

# Pull a lightweight model for agents
echo -e "Ensuring base model (llama3) is available..."
ollama pull llama3

# 6. Start Server
echo -e "${GREEN}Starting NEXUS-2244 Server...${NC}"
echo -e "REST API: http://localhost:8081"
echo -e "WebSocket: ws://localhost:8765"

node server.js
