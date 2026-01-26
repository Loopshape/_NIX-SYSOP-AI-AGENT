#!/usr/bin/env bash
set -e

echo "=== NEXUS Gemini-CLI Installer ==="

# Ask for installation directory
read -p "Enter installation directory (default ~/_) :" INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$HOME/_}

# Create directory structure
mkdir -p "$INSTALL_DIR/ai"
mkdir -p "$INSTALL_DIR/ui"

echo "[1/6] Copying AI scripts..."
# Copy AI scripts only if they exist and aren't already the same
[ -f ./ai.sh ] && cp -n ./ai.sh "$INSTALL_DIR/ai/" || echo "ai.sh already exists or missing"
[ -f ./nexus.mjs ] && cp -n ./nexus.mjs "$INSTALL_DIR/ai/" || echo "nexus.mjs already exists or missing"
[ -f ./memory.py ] && cp -n ./memory.py "$INSTALL_DIR/ai/" || echo "memory.py not found, skipping"

echo "[2/6] Creating Dockerfile..."
cat > "$INSTALL_DIR/ai/Dockerfile" << 'EOF'
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
EOF

echo "[3/6] Creating WebSocket Timeline Monitor..."
cat > "$INSTALL_DIR/ui/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>NEXUS Timeline Monitor</title>
  <style>
    body { font-family: monospace; background:#111; color:#eee; margin:0; padding:16px;}
    #timeline { display:flex; flex-wrap:wrap; gap:4px; }
    .state { padding:4px 6px; border-radius:4px; margin:2px; background:#222; }
    .branch { background:#4CAF50; }
    .loop { background:#FF9800; }
    .collapsed { background:#f44336; }
  </style>
</head>
<body>
  <h1>NEXUS Real-Time Timeline Monitor</h1>
  <div id="timeline"></div>

  <script type="module">
    const ws = new WebSocket("ws://localhost:8080");
    const timeline = document.getElementById("timeline");

    ws.onmessage = (msg) => {
      try {
        const data = JSON.parse(msg.data);
        const el = document.createElement("div");
        el.className = "state " + data.type;
        el.textContent = `${data.model} | ${data.hash.slice(0,6)} | ${data.status}`;
        timeline.appendChild(el);
      } catch(e) { console.error(e); }
    };
  </script>
</body>
</html>
EOF

echo "[4/6] Checking Docker BuildKit / legacy builder..."
# Fallback if buildx missing
if ! docker buildx version &>/dev/null; then
    echo "Buildx not found. Falling back to legacy builder."
    export DOCKER_BUILDKIT=0
fi

echo "[5/6] Building Docker image..."
docker build -t nexus-ai:latest "$INSTALL_DIR/ai"

echo "[6/6] Starting NEXUS container..."
docker run -d --name nexus-ai \
  -v "$INSTALL_DIR/ui":/root/_/ai/ui \
  -p 8080:8080 -p 11434:11434 \
  nexus-ai:latest

echo "=== NEXUS AI deployed successfully! ==="
echo "UI Timeline Monitor: $INSTALL_DIR/ui/index.html (http://localhost:8080 if using browser)"
echo "Stop container: docker stop nexus-ai"
echo "View logs: docker logs -f nexus-ai"

