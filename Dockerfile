# Base image with Node and Python
FROM python:3.12-slim

# Install Node, pip packages, and required system tools
RUN apt-get update && apt-get install -y \
    curl git wget build-essential \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && pip install --no-cache-dir sentence-transformers sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /root/_/ai

# Copy AI scripts
COPY ai.sh .
COPY nexus.mjs .
COPY memory.py .

# Expose ports (WebSocket + Ollama)
EXPOSE 8080 11434

# Entrypoint
ENTRYPOINT ["bash","ai.sh"]

