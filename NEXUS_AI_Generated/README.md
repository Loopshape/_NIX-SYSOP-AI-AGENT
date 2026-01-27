# NEXUS-AI-Agent-System

Autonomous multi-agent AI system with full web integration, 3D memory visualization, DOM diffing, and PDF reporting.

## Setup Instructions

### 1. Backend (WSL1)
1. Install dependencies:
   ```bash
   pip install -r backend/requirements.txt
   ```
2. Ensure Ollama is running:
   ```bash
   ollama serve
   ```
3. Start the NEXUS backend:
   ```bash
   python -m backend.app
   ```

### 2. Frontend (Browser)
1. Install the Tampermonkey extension in your browser.
2. Create a new script and paste the contents of `dashboard/nexus-ai.user.js`.
3. Save and enable the script.

## Usage
- Open any website.
- Press `CTRL + ALT + ENTER` to toggle the NEXUS Dashboard.
- Type prompts or commands into the input field.
- Use the **HEAT** button to visualize interaction heatmaps.
- Use the **SYNC** button to manually trigger DOM diffing.

## Agent Architecture
- **CORE**: Logical reasoning
- **CUBE**: 3D visualization
- **LOOP**: Iterative optimization
- **SIGN**: Pattern recognition
- **LINE**: Procedural execution
- **COIN**: Probabilistic analysis
- **WORK**: Workflow execution
- **CODE**: Programming and algorithm design

## Features
- **Entropy-Shifted Reasoning**: Rare concepts carry more weight in the swarm voting.
- **3D Memory Graph**: Visualized via Three.js in the dashboard.
- **DOM Diffing**: Real-time detection of page changes.
- **SQLite Persistence**: Cross-session memory and identity storage.
