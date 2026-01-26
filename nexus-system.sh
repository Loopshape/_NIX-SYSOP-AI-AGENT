gemini-cli generate \
--name "NEXUS-AI-Agent-System" \
--description "Autonomous multi-agent AI system with full web integration, 3D memory visualization, DOM diffing, timeline replay, heatmaps, and PDF reporting for universities and tech companies." \
--output "./NEXUS_AI_Generated" \
--language "javascript, html, css, python" \
--prompt "TASK: Generate a fully autonomous, web-integrated AI system named 'NEXUS-AI' that runs locally via WSL1 Ollama (localhost:11434), capable of analyzing, enhancing, and interacting with live HTML5 websites, supporting multi-agent reasoning, and persisting memory. The system must include all core features:

TARGET ENVIRONMENT:
- Local WSL1 Linux Subsystem on Windows 10
- Ollama AI Slim Edition (host: localhost:11434)
- Browser integration via Tampermonkey userscript
- Frontend: HTML5, CSS3, JavaScript (jQuery 3, GSAP, Three.js)
- Storage: SQLite + GM_setValue (for persistence)
- Output: PDF/HTML reports, memory export

AGENT ARCHITECTURE:
- 8 agents: CORE, CUBE, LOOP, SIGN, LINE, COIN, WORK, CODE
- 2Pi/8 entropy-shifted reasoning pool
- Multi-agent voting system to select best response
- Agent personalities:
  CORE: logical reasoning
  CUBE: 3D visualization
  LOOP: iterative optimization
  SIGN: pattern recognition
  LINE: procedural execution
  COIN: probabilistic analysis
  WORK: workflow execution
  CODE: programming and algorithm design

KEY FEATURES:
1. DOM analysis & diffing per AI response
2. 3D memory graph visualization (Three.js)
3. Heatmap overlay on live page
4. Timeline scrubber and branch replay
5. Multi-agent voting for best output
6. Cross-session memory persistence with SQLite export
7. Autonomous refactoring & self-training
8. Web-wide orchestration
9. Agent personalities and entropy-shifted reasoning

PROMPT HANDLING:
- Parallel processing by all agents
- Entropy-based sorting & fractal SHA256/MD5 rehashing
- Best response selected via multi-agent voting
- Enhance responses via iterative reasoning

DASHBOARD & UI:
- Embedded Tampermonkey dashboard
- Sections: Agent pool, 3D graph, memory timeline, control panel, status bar
- Controls: prompt input, model selection, sync DOM, export memory, entropy reset
- Shortcut: CTRL+ALT+ENTER opens dashboard
- Live visual overlays for DOM changes and heatmaps

PDF REPORT:
- Landscape A4, professional layout
- Include screenshots, 3D memory graphs, heatmaps, timeline snapshots
- Documentation for universities or tech companies

OUTPUT REQUIREMENTS:
- Fully working Tampermonkey userscript
- Modular, maintainable code
- Example PDF report of system operation
- Detailed logging of agent reasoning and entropy decisions

CONSTRAINTS:
- Fully offline with local WSL1 Ollama
- Only open-source or local tools
- Scalable to multiple webpages and repositories
- Robust error handling for timeouts, memory overflow, or DOM conflicts

GENERATE:
- All code for userscript, dashboard, and visualization
- Commented sections for clarity
- PDF scaffolding for reporting
- Ready for direct deployment in Tampermonkey + WSL1 Ollama environment."

