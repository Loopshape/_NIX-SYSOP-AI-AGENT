FROM python:3.12-slim

RUN apt-get update && apt-get install -y \
    curl git wget build-essential \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && pip install --no-cache-dir sentence-transformers sqlite3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root/_/ai

COPY ai.sh .
COPY nexus.mjs .
COPY memory.py .

EXPOSE 8080 11434

ENTRYPOINT ["bash","ai.sh"]
