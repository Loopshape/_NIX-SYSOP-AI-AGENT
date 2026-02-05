#!/bin/env python3

import anthropic

client = anthropic.Anthropic(
    # defaults to os.environ.get("ANTHROPIC_API_KEY")
    api_key="my_api_key",
)

message = client.messages.create(
    model="claude-haiku-4-5-20251001",
    max_tokens=64000,
    temperature=1,
    system="build a html singlefile with es module nodejs and python3 as hybrid",
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": r"""### USE THIS FOR THE DESIGN LAYOUT:

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nemodian 2244-1 :: Quantum Fractal AI Editor</title>
    <style>
        :root {
            --muted: #888;
            --info: #2196F3;
            --warn: #FF9800;
            --error: #F44336;
            --success: #4CAF50;
            --baseline: 1.5em;
            --header-h: calc(var(--baseline) * 1.6);
            --status-h: var(--baseline);
            --footer-h: calc(var(--baseline) * 2);
            --font-size: 13px;
            --ln-width: 50px;
            --theme-bg: #3a3c31;
            --panel: #313328;
            --header-bg: #2e3026;
            --status-bg: #22241e;
            --accent: #4ac94a;
            --muted-text: #999966;
            --err: #a03333;
            --warn-bg: #f0ad4e;
            --hover-blue: #3366a0;
            --info-bg: #5bc0de;
            --agent-nexus: #BB86FC;
            --agent-cognito: #03DAC6;
            --agent-relay: #FFD54F;
            --agent-sentinel: #CF6679;
            --agent-echo: #4ac94a;
            --quantum-glow: rgba(187, 134, 252, 0.6);
        }
		
		html {
			position: relative;
			display: block;
			width: 100%;
			height: 100%;
		}

        html, body {
            height: 100%;
            margin: 0;
            padding: 0;
            font-family: 'Fira Code', monospace;
            font-size: var(--font-size);
            line-height: var(--baseline);
            background: var(--theme-bg);
            color: #f0f0e0;
            overflow: hidden;
        }

        body {
            display: grid;
            grid-template-rows: var(--header-h) var(--status-h) 1fr var(--footer-h);
        }

        header {
            grid-row: 1;
            grid-column: 1 / -1;
            background: var(--header-bg);
            border-bottom: 1px solid #22241e;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 6px 12px;
            position: relative;
            overflow: hidden;
        }

        header::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, var(--quantum-glow), transparent);
            animation: quantumScan 3s infinite linear;
        }

        @keyframes quantumScan {
            0% { left: -100%; }
            100% { left: 100%; }
        }

        .quantum-pulse {
            animation: quantumPulse 2s infinite alternate;
        }

        .typing-active {
            caret-color: lime;
            animation: blink 1s infinite;
        }

        @keyframes blink {
            0%, 50% { background-color: transparent; }
            51%, 100% { background-color: rgba(0,255,0,0.05); }
        }

        @keyframes quantumPulse {
            0% { opacity: 0.7; transform: scale(1); }
            100% { opacity: 1; transform: scale(1.05); }
        }

        header .left {
            display: flex;
            gap: 12px;
            align-items: center;
            position: relative;
            z-index: 2;
        }

        header .right {
            display: flex;
            gap: 8px;
            align-items: center;
            position: relative;
            z-index: 2;
        }

        button {
            background: var(--err);
            border: 1px solid var(--err);
            color: #f0f0e0;
            padding: 6px 8px;
            cursor: pointer;
            font-size: 12px;
            transition: all .2s;
            border-radius: 3px;
        }

        button:hover {
            background: var(--hover-blue);
            border-color: var(--hover-blue);
        }

        button.success {
            background: var(--accent);
            border-color: var(--accent);
        }

        button.info {
            background: var(--info-bg);
            border-color: var(--info-bg);
        }

        button.warn {
            background: var(--warn-bg);
            border-color: var(--warn-bg);
            color: #3a3c31;
        }

        #status-bar {
            grid-row: 2;
            grid-column: 1 / -1;
            background: var(--status-bg);
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 4px 12px;
            font-size: 12px;
            position: relative;
        }

        .quantum-threads {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            opacity: 0.3;
        }

        .quantum-thread {
            position: absolute;
            width: 1px;
            height: 100%;
            background: linear-gradient(to bottom, transparent, var(--agent-nexus), transparent);
            animation: threadFlow 2s infinite linear;
        }

        @keyframes threadFlow {
            0% { top: -100%; }
            100% { top: 100%; }
        }
		
		#editor {
			overflow: hidden;
		}

        #editor-stage {
            grid-row: 3;
            grid-column: 1 / -1;
            display: grid;
            grid-template-columns: 0px 1fr;
            background: var(--theme-bg);
            overflow: hidden;
            position: relative;
            transition: grid-template-columns 0.3s ease;
        }

        #editor-stage.left-panel-open {
            grid-template-columns: 240px 1fr;
        }

        #left-panel {
            background: var(--panel);
            border-right: 1px solid #22241e;
            padding: 10px;
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
            gap: 8px;
            overflow: hidden;
            width: 240px;
        }

        .editor-container {
            position: relative;
            display: flex;
            flex: 1;
            background: var(--theme-bg);
            overflow: auto;
        }

        .line-numbers {
            width: var(--ln-width);
            padding: 10px 8px;
            background: var(--panel);
            color: var(--muted-text);
            font-variant-numeric: tabular-nums;
            text-align: right;
            user-select: none;
            line-height: var(--baseline);
            font-family: inherit;
            font-size: inherit;
            flex-shrink: 0;
            position: sticky;
            left: 0;
            z-index: 10;
        }

        .editor-content {
            flex: 1;
            position: relative;
            min-height: 100%;
            padding: 10px;
            padding-left: 12px;
            box-sizing: border-box;
            white-space: pre;
            line-height: var(--baseline);
            font-family: inherit;
            font-size: inherit;
            tab-size: 4;
            -moz-tab-size: 4;
            caret-color: var(--accent);
            outline: none;
            overflow-wrap: normal;
            word-break: normal;
            overflow: auto;
        }

        .editor-content:focus {
            outline: none;
        }

        footer {
            grid-row: 4;
            grid-column: 1 / -1;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 6px 12px;
            background: var(--header-bg);
            border-top: 1px solid #22241e;
            position: sticky;
            bottom: 0;
        }

        #prompt-input {
            flex: 1;
            margin-right: 8px;
            padding: 8px;
            background: var(--status-bg);
            border: 1px solid var(--accent);
            color: #f0f0e0;
            font-family: inherit;
            border-radius: 3px;
            font-size: 16px;
        }

        .small {
            font-size: 12px;
            padding: 6px 8px;
        }

        .agent-card {
            background: var(--panel);
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 8px;
            border-left: 4px solid var(--muted-text);
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .agent-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.1), transparent);
            transition: left 0.5s ease;
        }

        .agent-card.active::before {
            left: 100%;
        }

        .agent-card.active {
            box-shadow: 0 0 20px var(--quantum-glow);
            transform: translateY(-2px);
        }

        .agent-card.nexus { border-left-color: var(--agent-nexus); }
        .agent-card.cognito { border-left-color: var(--agent-cognito); }
        .agent-card.relay { border-left-color: var(--agent-relay); }
        .agent-card.sentinel { border-left-color: var(--agent-sentinel); }
        .agent-card.echo { border-left-color: var(--agent-echo); }

        .agent-title {
            font-weight: bold;
            font-size: 14px;
            margin-bottom: 4px;
        }

        .agent-nexus .agent-title { color: var(--agent-nexus); }
        .agent-cognito .agent-title { color: var(--agent-cognito); }
        .agent-relay .agent-title { color: var(--agent-relay); }
        .agent-sentinel .agent-title { color: var(--agent-sentinel); }
        .agent-echo .agent-title { color: var(--agent-echo); }

        .agent-subtitle {
            font-size: 11px;
            color: var(--muted-text);
            margin-bottom: 6px;
        }

        .agent-content {
            font-size: 12px;
            line-height: 1.4;
            min-height: 20px;
        }

        .quantum-spinner {
            width: 16px;
            height: 16px;
            display: inline-block;
            margin-right: 6px;
            position: relative;
        }

        .quantum-spinner::before {
            content: '';
            position: absolute;
            width: 100%;
            height: 100%;
            border: 2px solid transparent;
            border-top: 2px solid var(--agent-cognito);
            border-radius: 50%;
            animation: quantumSpin 1s linear infinite;
        }

        .quantum-spinner::after {
            content: '';
            position: absolute;
            width: 100%;
            height: 100%;
            border: 2px solid transparent;
            border-bottom: 2px solid var(--agent-nexus);
            border-radius: 50%;
            animation: quantumSpin 0.5s linear infinite;
        }

        @keyframes quantumSpin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .quantum-packet {
            position: fixed;
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: var(--agent-nexus);
            box-shadow: 0 0 10px var(--agent-nexus);
            opacity: 0;
            z-index: 100;
            pointer-events: none;
        }

        .quantum-trail {
            position: absolute;
            width: 100%;
            height: 2px;
            background: linear-gradient(90deg, transparent, var(--agent-nexus), transparent);
            opacity: 0;
        }

        .action-buttons {
            display: flex;
            gap: 8px;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid var(--muted-text);
        }

        .action-buttons button {
            flex: 1;
            padding: 6px;
            font-size: 11px;
        }

        .quantum-status {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 11px;
            margin-top: 5px;
        }

        .quantum-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--muted-text);
            position: relative;
        }

        .quantum-dot::before {
            content: '';
            position: absolute;
            top: -2px;
            left: -2px;
            right: -2px;
            bottom: -2px;
            border-radius: 50%;
            border: 1px solid var(--agent-nexus);
            animation: quantumPulseDot 2s infinite;
        }

        .quantum-dot.connected {
            background: var(--accent);
        }

        @keyframes quantumPulseDot {
            0%, 100% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.3); opacity: 0.7; }
        }

        /* ========== SYNTAX HIGHLIGHTING STYLES ========== */
        .sh-token { transition: opacity 0.08s ease; pointer-events: none; }
        .sh-comment { color: #64748b; font-style: italic; opacity: 0.8; }
        .sh-string { color: #a3e635; font-weight: 500; }
        .sh-number { color: #f59e0b; font-weight: 600; }
        .sh-keyword { color: #f472b6; font-weight: 600; }
        .sh-type { color: #7dd3fc; font-weight: 500; }
        .sh-bracket { color: #c084fc; font-weight: 700; }
        .sh-id { color: #94a3b8; }
        .sh-op { color: #94a3b8; font-weight: 500; }
        .sh-ws { opacity: 0.3; }
        .sh-key { color: #7dd3fc; font-weight: 500; }
        .sh-number2 { color: #f59e0b; font-weight: 600; }
        .sh-text { color: #e2e8f0; }
        .sh-unknown { color: #f87171; }
        .sh-tag { color: #f472b6; font-weight: 600; }
        .sh-property { color: #7dd3fc; font-weight: 500; }
        .sh-function { color: #4ac94a; font-weight: 500; }
        .sh-operator { color: #93c5fd; font-weight: 600; }
        .sh-regex { color: #fbbf24; }
        .sh-html-entity { color: #f59e0b; }
        .sh-css-selector { color: #c084fc; }
        .sh-css-property { color: #60a5fa; }
        .sh-css-value { color: #34d399; }
        .sh-jsx-tag { color: #f472b6; }
        .sh-jsx-attribute { color: #7dd3fc; }
        .sh-template-string { color: #a3e635; font-weight: 500; }

        .editor-content::selection {
            background: rgba(74, 201, 74, 0.3);
        }

        .editor-container::-webkit-scrollbar {
            width: 12px;
        }

        .editor-container::-webkit-scrollbar-track {
            background: var(--panel);
        }

        .editor-container::-webkit-scrollbar-thumb {
            background: var(--muted-text);
            border-radius: 6px;
        }

        .editor-container::-webkit-scrollbar-thumb:hover {
            background: var(--accent);
        }

        #preview-panel {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 80%;
            height: 80%;
            background: white;
            border: 2px solid var(--accent);
            border-radius: 5px;
            z-index: 1000;
            display: none;
            flex-direction: column;
            box-shadow: 0 0 30px rgba(0,0,0,.7);
        }

        #preview-header {
            background: var(--header-bg);
            color: #f0f0e0;
            padding: 8px 12px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--accent);
        }

        #preview-content {
            width: 100%;
            height: calc(100% - 40px);
            border: none;
            background: white;
        }

        #close-preview {
            background: transparent;
            border: none;
            color: #f0f0e0;
            font-size: 18px;
            cursor: pointer;
            padding: 0;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        #ai-response-panel {
            position: fixed;
            bottom: 60px;
            right: 20px;
            width: 500px;
            max-height: 600px;
            background: var(--panel);
            border: 1px solid var(--accent);
            border-radius: 5px;
            padding: 15px;
            overflow-y: auto;
            z-index: 100;
            display: none;
            box-shadow: 0 4px 12px rgba(0,0,0,.3);
        }

        #ai-response-content {
            font-size: 12px;
            line-height: 1.4;
        }

        #close-ai-panel {
            position: absolute;
            top: 5px;
            right: 5px;
            background: transparent;
            border: none;
            color: var(--muted-text);
            font-size: 14px;
            cursor: pointer;
        }

        #file-input {
            display: none;
        }

        .ai-status {
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .ai-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--accent);
            animation: none;
        }

        .ai-dot.probing {
            background: var(--err);
            animation: pulse 2s infinite;
        }

        .ai-dot.connected {
            background: var(--accent);
            animation: none;
        }

        .quantum-thinking {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            z-index: 5;
        }

        .fractal-node {
            position: absolute;
            width: 4px;
            height: 4px;
            border-radius: 50%;
            background: var(--agent-cognito);
            animation: fractalPulse 1.5s infinite alternate;
        }

        @keyframes fractalPulse {
            0% { transform: scale(1); opacity: 0.3; }
            100% { transform: scale(1.5); opacity: 0.8; }
        }

        @media (max-width: 768px) {
            #editor-stage {
                grid-template-columns: 1fr !important;
            }

            #left-panel {
                position: absolute;
                height: 100%;
                z-index: 30;
                transform: translateX(-240px);
            }

            #left-panel.open {
                transform: translateX(0);
            }

            #ai-response-panel {
                width: calc(100% - 40px);
                right: 20px;
                left: 20px;
            }

            #preview-panel {
                width: 95%;
                height: 85%;
            }

            body {
                grid-template-rows: var(--header-h) var(--status-h) 1fr auto;
            }

            footer {
                position: relative;
            }
        }

        .consensus-panel {
            background: var(--panel);
            border: 1px solid var(--agent-nexus);
            border-radius: 8px;
            padding: 15px;
            margin-top: 15px;
            max-height: 300px;
            overflow-y: auto;
        }

        .consensus-header {
            font-weight: bold;
            color: var(--agent-nexus);
            margin-bottom: 10px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .candidate-item {
            background: rgba(255,255,255,0.05);
            border-radius: 4px;
            padding: 8px;
            margin-bottom: 8px;
            border-left: 3px solid var(--agent-cognito);
        }

        .candidate-meta {
            font-size: 10px;
            color: var(--muted-text);
            display: flex;
            justify-content: space-between;
            margin-bottom: 4px;
        }

        .candidate-content {
            font-size: 11px;
            font-family: 'Fira Code', monospace;
            white-space: pre-wrap;
            max-height: 80px;
            overflow: hidden;
        }

        .entropy-badge {
            background: var(--agent-nexus);
            color: white;
            padding: 2px 6px;
            border-radius: 10px;
            font-size: 10px;
        }

        .selected-candidate {
            border-left-color: var(--accent);
            background: rgba(74, 201, 74, 0.1);
        }

        .orchestration-log {
            background: rgba(0,0,0,0.3);
            border-radius: 4px;
            padding: 8px;
            margin-top: 10px;
            max-height: 120px;
            overflow-y: auto;
            font-size: 10px;
            font-family: 'Fira Code', monospace;
        }

        .orchestration-log .log-entry {
            margin-bottom: 4px;
            padding-left: 10px;
            border-left: 2px solid var(--agent-nexus);
        }

        .orchestration-log .log-entry.genesis {
            border-left-color: var(--agent-nexus);
            color: var(--agent-nexus);
        }

        .orchestration-log .log-entry.origin {
            border-left-color: var(--agent-cognito);
            color: var(--agent-cognito);
        }

        .orchestration-log .log-entry.event {
            border-left-color: var(--agent-relay);
            color: var(--agent-relay);
        }

        .orchestration-log .log-entry.fragment {
            border-left-color: var(--agent-sentinel);
            color: var(--agent-sentinel);
        }

        .orchestration-log .log-entry.consensus {
            border-left-color: var(--agent-echo);
            color: var(--agent-echo);
        }
        
        .orchestration-log .log-entry.verification { border-left-color: var(--agent-nexus); color: var(--agent-nexus); }
        .orchestration-log .log-entry.analysis { border-left-color: var(--agent-sentinel); color: var(--agent-sentinel); }
        .orchestration-log .log-entry.alignment { border-left-color: var(--agent-relay); color: var(--agent-relay); }
        .orchestration-log .log-entry.validation { border-left-color: var(--agent-echo); color: var(--agent-echo); }
        .orchestration-log .log-entry.optimization { border-left-color: var(--agent-sentinel); color: var(--agent-sentinel); }
        .orchestration-log .log-entry.security { border-left-color: var(--agent-sentinel); color: var(--agent-sentinel); }
        .orchestration-log .log-entry.documentation { border-left-color: var(--agent-echo); color: var(--agent-echo); }
        .orchestration-log .log-entry.ux { border-left-color: var(--agent-relay); color: var(--agent-relay); }
        .orchestration-log .log-entry.archive { border-left-color: var(--agent-nexus); color: var(--agent-nexus); }


        .memory-status {
            font-size: 10px;
            color: var(--muted-text);
            padding: 2px 6px;
            border-radius: 3px;
            background: rgba(0,0,0,0.3);
        }

        .memory-status.low {
            color: #f87171;
            background: rgba(248, 113, 113, 0.1);
        }

        .memory-status.warning {
            color: #f59e0b;
            background: rgba(245, 158, 11, 0.1);
        }

        .memory-status.good {
            color: #4ac94a;
        }

        .suggestion-item {
            padding: 8px;
            border-bottom: 1px solid var(--muted-text);
            cursor: pointer;
            transition: background 0.2s;
        }

        .suggestion-item:hover {
            background: rgba(255,255,255,0.1);
        }

        .suggestion-item:last-child {
            border-bottom: none;
        }

        #suggestions-panel {
            position: absolute;
            background: var(--panel);
            border: 1px solid var(--accent);
            border-radius: 4px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 1000;
            display: none;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        }
    </style>
</head>
<body>
<header>
    <div class="left">
        <button id="left-toggle" class="small">☰</button>
        <div style="font-weight:800;" class="quantum-pulse">Nemodian 2244-1 :: Quantum Fractal AI</div>
    </div>
    <div class="right">
        <div class="ai-status">
            <div id="ai-dot" class="ai-dot connected"></div>
            <div id="ai-indicator" style="font-size:12px;color:#cfcfbd;">Quantum AI: Ready</div>
        </div>
        <button id="open-file" class="small">Open</button>
        <button id="save-file" class="small">Save</button>
        <button id="save-as" class="small">Save As</button>
        <button id="render-html" class="small warn">Render HTML</button>
        <button id="run-local-ai" class="small info">Quantum AI</button>
        <button id="run-orchestrator" class="small success">Orchestrator</button>
    </div>
</header>
<div id="status-bar" class="info">
    <div class="quantum-threads" id="quantum-threads"></div>
    <div id="file-meta">No File Loaded</div>
    <div id="editor-meta">Cursor: 0:0 | Lines: 0 | Chars: 0 | History: 0</div>
    <div id="memory-status" class="memory-status good">RAM: OK</div>
</div>
<div id="editor-stage">
    <aside id="left-panel" class="closed">
        <button id="btn-undo" class="small">UNDO</button>
        <button id="btn-redo" class="small">REDO</button>
        <button id="btn-beautify" class="small">Beautify</button>
        <button id="btn-render" class="small warn">Render HTML</button>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Quantum AI Commands:</strong></p>
            <ul style="padding-left: 15px;">
                <li>Rewrite this function</li>
                <li>Optimize performance</li>
                <li>Add error handling</li>
                <li>Convert to TypeScript</li>
                <li>Explain this code</li>
            </ul>
        </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Quantum Actions:</strong></p>
            <button id="btn-optimize" class="small" style="width:100%;margin-bottom:5px;">Quantum Optimize</button>
            <button id="btn-document" class="small" style="width:100%;margin-bottom:5px;">Fractal Document</button>
            <button id="btn-refactor" class="small" style="width:100%;">Hyper Refactor</button>
            <button id="btn-orchestrate" class="small success" style="width:100%;margin-top:5px;">Multi-Agent Consensus</button>
        </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Memory Management:</strong></p>
            <button id="btn-clear-cache" class="small" style="width:100%;margin-bottom:5px;">Clear Cache</button>
            <button id="btn-optimize-memory" class="small info" style="width:100%;margin-bottom:5px;">Optimize Memory</button>
            <button id="btn-export-session" class="small" style="width:100%;">Export Session</button>
        </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Quantum Settings:</strong></p>
            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                <input type="checkbox" id="quantum-mode" checked>
                <label for="quantum-mode">Quantum Fractal Mode</label>
            </div>
            <div style="display: flex; align-items: center; gap: 8px;">
                <input type="checkbox" id="hyperthreading" checked>
                <label for="hyperthreading">Hyperthreading</label>
            </div>
            <div style="display: flex; align-items: center; gap: 8px; margin-top: 5px;">
                <input type="checkbox" id="multi-agent-mode" checked>
                <label for="multi-agent-mode">Multi-Agent Consensus</label>
            </div>
            <div style="display: flex; align-items: center; gap: 8px; margin-top: 5px;">
                <input type="checkbox" id="auto-save" checked>
                <label for="auto-save">Auto Save</label>
            </div>
        </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Orchestrator Settings:</strong></p>
            <div style="margin-bottom: 5px;">
                <label for="agent-count">Agent Count:</label>
                <input type="number" id="agent-count" min="2" max="8" value="5" style="width: 60px; background: var(--status-bg); color: white; border: 1px solid var(--muted-text); padding: 2px; border-radius: 3px;">
            </div>
            <div style="margin-bottom: 5px;">
                <label for="max-rounds">Max Rounds:</label>
                <input type="number" id="max-rounds" min="1" max="10" value="3" style="width: 60px; background: var(--status-bg); color: white; border: 1px solid var(--muted-text); padding: 2px; border-radius: 3px;">
            </div>
            <div style="margin-bottom: 5px;">
                <label for="reasoning-depth">Reasoning Depth:</label>
                <input type="number" id="reasoning-depth" min="1" max="5" value="3" style="width: 60px; background: var(--status-bg); color: white; border: 1px solid var(--muted-text); padding: 2px; border-radius: 3px;">
            </div>
        </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Recent Files:</strong></p>
            <div id="recent-files" style="max-height: 100px; overflow-y: auto;">
                <!-- Recent files will be populated here -->
            </div>
        </div>
    </aside>

    <!-- Quantum Editor Container -->
    <div class="editor-container">
        <div class="quantum-thinking" id="quantum-thinking"></div>
        <div class="line-numbers" id="line-numbers"></div>
        <div
            class="editor-content"
            id="editor"
            contenteditable="true"
            spellcheck="false"
            data-gramm="false"
            data-gramm_editor="false"
            data-enable-grammarly="false"
        >// Quantum Fractal AI Editor - Ready
// Start coding or use the prompt below for AI assistance

function welcome() {
    return "Welcome to the Quantum Fractal AI Editor!";
}</div>
    </div>
</div>
<footer>
    <input id="prompt-input" placeholder="Enter quantum command (e.g., 'create a function to sort arrays')">
    <button id="send-button" class="success">QUANTUM PROCESS</button>
</footer>

<!-- Hidden elements -->
<input type="file" id="file-input" accept=".js,.html,.css,.txt,.json,.ts,.jsx,.tsx,.py,.php,.sql,.md,.xml,.yaml,.yml">
<div id="suggestions-panel"></div>

<!-- Panels -->
<div id="preview-panel">
    <div id="preview-header">
        <span>Quantum Preview</span>
        <button id="close-preview">×</button>
    </div>
    <iframe id="preview-content"></iframe>
</div>

<div id="ai-response-panel">
    <button id="close-ai-panel">×</button>
    <div id="ai-response-content">
        <div class="agent-card nexus agent-nexus">
            <div class="agent-title">Nexus</div>
            <div class="agent-subtitle">Quantum Orchestrator (Fractal Core)</div>
            <div class="agent-content">Idle. Awaiting quantum command.</div>
            <div class="orchestration-log" id="nexus-log"></div>
            <div class="quantum-status">
                <div class="quantum-dot connected"></div>
                <span>Quantum State: Entangled</span>
            </div>
        </div>
        <div class="agent-card cognito agent-cognito">
            <div class="agent-title">Cognito</div>
            <div class="agent-subtitle">Fractal Analyzer (Quantum Loop)</div>
            <div class="agent-content">Ready</div>
            <div class="orchestration-log" id="cognito-log"></div>
        </div>
        <div class="agent-card relay agent-relay">
            <div class="agent-title">Relay</div>
            <div class="agent-subtitle">Quantum Communicator (Wave)</div>
            <div class="agent-content">Ready</div>
            <div class="orchestration-log" id="relay-log"></div>
        </div>
        <div class="agent-card sentinel agent-sentinel">
            <div class="agent-title">Sentinel</div>
            <div class="agent-subtitle">Quantum Monitor (Fractal Coin)</div>
            <div class="agent-content">Ready</div>
            <div class="orchestration-log" id="sentinel-log"></div>
        </div>
        <div class="agent-card echo agent-echo">
            <div class="agent-title">Echo</div>
            <div class="agent-subtitle">Quantum Reporter (Fractal Code)</div>
            <div class="agent-content">Awaiting quantum report...</div>
            <div class="orchestration-log" id="echo-log"></div>
        </div>
        <div class="consensus-panel" id="consensus-panel" style="display: none;">
            <div class="consensus-header">
                <span>Multi-Agent Consensus Results</span>
                <span class="entropy-badge" id="consensus-score">Score: 0</span>
            </div>
            <div id="candidates-list"></div>
        </div>
    </div>
</div>

<!-- GSAP for animations -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.9.1/gsap.min.js"></script>

<script>
    /* =========================================================================
       QUANTUM FRACTAL AI EDITOR - FULL FUNCTIONALITY
       ========================================================================== */

    // Global state
    window.quantumState = {
        isGenerating: true,
        isSpeaking: true,
        currentSession: null,
        recentFiles: [],
        settings: {
            quantumMode: true,
            hyperthreading: true,
            multiAgentMode: true,
            autoSave: true,
            agentCount: 5,
            maxRounds: 1,
            reasoningDepth: 2
        }
    };

    /* =========================================================================
       MEMORY MANAGER - Enhanced with Full Features
       ========================================================================== */

    class QuantumMemoryManager {
        constructor() {
            this.storageKey = 'quantum_editor_cache';
            this.settingsKey = 'quantum_editor_settings';
            this.recentFilesKey = 'quantum_recent_files';
            this.maxMemoryThreshold = 50 * 1024 * 1024;
            this.cacheLimit = 40960;
            this.memoryStatus = document.getElementById('memory-status');
            this.cleanupInterval = null;
            
            this.init();
        }

        init() {
            this.loadSettings();
            this.loadRecentFiles();
            this.startMemoryMonitoring();
            this.cleanupOldCache();
        }

        startMemoryMonitoring() {
            this.cleanupInterval = setInterval(() => {
                this.checkMemoryUsage();
            }, 3200);

            window.addEventListener('beforeunload', () => this.cleanup());
        }

        async checkMemoryUsage() {
            try {
                if ('memory' in performance) {
                    const memory = performance.memory;
                    const used = memory.usedJSHeapSize;
                    const limit = memory.jsHeapSizeLimit;
                    
                    const usagePercent = (used / limit) * 100;
                    
                    if (usagePercent > 80) {
                        this.memoryStatus.textContent = 'RAM: CRITICAL';
                        this.memoryStatus.className = 'memory-status low';
                        this.emergencyCleanup();
                    } else if (usagePercent > 60) {
                        this.memoryStatus.textContent = 'RAM: WARNING';
                        this.memoryStatus.className = 'memory-status warning';
                        this.aggressiveCleanup();
                    } else {
                        this.memoryStatus.textContent = 'RAM: OK';
                        this.memoryStatus.className = 'memory-status good';
                    }
                }
            } catch (error) {
                console.warn('Memory monitoring unavailable:', error);
            }
        }

        // Settings management
        loadSettings() {
            try {
                const stored = localStorage.getItem(this.settingsKey);
                if (stored) {
                    const settings = JSON.parse(stored);
                    window.quantumState.settings = { ...window.quantumState.settings, ...settings };
                    this.applySettings();
                }
            } catch (error) {
                console.warn('Settings load failed:', error);
            }
        }

        saveSettings() {
            try {
                localStorage.setItem(this.settingsKey, JSON.stringify(window.quantumState.settings));
            } catch (error) {
                console.warn('Settings save failed:', error);
            }
        }

        applySettings() {
            const settings = window.quantumState.settings;
            document.getElementById('quantum-mode').checked = settings.quantumMode;
            document.getElementById('hyperthreading').checked = settings.hyperthreading;
            document.getElementById('multi-agent-mode').checked = settings.multiAgentMode;
            document.getElementById('auto-save').checked = settings.autoSave;
            document.getElementById('agent-count').value = settings.agentCount;
            document.getElementById('max-rounds').value = settings.maxRounds;
            document.getElementById('reasoning-depth').value = settings.reasoningDepth;
        }

        // Recent files management
        loadRecentFiles() {
            try {
                const stored = localStorage.getItem(this.recentFilesKey);
                if (stored) {
                    window.quantumState.recentFiles = JSON.parse(stored);
                    this.updateRecentFilesUI();
                }
            } catch (error) {
                console.warn('Recent files load failed:', error);
            }
        }

        saveRecentFiles() {
            try {
                localStorage.setItem(this.recentFilesKey, JSON.stringify(window.quantumState.recentFiles));
            } catch (error) {
                console.warn('Recent files save failed:', error);
            }
        }

        addRecentFile(filename, content) {
            // Remove if already exists
            window.quantumState.recentFiles = window.quantumState.recentFiles.filter(f => f.filename !== filename);
            
            // Add to beginning
            window.quantumState.recentFiles.unshift({
                filename,
                content: content.substring(0, 1000), // Store only preview
                timestamp: Date.now()
            });

            // Keep only last 10 files
            window.quantumState.recentFiles = window.quantumState.recentFiles.slice(0, 10);
            
            this.saveRecentFiles();
            this.updateRecentFilesUI();
        }

        updateRecentFilesUI() {
            const container = document.getElementById('recent-files');
            container.innerHTML = '';

            window.quantumState.recentFiles.forEach(file => {
                const item = document.createElement('div');
                item.className = 'suggestion-item';
                item.innerHTML = `
                    <div style="font-weight: bold;">${file.filename}</div>
                    <div style="font-size: 9px; color: var(--muted-text);">${new Date(file.timestamp).toLocaleDateString()}</div>
                `;
                item.addEventListener('click', () => {
                    quantumEditor.setContent(file.content, quantumEditor.highlighter.detectLanguage(file.filename));
                    document.getElementById('file-meta').textContent = file.filename;
                    quantumEditor.currentFileName = file.filename;
                });
                container.appendChild(item);
            });

            if (window.quantumState.recentFiles.length === 0) {
                container.innerHTML = '<div style="padding: 8px; color: var(--muted-text); font-size: 10px;">No recent files</div>';
            }
        }

        async store(key, data, priority = 'medium') {
            try {
                const cache = this.getCache();
                const dataSize = new Blob([JSON.stringify(data)]).size;
                if (dataSize > this.maxMemoryThreshold) {
                    throw new Error('Data too large for storage');
                }

                cache[key] = {
                    data: data,
                    timestamp: Date.now(),
                    priority: priority,
                    size: dataSize
                };

                if (Object.keys(cache).length > this.cacheLimit) {
                    this.cleanupCache();
                }

                await this.saveCache(cache);
                return true;
            } catch (error) {
                console.warn('Storage failed, falling back to memory:', error);
                if (!window.quantumMemoryCache) {
                    window.quantumMemoryCache = new Map();
                }
                window.quantumMemoryCache.set(key, data);
                return false;
            }
        }

        async retrieve(key) {
            try {
                const cache = this.getCache();
                if (cache[key]) {
                    return cache[key].data;
                }
                
                if (window.quantumMemoryCache && window.quantumMemoryCache.has(key)) {
                    return window.quantumMemoryCache.get(key);
                }
                
                return null;
            } catch (error) {
                console.warn('Retrieval failed:', error);
                return null;
            }
        }

        cleanupCache() {
            try {
                const cache = this.getCache();
                const entries = Object.entries(cache);
                
                if (entries.length > this.cacheLimit) {
                    entries.sort((a, b) => a[1].timestamp - b[1].timestamp);
                    const toRemove = entries.slice(0, Math.floor(entries.length * 0.3));
                    toRemove.forEach(([key]) => delete cache[key]);
                    this.saveCache(cache);
                }
            } catch (error) {
                console.warn('Cache cleanup failed:', error);
            }
        }

        emergencyCleanup() {
            try {
                localStorage.removeItem(this.storageKey);
                sessionStorage.clear();
                
                if (window.quantumMemoryCache) {
                    window.quantumMemoryCache.clear();
                }
                
                if (window.gc) window.gc();
                this.clearLargeArrays();
                console.log('Emergency memory cleanup completed');
            } catch (error) {
                console.error('Emergency cleanup failed:', error);
            }
        }

        aggressiveCleanup() {
            try {
                const cache = this.getCache();
                const entries = Object.entries(cache);
                const toKeep = entries.filter(([key, entry]) => 
                    entry.priority === 'high' && entry.size < 1021024
                );
                this.saveCache(Object.fromEntries(toKeep));
                
                if (window.quantumMemoryCache) {
                    const keys = Array.from(window.quantumMemoryCache.keys());
                    keys.slice(0, Math.floor(keys.length * 0.5)).forEach(key => 
                        window.quantumMemoryCache.delete(key)
                    );
                }
                console.log('Aggressive memory cleanup completed');
            } catch (error) {
                console.warn('Aggressive cleanup failed:', error);
            }
        }

        clearLargeArrays() {
            if (window.largeArrays) {
                window.largeArrays.clear();
            }
        }

        cleanupOldCache() {
            const cache = this.getCache();
            const now = Date.now();
            const oneHour = 60 * 60 * 1000;
            
            Object.keys(cache).forEach(key => {
                if (now - cache[key].timestamp > oneHour) {
                    delete cache[key];
                }
            });
            this.saveCache(cache);
        }

        getCache() {
            try {
                const stored = localStorage.getItem(this.storageKey);
                return stored ? JSON.parse(stored) : {};
            } catch (error) {
                console.warn('Cache retrieval failed:', error);
                return {};
            }
        }

        async saveCache(cache) {
         try {
                localStorage.setItem(this.storageKey, JSON.stringify(cache));
            } catch (error) {
                console.warn('Cache save failed:', error);
            }
        }

        cleanup() {
            if (this.cleanupInterval) {
                clearInterval(this.cleanupInterval);
            }
        }

        async exportSession() {
            try {
                const sessionData = {
                    timestamp: Date.now(),
                    cache: is.getCache(),
                    memoryCache: window.quantumMemoryCache ? 
                        Array.from(window.quantumMemoryCache.entries()) : [],
                    recentFiles: window.quantumState.recentFiles,
                    settings: window.quantumState.settings
                };
                
                const blob = new Blob([JSON.stringify(sessionData, null, 2)], 
                    { type: 'application/json' });
                const url = URL.createObjectURL(blob);
           const a = document.createElement('a');
                a.href = url;
                a.download = `quantum_session_${Date.now()}.json`;
                a.click();
                URL.revokeObjectURL(url);
                return true;
            } catch (error) {
                console.error('Session export failed:', error);
                return false;
            }
        }

        async clearAllCache() {
            try {
                localStorage.removeItem(this.storageKey                localStorage.removeItem(this.settingsKey);
                localStorage.removeItem(this.recentFilesKey);
                if (window.quantumMemoryCache) {
                    window.quantumMemoryCache.clear();
                }
                sessionStorage.clear();
                return true;
            } catch (error) {
                console.error('Cache clearance failed:', error);
                return false;
            }
        }
    }
	
### USE THIS FOR THE REAL SCIPT LOGIC:	

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nemodian 2244-1 :: Quantum Fractal AI Editor</title>
    <style>
        :root {
            --muted: #888;
            --info: #2196F3;
            --warn: #FF9800;
            --error: #F44336;
            --success: #4CAF50;
            --baseline: 1.5em;
            --header-h: calc(var(--baseline) * 1.6);
        tatus-h: var(--baseline);
            --footer-h: calc(var(--baseline) * 2);
            --font-size: 13px;
            --ln-width: 50px;
            --theme-bg: #3a3c31;
            --panel: #313328;
            --header-bg: #2e3026;
            --status-bg: #22241e;
            --accent: #4ac94a;
            --muted-text: #999966;
            --err: #a03333;
            --warn-bg: #f0ad4e;
            --hover-blue: #3366a0;
            --info-bg: #5bc0de;
            --agent-nexus: #BB86FC;
            --agent-cognito: #03DAC6;
            --agent-relay: #FFD54F;
            --agent-sentinel: #CF6679;
            --agent-echo: #4ac94a;
            --quantum-glow: rgba(187, 134, 252, 0.6);
        /* =========================================================================
       ENHANCED QUANTUM SYNTAX HIGHLIGHTER
       ========================================================================== */

    class QuantumSyntaxHighlighter {
        constructor() {
            this.languaPatterns = {
                javascript: this.getJavaScriptPatterns(),
                typescript: this.getTypeScriptPatterns(),
                html: this.getHTMLPatterns(),
                css: this.getCSSPatterns(),
                python: this.getPythonPatterns(),
                php: this.getPHPPatterns(),
                sql: this.getSQLPatterns(),
                markdown: this.getMarkdownPatterns(),
                json: this.getJSONPatterns(),
                jsx: this.getJSXPatterns(),
                tsx: this.getTSXPatterns(),
                xml: this.getXMLPatterns(),
                yaml: this.getYAMLPatterns()
            /* =========================================================================
       ENHANCED QUANTUM EDITOR WITH COMPLETE FEATURES
       ========================================================================== */

    class QuantumEditor {
        constructor() {
            this.editor = document.getElementById('editor');
            this.lineNumbers = document.getElementById('line-numbers');
            this.statusEditor = document.getElementById('editor-meta');
            this.statusFile = document.getElementById('file-meta');
            this.memoryManager = new QuantumMemoryManager();
            this.highlighter = new QuantumSyntaxHighlighter();
            this.quantumThinking = document.getElementById('quantum-thinking');

            this.currentFileName = null;
            this.currentFileType = 'javascript';
            this.historyS [];
            this.redoStack = [];
            this.isComposing = false;
            this.quantumMode = true;
            this.hyperthreading = true;
            this.multiAgentMode = true;

            this.maxHistorySize = 50;
            this.debounceDelay = 100;
            this.chunkSize = 1000;
            this.autoSaveInterval = null;

            this.init();
        }

        init() {
            this.bindEvents();
            this.loadAutosave();
            this.pushHistory(;
            this.initQuantumVisuals();
            this.enableRealtimeHighlighting();
            this.startAutoSave();
        }

        startAutoSave() {
            if (window.quantumState.settings.autoSave) {
                this.autoSaveInterval = setInterval(() => {
                    this.saveAutosave();
                }, 30000);
            }
        }

        stopAutoSave() {
            if (this.autoSaveInterval) {
                clearInterval(this.autoSaveInterval);
           }
        }

        async loadAutosave() {
            try {
                const autosave = await this.memoryManager.retrieve('autosave_content');
                if (autosave && !this.editor.textContent.trim()) {
                    this.render(autosave);
                    quantumNotify('Autosave restored', 'success');
                }
            } catch (error) {
                console.warn('Autosave load failed:', error);
            }
        }

        async saveAutosave() {            if (!window.quantumState.settings.autoSave) return;
            
            try {
                const content = this.editor.textContent;
                if (content.trim()) {
                    await this.memoryManager.store('autosave_content', content, 'high');
                }
            } catch (error) {
                console.warn('Autosave failed:', error);
            }
        }

        bindEvents() {
            let inputTimeout;
            this.editor.addEventListener('input', () => {
                clearTimeout(inputTimeout);
                inputTimeout = setTimeout(() => {
                    this.handleInput();
                }, this.debounceDelay);
            });

            this.editor.addEventListener('compositionstart', () => this.isComposing = true);
            this.editor.addEventListener('compositionend', () => {
                this.isComposing = false;
                this.handleInput();
            });

            this.editor.addEventListener('keydown', this.handleKeydown.bind(this));
            this.editor.addEventListener('click', this.updateStatus.bind(this));
            this.editor.addEventListener('keyup', this.updateStatus.bind(this));
            this.editor.addEventListener('scroll', this.syncScroll.bind(this));

            window.addEventListener('beforeunload', () => this.saveAutosave());
            document.addEventListener('visibilitychange', () => {
                if (document.hidden) {
                    this.saveAutosave();
                }
            });

            // Settings bindings
            document.getElementById('quantum-mode').addEventListener('change', (e) => {
                window.quantumState.settings.quantumMode = e.target.checked;
                this.quantumMode = e.target.checked;
                this.memoryManager.saveSettings();
                if (this.quantumMode) {
                    this.createFractalNodes();
                } else {
                    this.quantumThinking.innerHTML = '';
                }
            });

            document.getElementById('hyperthreading').addEventListener('change', (e) => {
                window.quantumState.settings.hyperthreading = e.target.checked;
                this.hyperthreading = e.target.checked;
                this.memoryManager.saveSettings();
                if (this.quantumMode) {
                    this.createFractalNodes();
                }
            });

            document.getElementById('multi-agent-mode').addEventListener('change', (e) => {
                window.quantumState.settings.multiAgentMode = e.target.checked;
                this.multiAgentMode = e.target.checked;
                this.memoryManager.saveSettings();
            });

            document.getElementById('auto-save').addEventListener('change', (e) => {
                window.quantumState.settings.autoSave = e.target.checked;
                this.memoryManager.saveSettings();
                if (e.get.checked) {
                    this.startAutoSave();
                } else {
                    this.stopAutoSave();
                }
            });

            document.getElementById('agent-count').addEventListener('change', (e) => {
                window.quantumState.settings.agentCount = parseInt(e.target.value);
                this.memoryManager.saveSettings();
            });

            document.getElementById('max-rounds').addEventListener('change', (e) => {
                window.quantumState.settings.maxRounds = parseInt(e.target.value);
                this.memoryManager.saveSettings();
            });

            document.getElementById('reasoning-depth').addEventListener('change', (e) => {
                window.quantumState.settings.reasoningDepth = parseInt(e.target.value);
                this.memoryManager.saveSettings();
            });

            // Memory management buttons
            document.getElementById('btn-clear-cache').addEventListener('click', () => {
                this.memoryManager.clearAllCache().then(success => {
                    quantumNotify(success ? 'Cache cleared' : 'Cache clearance failed', 
                                success ? 'success' : 'error');
                });
            });

            document.getElementById('btn-optimize-memory').addEventListener('click', () => {
                this.memoryManager.aggressiveCleanup();
                quantumNotify('Memory optimized', 'success');
            });

        document.getElementById('btn-export-session').addEventListener('click', () => {
                this.memoryManager.exportSession().then(success => {
                    quantumNotify(success ? 'Session exported' : 'Export failed', 
                                success ? 'success' : 'error');
                });
            });

            this.setupCodeSuggestions();
        }

        setupCodeSuggestions() {
            const promptInput = document.getElementById('prompt-input');
      const suggestionsPanel = document.getElementById('suggestions-panel');

            promptInput.addEventListener('input', () => {
                const value = promptInput.value.toLowerCase();
                if (value.length < 2) {
                    suggestionsPanel.style.display = 'none';
                    return;
                }

                const suggestions = this.getSuggestions(value);
                if (suggestions.length > 0) {
                    this.showSuggestions(suggest, promptInput);
                } else {
                    suggestionsPanel.style.display = 'none';
                }
            });

            promptInput.addEventListener('blur', () => {
                setTimeout(() => {
                    suggestionsPanel.style.display = 'none';
                }, 200);
            });
        }

        getSuggestions(input) {
            const commonCommands = [
                'create a function to sort arrays',
                'optimize this co for performance',
                'add error handling to this function',
                'convert this to TypeScript',
                'explain this code',
                'refactor this code',
                'write unit tests for this function',
                'create a React component',
                'implement a database query',
                'add comments to this code',
                'fix bugs in this code',
                'improve code readability',
                'implement autheation',
                'create API endpoints',
                'optimize database queries',
                'add input validation',
                'implement caching',
                'create documentation',
                'set up logging',
                'handle edge cases'
            ];

            return commonCommands.filter(cmd => 
                cmd.toLowerCase().includes(input.toLowerCase())
            ).slice(0, 5);
        }

        showSuggestions(suggestions, inputElement)            const suggestionsPanel = document.getElementById('suggestions-panel');
            suggestionsPanel.innerHTML = '';

            suggestions.forEach(suggestion => {
                const item = document.createElement('div');
                item.className = 'suggestion-item';
                item.textContent = suggestion;
                item.addEventListener('click', () => {
                    inputElement.value = suggestion;
                    suggestionsPanel.style.display = 'none';
                    inputElement.focus();
                });
                suggestionsPanel.appendChild(item);
            });

            const rect = inputElement.getBoundingClientRect();
            suggestionsPanel.style.position = 'fixed';
            suggestionsPanel.style.bottom = (window.innerHeight - rect.top + 5) + 'px';
            suggestionsPanel.style.left = (rect.left + window.scrollX) + 'px';
            suggestionsPanel.style.width = (rect.width) + 'px';
            suggestionsPanel.style.display = 'block';
        }

        handleInput() {
            if (this.isComposing) return;

            this.pushHistory();
            this.updateLineNumbers();
            this.updateStatus();
            this.saveAutosave();

            if (this.quantumMode) {
                this.createFractalNodes();
            }
        }

        handleKeydown(event) {
            if (event.key === 'Tab') {
                event.preventDefault();
                this.insertTet('    ');
            }

            if (event.ctrlKey || event.metaKey) {
                if (event.key === 'z' && !event.shiftKey) {
                    event.preventDefault();
                    this.undo();
                } else if (event.key === 'z' && event.shiftKey) {
                    event.preventDefault();
                    this.redo();
                } else if (event.key === 'y') {
                    event.preventDefault();
                    this.redo();
                }  (event.key === 's') {
                    event.preventDefault();
                    quantumSaveFile();
                } else if (event.key === 'f') {
                    event.preventDefault();
                    this.showFindDialog();
                } else if (event.key === 'd') {
                    event.preventDefault();
                    this.duplicateLine();
                }
            } else if (event.key === 'F2') {
                event.preventDefault();
                this.rnameVariable();
            }
        }

        showFindDialog() {
            const findText = prompt('Find:');
            if (findText) {
                const content = this.editor.textContent;
                const regex = new RegExp(findText, 'gi');
                const matches = content.match(regex);
                if (matches) {
                    quantumNotify(`Found ${matches.length} matches`, 'info');
                    this.highlightMatches(findText);
                } else {
                quantumNotify('No matches found', 'warn');
                }
            }
        }

        highlightMatches(text) {
            const content = this.editor.innerHTML;
            const regex = new RegExp(`(${text})`, 'gi');
            const highlighted = content.replace(regex, '<mark>$1</mark>');
            this.editor.innerHTML = highlighted;
            
            setTimeout(() => {
                this.highlighter.highlightElement(this.editor, this.currentFileType);
           }, 3000);
        }

        duplicateLine() {
            const selection = window.getSelection();
            if (selection.rangeCount === 0) return;

            const range = selection.getRangeAt(0);
            const lineElement = range.startContainer.parentElement;
            const lineText = lineElement.textContent;
            
            const newLine = document.createTextNode('\
' + lineText);
            range.insertNode(newLine);
            
            this.handleInpu;
        }

        renameVariable() {
            const selection = window.getSelection();
            if (selection.rangeCount === 0) return;

            const range = selection.getRangeAt(0);
            const selectedText = range.toString();
            
            if (selectedText) {
                const newName = prompt('Rename variable:', selectedText);
                if (newName && newName !== selectedText) {
                    range.deleteContents();
                    range.inode(document.createTextNode(newName));
                    this.handleInput();
                }
            } else {
                quantumNotify('Select a variable to rename', 'warn');
            }
        }

        insertText(text) {
            const selection = window.getSelection();
            if (selection.rangeCount === 0) return;

            const range = selection.getRangeAt(0);
            range.deleteContents();
            range.insertNode(document.createTextNode(text));

        range.setStart(range.endContainer, range.endOffset);
            range.setEnd(range.endContainer, range.endOffset);
            selection.removeAllRanges();
            selection.addRange(range);

            this.handleInput();
        }

        enableRealtimeHighlighting() {
            this.highlighter.enableRealtimeHighlighting(this.editor, this.currentFileType);
        }

        initQuantumVisuals() {
            const threadsContainer = document.getElementById('quantum-threads')           for (let i = 0; i < 5; i++) {
                const thread = document.createElement('div');
                thread.className = 'quantum-thread';
                thread.style.left = `${20 + i * 15}%`;
                thread.style.animationDelay = `${i * 0.3}s`;
                threadsContainer.appendChild(thread);
            }
        }

        createFractalNodes() {
            if (!this.quantumMode) return;

            this.quantumThinking.innerHTML = '';
            const nodeCo= this.hyperthreading ? 12 : 6;

            for (let i = 0; i < nodeCount; i++) {
                const node = document.createElement('div');
                node.className = 'fractal-node';
                node.style.left = `${Math.random() * 100}%`;
                node.style.top = `${Math.random() * 100}%`;
                node.style.animationDelay = `${Math.random() * 2}s`;
                node.style.background = i % 2 === 0 ? 'var(--agent-nexus)' : 'var(--agent-cognito)';
                this.quantumThinking.appendChild(node);
            }
        }

        pushHistory() {
            const content = this.editor.textContent;
            if (this.historyStack.length && this.historyStack[this.historyStack.length - 1] === content) return;

            this.historyStack.push(content);
            this.redoStack = [];

            if (this.historyStack.length > this.maxHistorySize) {
                this.historyStack.shift();
            }
        }

        undo() {
            if (this.historyStack.length > 1) {
                this.redoStack.push(this.historyStack.pop());
                this.render(this.historyStack[this.historyStack.length - 1]);
            }
        }

        redo() {
            if (this.redoStack.length) {
                const content = this.redoStack.pop();
                this.historyStack.push(content);
                this.render(content);
            }
        }

        render(content) {
            try {
                if (content.length > 100000) {
                    this.renderInChunks(content);
                } else {
                    this.editor.textContent = content;
                    this.highlightContent();
                }
                
                this.updateLineNumbers();
                this.updateStatus();

                if (this.quantumMode) {
                    this.createFractalNodes();
                }
            } catch (error) {
                console.error('Render f:', error);
                this.handleMemoryError(error);
            }
        }

        renderInChunks(content) {
            const lines = content.split('\
');
            const chunkSize = this.chunkSize;
            let currentChunk = 0;

            const renderNextChunk = () => {
                const start = currentChunk * chunkSize;
                const end = start + chunkSize;
                const chunk = lines.slice(start, end).join('\
');
                
                if (currentChunk === 0) {
                    this.editor.textContent = chunk;
                } else {
                    this.editor.textContent += '\
' + chunk;
                }

                if (end < lines.length) {
                    currentChunk++;
                    setTimeout(renderNextChunk, 0);
                } else {
                    this.highlightContent();
                }
            };

            renderNextChunk();
        }

        highlightContent() {
        this.highlighter.highlightElement(this.editor, this.currentFileType);
        }

        updateLineNumbers() {
            try {
                const text = this.editor.textContent || '';
                const lines = text.split('\
');
                const lineCount = lines.length;

                let lineNumbersHTML = '';
                for (let i = 1; i <= lineCount; i++) {
                    lineNumbersHTML += i + '<br>';
                }

                this.lineNumbers.innerHTML  lineNumbersHTML;
                this.lineNumbers.style.height = this.editor.scrollHeight + 'px';
            } catch (error) {
                console.warn('Line number update failed:', error);
            }
        }

        syncScroll() {
            this.lineNumbers.scrollTop = this.editor.scrollTop;
        }

        updateStatus() {
            const selection = window.getSelection();
            const text = this.editor.textContent || '';
            const lines = text.split('\
');\          let lineNum = 1;
            let colNum = 0;

            if (selection.rangeCount > 0) {
                const range = selection.getRangeAt(0);
                const preCaretRange = range.cloneRange();
                preCaretRange.selectNodeContents(this.editor);
                preCaretRange.setEnd(range.endContainer, range.endOffset);

                const preCaretText = preCaretRange.toString();
                const preCaretLines = preCaretText.split('\
');

                lineNum = preCaretLines.length;
                colNum = preCaretLines[preCaretLines.length - 1].length;
            }

            const quantumStatus = this.quantumMode ?
                ` | Quantum: ${this.hyperthreading ? 'Hyperthreaded' : 'Standard'}` :
                ' | Classical Mode';

            const agentStatus = this.multiAgentMode ? ' | Multi-Agent' : ' | Single-Agent';

            this.statusEditor.textContent =
                `Cursor: ${lineNum}:${colNum} | Lines: ${lines.length} | Chars: ${text.length} | History: ${this.historyStack.length}${quantumStatus}${agentStatus}`;
        }

        handleMemoryError(error) {
            console.error('Memory error occurred:', error);
            document.getElementById('memory-status').textContent = 'RAM: CRITICAL';
            document.getElementById('memory-status').className = 'memory-status low';
            
            this.memoryManager.emergencyCleanup();
            this.editor.textContent = '// Memory optimization in progress...\
// Please save your work and refresh if issues persist';
            
            quantumNotify('Memory optimized for stability', 'warn');
        }

        setContent(content, fileType = 'javascript') {
            try {
                this.currentFileType = fileType;
                this.highlighter.setLanguage(fileType);
                this.render(content);
                this.historyStack = [content];
                this.redoStack = [];
            } catch (error) {
                this.handleMemoryError(error);
            }
        }

        getContent() {
            return this.editor.textContent;
        }

        insertCodeAtCursor(code) {
            const selection = window.getSelection();
            if (selection.rangeCount === 0) return;

            const range = selection.getRangeAt(0);
            range.deleteContents();

            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = code;

            const fragment = document.createDocumentFragment();
            while (tempDiv.firstChild) {
                fragment.appendChild(tempDiv.firstChild);
            }

            range.insertNode(fragment);

            range.setStartAfter(fragment.lastChild);
            range.setEndAfter(fragment.lastChild);
            selection.removeAllRanges();
            selection.addRange(range);

            this.handleInput();
        }

        replaceSelectionWithCode(code) {
            const selection = window.getSelection();
            if (selection.rangeCount === 0) return;

            const range = selection.getRangeAt(0);
            range.deleteContents();

            const textNode = document.createTextNode(code);
            range.insertNode(textNode);

            range.setStartAfter(textNode);
            range.setEndAfter(textNode);
            selection.removeAllRanges();
            selection.addRange(range);

            this.handleInput();
        }

        beautifyCode() {
            try {
                const content = this.getContent();
                let formatted = content;

                formatted = formatted.replace(/\\s+/g, ' ');
                formatted = formatted.replace(/\\s*{\\s*/g, ' { ');
                formatted = formatted.replace(/\\s*}\\s*/g, ' } ');
                formatted = formatted.replace(/\\s*\\(\\s*/g, ' ( ');
                formatted = formatted.replace(/\\s*\\)\\s*/g, ' ) ');
                formatted = formatted.replace(/;\\s+/g, ';\
');
                formatted = formatted.replace(/\
\\s*\
/g, '\
');

                this.setContent(formatted);
                quantumNotify('Code beautified', 'success');
            } catch (error) {
                quantumNotify('Beautification failed', 'error');
            }
        }
    };
            
            this.currentLanguage = 'javascript';
            this.debounceTimer = null;
            this.debounceDelay = 50;
        }

        getJavaScriptPatterns() {
            return [
                { pattern: /\\/\\/.*$/gm, type: 'comment' },
                { pattern: /\\/\\*[\\s\\S]*?\\*\\//g, type: 'comment' },
                { pattern: /`(?:\\\\.|[^`\\\\])*`/g, type: 'template-string' },
                { pattern: /'(?:\\\\.|[^'\\\\])*'/g, type: 'string' },
                { pattern: /"(?:\\\\.|[^"\\\\])*"/g, type: 'string' },
                { pattern: /\\/(?![*\\/])(?:\\\\.|[^\\/\\\\\
])+\\/[gimuy]*/g, type: 'regex' },
                { pattern: /\\b\\d+(\\.\\d+)?\\b/g, type: 'number' },
                { pattern: /\\b0x[a-fA-F0-9]+\\b/g, type: 'number' },
                { pattern: /\\b(?:function|class|const|let|var|if|else|for|while|do|switch|case|break|continue|return|try|catch|finally|throw|new|this|super|extends|implements|import|export|from|default|async|await|yield|static|public|private|protected|readonly|abstract|interface|type|namespace|module|declare|get|set|of|in|instanceof|typeof|void|delete)\\b/g, type: 'keyword' },
                { pattern: /\\b(?:console|Math|Date|Array|Object|String|Number|Boolean|Symbol|Map|Set|Promise|JSON|RegExp|Error|Function|Proxy|Reflect)\\b/g, type: 'type' },
                { pattern: /\\b[a-zA-Z_$][\\w$]*(?=\\s*\\()/g, type: 'function' },
                { pattern: /[+\\-*/%=<>!&|^~?:.,;]/g, type: 'operator' },
                { pattern: /[{}()[\\]<>]/g, type: 'bracket' }
            ];
        }

        getTypeScriptPatterns() {
            const jsPatterns = this.getJavaScriptPatterns();
            jsPatterns.push(
                { pattern: /\\b(?:interface|type|implements|namespace|module|declare|readonly|abstract|public|private|protected)\\b/g, type: 'keyword' },
                { pattern: /:\\s*\\w+/g, type: 'type' }
            );
            return jsPatterns;
        }

        getHTMLPatterns() {
            return [
                { pattern: /<!--[\\s\\S]*?-->/g, type: 'comment' },
                { pattern: /<\\/?[\\w][\\w-]*/g, type: 'tag' },
                { pattern: /(?<=<\\/?[\\w][\\w-]*\\s+)[\\w-]+(?=\\s*=)/g, type: 'property' },
                { pattern: /"(?:\\\\.|[^"\\\\])*"/g, type: 'string' },
                { pattern: /'(?:\\\\.|[^'\\\\])*'/g, type: 'string' },
                { pattern: /<!DOCTYPE\\s+[^>]+>/gi, type: 'keyword' }
            ];
        }

        getCSSPatterns() {
            return [
                { pattern: /\\/\\*[\\s\\S]*?\\*\\//g, type: 'comment' },
                { pattern: /[.#]?[\\w-]+\\s*(?={)/g, type: 'css-selector' },
                { pattern: /[\\w-]+(?=\\s*:)/g, type: 'css-property' },
                { pattern: /:\\s*[^;]+/g, type: 'css-value' },
                { pattern: /!important/gi, type: 'keyword' },
                { pattern: /@\\w+/g, type: 'keyword' }
            ];
        }

        getPythonPatterns() {
            return [
                { pattern: /#.*$/gm, type: 'comment' },
                { pattern: /\"\"\"(?:.|\
)*?\"\"\"/g, type: 'string' },
                { pattern: /'''(?:.|\
)*?'''/g, type: 'string' },
                { pattern: /"(?:\\\\.|[^"\\\\])*"/g, type: 'string' },
                { pattern: /'(?:\\\\.|[^'\\\\])*'/g, type: 'string' },
                { pattern: /\\b\\d+(\\.\\d+)?\\b/g, type: 'number' },
                { pattern: /\\b(?:def|class|if|elif|else|for|while|try|except|finally|with|import|from|as|return|yield|async|await|lambda|None|True|False|and|or|not|in|is|global|nonlocal|del|pass|break|continue|raise)\\b/g, type: 'keyword' },
                { pattern: /\\b[a-zA-Z_][\\w]*(?=\\s*\\()/g, type: 'function' },
                { pattern: /@\\w+/g, type: 'function' }
            ];
        }

        getPHPPatterns() {
            return [
                { pattern: /\\/\\/.*$/gm, type: 'comment' },
                { pattern: /#.*$/gm, type: 'comment' },
                { pattern: /\\/\\*[\\s\\S]*?\\*\\//g, type: 'comment' },
                { pattern: /<\\?php|\\?>/g, type: 'tag' },
                { pattern: /'(?:\\\\.|[^'\\\\])*'/g, type: 'string' },
                { pattern: /"(?:\\\\.|[^"\\\\])*"/g, type: 'string' },
                { pattern: /\\$\\w+/g, type: 'variable' },
                { pattern: /\\b(?:function|class|interface|trait|namespace|use|public|private|protected|static|final|abstract|const|if|else|elseif|for|foreach|while|do|switch|case|break|continue|return|try|catch|finally|throw|new|clone|instanceof|echo|print|die|exit|isset|unset|empty)\\b/g, type: 'keyword' }
            ];
        }

        getSQLPatterns() {
            return [
                { pattern: /--.*$/gm, type: 'comment' },
                { pattern: /\\/\\*[\\s\\S]*?\\*\\//g, type: 'comment' },
                { pattern: /'(?:\\\\.|[^'\\\\])*'/g, type: 'string' },
                { pattern: /"(?:\\\\.|[^"\\\\])*"/g, type: 'string' },
                { pattern: /\\b(?:SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|JOIN|INNER|LEFT|RIGHT|OUTER|ON|AND|OR|NOT|IN|BETWEEN|LIKE|IS|NULL|ORDER BY|GROUP BY|HAVING|LIMIT|OFFSET|UNION|CREATE|ALTER|DROP|TABLE|INDEX|VIEW|DATABASE|TRIGGER|PROCEDURE|FUNCTION|VALUES|SET|DEFAULT|PRIMARY KEY|FOREIGN KEY|REFERENCES|CASCADE|UNIQUE|CHECK|EXISTS|CASE|WHEN|THEN|ELSE|END|DISTINCT|COUNT|SUM|AVG|MIN|MAX)\\b/gi, type: 'keyword' },
                { pattern: /\\b\\d+(\\.\\d+)?\\b/g, type: 'number' }
            ];
        }

        getMarkdownPatterns() {
            return [
                { pattern: /^#{1,6}\\s+.+$/gm, type: 'keyword' },
                { pattern: /\\*\\*(.*?)\\*\\*/g, type: 'keyword' },
                { pattern: /\\*(.*?)\\*/g, type: 'comment' },
                { pattern: /`[^`]*`/g, type: 'string' },
                { pattern: /\\[([^\\]]+)\\]\\(([^)]+)\\)/g, type: 'function' },
                { pattern: /^\\s*[\\-\\*\\+]\\s+/gm, type: 'operator' },
                { pattern: /^\\s*\\d+\\.\\s+/gm, type: 'number' }
            ];
        }

        getJSONPatterns() {
            return [
                { pattern: /"(?:\\\\.|[^"\\\\])*"(?=\\s*:)/g, type: 'key' },
                { pattern: /"(?:\\\\.|[^"\\\\])*"/g, type: 'string' },
                { pattern: /\\b\\d+(\\.\\d+)?\\b/g, type: 'number' },
                { pattern: /\\b(?:true|false|null)\\b/g, type: 'keyword' }
            ];
        }

        getJSXPatterns() {
            const jsPatterns = this.getJavaScriptPatterns();
            jsPatterns.push(
                { pattern: /<\\/?[A-Z][\\w]*|<\\/?[a-z][\\w-]*/g, type: 'jsx-tag' },
                { pattern: /(?<=<[A-Z][\\w]*\\s+)[\\w-]+(?=\\s*=)/g, type: 'jsx-attribute' }
            );
            return jsPatterns;
        }

        getTSXPatterns() {
            const tsPatterns = this.getTypeScriptPatterns();
            tsPatterns.push(
                { pattern: /<\\/?[A-Z][\\w]*|<\\/?[a-z][\\w-]*/g, type: 'jsx-tag' },
                { pattern: /(?<=<[A-Z][\\w]*\\s+)[\\w-]+(?=\\s*=)/g, type: 'jsx-attribute' }
            );
            return tsPatterns;
        }

        getXMLPatterns() {
            return [
                { pattern: /<!--[\\s\\S]*?-->/g, type: 'comment' },
                { pattern: /<\\/?[\\w][\\w-]*/g, type: 'tag' },
                { pattern: /(?<=<\\/?[\\w][\\w-]*\\s+)[\\w-]+(?=\\s*=)/g, type: 'property' },
                { pattern: /"(?:\\\\.|[^"\\\\])*"/g, type: 'string' },
                { pattern: /'(?:\\\\.|[^'\\\\])*'/g, type: 'string' }
            ];
        }

        getYAMLPatterns() {
            return [
                { pattern: /#.*$/gm, type: 'comment' },
                { pattern: /"(?:\\\\.|[^"\\\\])*"/g, type: 'string' },
                { pattern: /'(?:\\\\.|[^'\\\\])*'/g, type: 'string' },
                { pattern: /\\b\\d+(\\.\\d+)?\\b/g, type: 'number' },
                { pattern: /^(?:\\s*)[\\w-]+(?=\\s*:)/gm, type: 'key' },
                { pattern: /\\b(?:true|false|null|yes|no|on|off)\\b/gi, type: 'keyword' }
            ];
        }

        detectLanguage(filename) {
            const ext = filename.split('.').pop().toLowerCase();
            const languageMap = {
                'js': 'javascript', 'jsx': 'jsx', 'ts': 'typescript', 'tsx': 'tsx',
                'html': 'html', 'htm': 'html', 'css': 'css', 'py': 'python',
                'php': 'php', 'sql': 'sql', 'md': 'markdown', 'json': 'json',
                'txt': 'javascript', 'xml': 'xml', 'yaml': 'yaml', 'yml': 'yaml'
            };
            return languageMap[ext] || 'javascript';
        }

        setLanguage(language) {
            this.currentLanguage = language;
        }

        escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        highlightText(text, language = null) {
            const lang = language || this.currentLanguage;
            const patterns = this.languagePatterns[lang] || this.languagePatterns.javascript;
            
            let highlighted = this.escapeHtml(text);
            
            patterns.forEach(({ pattern, type }) => {
                highlighted = highlighted.replace(pattern, match => {
                    return `<span class="sh-${type}">${this.escapeHtml(match)}</span>`;
                });
            });
            
            return highlighted;
        }

        highlightElement(element, language = null) {
            const text = element.textContent || '';
            
            const selection = window.getSelection();
            const range = selection.rangeCount > 0 ? selection.getRangeAt(0).cloneRange() : null;
            
            element.innerHTML = this.highlightText(text, language);
            
            if (range && element.contains(range.startContainer) && element.contains(range.endContainer)) {
                try {
                    selection.removeAllRanges();
                    selection.addRange(range);
                } catch (e) {
                    console.warn("Could not restore selection after highlight:", e);
                }
            }
        }

        enableRealtimeHighlighting(editorElement, language = null) {
            let isComposing = false;
            
            const highlight = () => {
                if (isComposing) return;
                
                clearTimeout(this.debounceTimer);
                this.debounceTimer = setTimeout(() => {
                    this.highlightElement(editorElement, language);
                }, this.debounceDelay);
            };
            
            editorElement.addEventListener('input', highlight);
            editorElement.addEventListener('compositionstart', () => { isComposing = true; });
            editorElement.addEventListener('compositionend', () => { 
                isComposing = false; 
                highlight();
            });
            editorElement.addEventListener('paste', () => setTimeout(highlight, 10));
            
            highlight();
        }
    }
		
		html {
			position: relative;
			display: block;
			width: 100%;
			height: 100%;
		}

        html, body {
            height: 100%;
            margin: 0;
            padding: 0;
            font-family: 'Fira Code', monospace;
            font-size: var(--font-size);
            line-height: var(--baseline);
            background: var(--theme-bg);
            color: #f0f0e0;
            overflow: hidden;
        }

        body {
            display: grid;
            grid-template-rows: var(--header-h) var(--status-h) 1fr var(--footer-h);
        }

        header {
            grid-row: 1;
            grid-column: 1 / -1;
            background: var(--header-bg);
            border-bottom: 1px solid #22241e;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 6px 12px;
            position: relative;
            overflow: hidden;
        }

        header::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, var(--quantum-glow), transparent);
            animation: quantumScan 3s infinite linear;
        }

        @keyframes quantumScan {
            0% { left: -100%; }
            100% { left: 100%; }
        }

        .quantum-pulse {
            animation: quantumPulse 2s infinite alternate;
        }

        .typing-active {
            caret-color: lime;
            animation: blink 1s infinite;
        }

        @keyframes blink {
            0%, 50% { background-color: transparent; }
            51%, 100% { background-color: rgba(0,255,0,0.05); }
        }

        @keyframes quantumPulse {
            0% { opacity: 0.7; transform: scale(1); }
            100% { opacity: 1; transform: scale(1.05); }
        }

        header .left {
            display: flex;
            gap: 12px;
            align-items: center;
            position: relative;
            z-index: 2;
        }

        header .right {
            display: flex;
            gap: 8px;
            align-items: center;
            position: relative;
            z-index: 2;
        }

        button {
            background: var(--err);
            border: 1px solid var(--err);
            color: #f0f0e0;
            padding: 6px 8px;
            cursor: pointer;
            font-size: 12px;
            transition: all .2s;
            border-radius: 3px;
        }

        button:hover {
            background: var(--hover-blue);
            border-color: var(--hover-blue);
        }

        button.success {
            background: var(--accent);
            border-color: var(--accent);
        }

        button.info {
            background: var(--info-bg);
            border-color: var(--info-bg);
        }

        button.warn {
            background: var(--warn-bg);
            border-color: var(--warn-bg);
            color: #3a3c31;
        }

        #status-bar {
            grid-row: 2;
            grid-column: 1 / -1;
            background: var(--status-bg);
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 4px 12px;
            font-size: 12px;
            position: relative;
        }

        .quantum-threads {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            opacity: 0.3;
        }

        .quantum-thread {
            position: absolute;
            width: 1px;
            height: 100%;
            background: linear-gradient(to bottom, transparent, var(--agent-nexus), transparent);
            animation: threadFlow 2s infinite linear;
        }

        @keyframes threadFlow {
            0% { top: -100%; }
            100% { top: 100%; }
        }
		
		#editor {
			overflow: hidden;
		}

        #editor-stage {
            grid-row: 3;
            grid-column: 1 / -1;
            display: grid;
            grid-template-columns: 0px 1fr;
            background: var(--theme-bg);
            overflow: hidden;
            position: relative;
            transition: grid-template-columns 0.3s ease;
        }

        #editor-stage.left-panel-open {
            grid-template-columns: 240px 1fr;
        }

        #left-panel {
            background: var(--panel);
            border-right: 1px solid #22241e;
            padding: 10px;
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
            gap: 8px;
            overflow: hidden;
            width: 240px;
        }

        .editor-container {
            position: relative;
            display: flex;
            flex: 1;
            background: var(--theme-bg);
            overflow: auto;
        }

        .line-numbers {
            width: var(--ln-width);
            padding: 10px 8px;
            background: var(--panel);
            color: var(--muted-text);
            font-variant-numeric: tabular-nums;
            text-align: right;
            user-select: none;
            line-height: var(--baseline);
            font-family: inherit;
            font-size: inherit;
            flex-shrink: 0;
            position: sticky;
            left: 0;
            z-index: 10;
        }

        .editor-content {
            flex: 1;
            position: relative;
            min-height: 100%;
            padding: 10px;
            padding-left: 12px;
            box-sizing: border-box;
            white-space: pre;
            line-height: var(--baseline);
            font-family: inherit;
            font-size: inherit;
            tab-size: 4;
            -moz-tab-size: 4;
            caret-color: var(--accent);
            outline: none;
            overflow-wrap: normal;
            word-break: normal;
            overflow: auto;
        }

        .editor-content:focus {
            outline: none;
        }

        footer {
            grid-row: 4;
            grid-column: 1 / -1;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 6px 12px;
            background: var(--header-bg);
            border-top: 1px solid #22241e;
            position: sticky;
            bottom: 0;
        }

        #prompt-input {
            flex: 1;
            margin-right: 8px;
            padding: 8px;
            background: var(--status-bg);
            border: 1px solid var(--accent);
            color: #f0f0e0;
            font-family: inherit;
            border-radius: 3px;
            font-size: 16px;
        }

        .small {
            font-size: 12px;
            padding: 6px 8px;
        }

        .agent-card {
            background: var(--panel);
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 8px;
            border-left: 4px solid var(--muted-text);
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .agent-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.1), transparent);
            transition: left 0.5s ease;
        }

        .agent-card.active::before {
            left: 100%;
        }

        .agent-card.active {
            box-shadow: 0 0 20px var(--quantum-glow);
            transform: translateY(-2px);
        }

        .agent-card.nexus { border-left-color: var(--agent-nexus); }
        .agent-card.cognito { border-left-color: var(--agent-cognito); }
        .agent-card.relay { border-left-color: var(--agent-relay); }
        .agent-card.sentinel { border-left-color: var(--agent-sentinel); }
        .agent-card.echo { border-left-color: var(--agent-echo); }

        .agent-title {
            font-weight: bold;
            font-size: 14px;
            margin-bottom: 4px;
        }

        .agent-nexus .agent-title { color: var(--agent-nexus); }
        .agent-cognito .agent-title { color: var(--agent-coo); }
        .agent-relay .agent-title { color: var(--agent-relay); }
        .agent-sentinel .agent-title { color: var(--agent-sentinel); }
        .agent-echo .agent-title { color: var(--agent-echo); }

        .agent-subtitle {
            font-size: 11px;
            color: var(--muted-text);
            margin-bottom: 6px;
        }

        .agent-content {
            font-size: 12px;
            line-height: 1.4;
            min-height: 20px;
        }

        .quantum-spinner {
      width: 16px;
            height: 16px;
            display: inline-block;
            margin-right: 6px;
            position: relative;
        }

        .quantum-spinner::before {
            content: '';
            position: absolute;
            width: 100%;
            height: 100%;
            border: 2px solid transparent;
            border-top: 2px solid var(--agent-cognito);
            border-radius: 50%;
            animation: quantumSpin 1s linear infinite;
        }

 .quantum-spinner::after {
            content: '';
            position: absolute;
            width: 100%;
            height: 100%;
            border: 2px solid transparent;
            border-bottom: 2px solid var(--agent-nexus);
            border-radius: 50%;
            animation: quantumSpin 0.5s linear infinite;
        }

        @keyframes quantumSpin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .quantum-packet {n            position: fixed;
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: var(--agent-nexus);
            box-shadow: 0 0 10px var(--agent-nexus);
            opacity: 0;
            z-index: 100;
            pointer-events: none;
        }

        .quantum-trail {
            position: absolute;
            width: 100%;
            height: 2px;
            background: linear-gradient(90deg, transparent, var(--agent-nexus), transpa);
            opacity: 0;
        }

        .action-buttons {
            display: flex;
            gap: 8px;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid var(--muted-text);
        }

        .action-buttons button {
            flex: 1;
            padding: 6px;
            font-size: 11px;
        }

        .quantum-status {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 1n            margin-top: 5px;
        }

        .quantum-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--muted-text);
            position: relative;
        }

        .quantum-dot::before {
            content: '';
            position: absolute;
            top: -2px;
            left: -2px;
            right: -2px;
            bottom: -2px;
            border-radius: 50%;
            border: 1px solid var(--agent-ne;
            animation: quantumPulseDot 2s infinite;
        }

        .quantum-dot.connected {
            background: var(--accent);
        }

        @keyframes quantumPulseDot {
            0%, 100% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.3); opacity: 0.7; }
        }

        /* ========== SYNTAX HIGHLIGHTING STYLES ========== */
        .sh-token { transition: opacity 0.08s ease; pointer-events: none; }
        .sh-comment { color: #64748b; font-stylitalic; opacity: 0.8; }
        .sh-string { color: #a3e635; font-weight: 500; }
        .sh-number { color: #f59e0b; font-weight: 600; }
        .sh-keyword { color: #f472b6; font-weight: 600; }
        .sh-type { color: #7dd3fc; font-weight: 500; }
        .sh-bracket { color: #c084fc; font-weight: 700; }
        .sh-id { color: #94a3b8; }
        .sh-op { color: #94a3b8; font-weight: 500; }
        .sh-ws { opacity: 0.3; }
        .sh-key { color: #7dd3fc; font-weight: 500; }
        .sh-number2 { color: #f59e0b; font-weight: 600; }
        .sh-text { color: #e2e8f0; }
        .sh-unknown { color: #f87171; }
        .sh-tag { color: #f472b6; font-weight: 600; }
        .sh-property { color: #7dd3fc; font-weight: 500; }
        .sh-function { color: #4ac94a; font-weight: 500; }
        .sh-operator { color: #93c5fd; font-weight: 600; }
        .sh-regex { color: #fbbf24; }
        .sh-html-entity { color: #f59e0b; }
        .sh-css-selector { color: #c084fc; }
        .sh-css-property { or: #60a5fa; }
        .sh-css-value { color: #34d399; }
        .sh-jsx-tag { color: #f472b6; }
        .sh-jsx-attribute { color: #7dd3fc; }
        .sh-template-string { color: #a3e635; font-weight: 500; }

        .editor-content::selection {
            background: rgba(74, 201, 74, 0.3);
        }

        .editor-container::-webkit-scrollbar {
            width: 12px;
        }

        .editor-container::-webkit-scrollbar-track {
            background: var(--panel);
        }

     .editor-container::-webkit-scrollbar-thumb {
            background: var(--muted-text);
            border-radius: 6px;
        }

        .editor-container::-webkit-scrollbar-thumb:hover {
            background: var(--accent);
        }

        #preview-panel {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 80%;
            height: 80%;
            background: white;
            border: 2px solir(--accent);
            border-radius: 5px;
            z-index: 1000;
            display: none;
            flex-direction: column;
            box-shadow: 0 0 30px rgba(0,0,0,.7);
        }

        #preview-header {
            background: var(--header-bg);
            color: #f0f0e0;
            padding: 8px 12px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--accent);
        }

      #preview-content {
            width: 100%;
            height: calc(100% - 40px);
            border: none;
            background: white;
        }

        #close-preview {
            background: transparent;
            border: none;
            color: #f0f0e0;
            font-size: 18px;
            cursor: pointer;
            padding: 0;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: cent;
        }

        #ai-response-panel {
            position: fixed;
            bottom: 60px;
            right: 20px;
            width: 500px;
            max-height: 600px;
            background: var(--panel);
            border: 1px solid var(--accent);
            border-radius: 5px;
            padding: 15px;
            overflow-y: auto;
            z-index: 100;
            display: none;
            box-shadow: 0 4px 12px rgba(0,0,0,.3);
        }

        #ai-response-conten {
            font-size: 12px;
            line-height: 1.4;
        }

        #close-ai-panel {
            position: absolute;
            top: 5px;
            right: 5px;
            background: transparent;
            border: none;
            color: var(--muted-text);
            font-size: 14px;
            cursor: pointer;
        }

        #file-input {
            display: none;
        }

        .ai-status {
            display: flex;
            align-items: center;
      gap: 5px;
        }

        .ai-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--accent);
            animation: none;
        }

        .ai-dot.probing {
            background: var(--err);
            animation: pulse 2s infinite;
        }

        .ai-dot.connected {
            background: var(--accent);
            animation: none;
        }

        .quantum-thinking {
            position: absolute;
        top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            z-index: 5;
        }

        .fractal-node {
            position: absolute;
            width: 4px;
            height: 4px;
            border-radius: 50%;
            background: var(--agent-cognito);
            animation: fractalPulse 1.5s infinite alternate;
        }

        @keyframes fractalPulse {
            0% { transform: scale(1); opacity: 0.3;
            100% { transform: scale(1.5); opacity: 0.8; }
        }

        @media (max-width: 768px) {
            #editor-stage {
                grid-template-columns: 1fr !important;
            }

            #left-panel {
                position: absolute;
                height: 100%;
                z-index: 30;
                transform: translateX(-240px);
            }

            #left-panel.open {
                transform: translateX(0);
            }

            #ai-rponse-panel {
                width: calc(100% - 40px);
                right: 20px;
                left: 20px;
            }

            #preview-panel {
                width: 95%;
                height: 85%;
            }

            body {
                grid-template-rows: var(--header-h) var(--status-h) 1fr auto;
            }

            footer {
                position: relative;
            }
        }

        .consensus-panel {
            background: var(--panel);
       border: 1px solid var(--agent-nexus);
            border-radius: 8px;
            padding: 15px;
            margin-top: 15px;
            max-height: 300px;
            overflow-y: auto;
        }

        .consensus-header {
            font-weight: bold;
            color: var(--agent-nexus);
            margin-bottom: 10px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .candidate-item {
            backgr rgba(255,255,255,0.05);
            border-radius: 4px;
            padding: 8px;
            margin-bottom: 8px;
            border-left: 3px solid var(--agent-cognito);
        }

        .candidate-meta {
            font-size: 10px;
            color: var(--muted-text);
            display: flex;
            justify-content: space-between;
            margin-bottom: 4px;
        }

        .candidate-content {
            font-size: 11px;
            font-family: 'Fira Code', monospacen            white-space: pre-wrap;
            max-height: 80px;
            overflow: hidden;
        }

        .entropy-badge {
            background: var(--agent-nexus);
            color: white;
            padding: 2px 6px;
            border-radius: 10px;
            font-size: 10px;
        }

        .selected-candidate {
            border-left-color: var(--accent);
            background: rgba(74, 201, 74, 0.1);
        }

        .orchestration-log {
            background: a(0,0,0,0.3);
            border-radius: 4px;
            padding: 8px;
            margin-top: 10px;
            max-height: 120px;
            overflow-y: auto;
            font-size: 10px;
            font-family: 'Fira Code', monospace;
        }

        .orchestration-log .log-entry {
            margin-bottom: 4px;
            padding-left: 10px;
            border-left: 2px solid var(--agent-nexus);
        }

        .orchestration-log .log-entry.genesis {
            border-left-c var(--agent-nexus);
            color: var(--agent-nexus);
        }

        .orchestration-log .log-entry.origin {
            border-left-color: var(--agent-cognito);
            color: var(--agent-cognito);
        }

        .orchestration-log .log-entry.event {
            border-left-color: var(--agent-relay);
            color: var(--agent-relay);
        }

        .orchestration-log .log-entry.fragment {
            border-left-color: var(--agent-sentinel);
            color: var(nt-sentinel);
        }

        .orchestration-log .log-entry.consensus {
            border-left-color: var(--agent-echo);
            color: var(--agent-echo);
        }
        
        .orchestration-log .log-entry.verification { border-left-color: var(--agent-nexus); color: var(--agent-nexus); }
        .orchestration-log .log-entry.analysis { border-left-color: var(--agent-sentinel); color: var(--agent-sentinel); }
        .orchestration-log .log-entry.alignment { border-left-color: var(--ant-relay); color: var(--agent-relay); }
        .orchestration-log .log-entry.validation { border-left-color: var(--agent-echo); color: var(--agent-echo); }
        .orchestration-log .log-entry.optimization { border-left-color: var(--agent-sentinel); color: var(--agent-sentinel); }
        .orchestration-log .log-entry.security { border-left-color: var(--agent-sentinel); color: var(--agent-sentinel); }
        .orchestration-log .log-entry.documentation { border-left-color: var(--agent-echo); color: va(--agent-echo); }
        .orchestration-log .log-entry.ux { border-left-color: var(--agent-relay); color: var(--agent-relay); }
        .orchestration-log .log-entry.archive { border-left-color: var(--agent-nexus); color: var(--agent-nexus); }


        .memory-status {
            font-size: 10px;
            color: var(--muted-text);
            padding: 2px 6px;
            border-radius: 3px;
            background: rgba(0,0,0,0.3);
        }

        .memory-status.low {
            colo: #f87171;
            background: rgba(248, 113, 113, 0.1);
        }

        .memory-status.warning {
            color: #f59e0b;
            background: rgba(245, 158, 11, 0.1);
        }

        .memory-status.good {
            color: #4ac94a;
        }

        .suggestion-item {
            padding: 8px;
            border-bottom: 1px solid var(--muted-text);
            cursor: pointer;
            transition: background 0.2s;
        }

        .suggestion-item:hover {
          background: rgba(255,255,255,0.1);
        }

        .suggestion-item:last-child {
            border-bottom: none;
        }

        #suggestions-panel {
            position: absolute;
            background: var(--panel);
            border: 1px solid var(--accent);
            border-radius: 4px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 1000;
            display: none;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        }
    </stye>
</head>
<body>
<header>
    <div class="left">
        <button id="left-toggle" class="small">☰</button>
        <div style="font-weight:800;" class="quantum-pulse">Nemodian 2244-1 :: Quantum Fractal AI</div>
    </div>
    <div class="right">
        <div class="ai-status">
            <div id="ai-dot" class="ai-dot connected"></div>
            <div id="ai-indicator" style="font-size:12px;color:#cfcfbd;">Quantum AI: Ready</div>
        </div>
        <button id="opn-file" class="small">Open</button>
        <button id="save-file" class="small">Save</button>
        <button id="save-as" class="small">Save As</button>
        <button id="render-html" class="small warn">Render HTML</button>
        <button id="run-local-ai" class="small info">Quantum AI</button>
        <button id="run-orchestrator" class="small success">Orchestrator</button>
    </div>
</header>
<div id="status-bar" class="info">
    <div class="quantum-threads" id"quantum-threads"></div>
    <div id="file-meta">No File Loaded</div>
    <div id="editor-meta">Cursor: 0:0 | Lines: 0 | Chars: 0 | History: 0</div>
    <div id="memory-status" class="memory-status good">RAM: OK</div>
</div>
<div id="editor-stage">
    <aside id="left-panel" class="closed">
        <button id="btn-undo" class="small">UNDO</button>
        <button id="btn-redo" class="small">REDO</button>
        <button id="btn-beautify" class="small">Beautify</button>
      <button id="btn-render" class="small warn">Render HTML</button>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Quantum AI Commands:</strong></p>
            <ul style="padding-left: 15px;">
                <li>Rewrite this function</li>
                <li>Optimize performance</li>
                <li>Add error handling</li>
                <li>Convert to TypeScript</li>
                <li>Explain this code</li>
            >
        </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Quantum Actions:</strong></p>
            <button id="btn-optimize" class="small" style="width:100%;margin-bottom:5px;">Quantum Optimize</button>
            <button id="btn-document" class="small" style="width:100%;margin-bottom:5px;">Fractal Document</button>
            <button id="btn-refactor" class="small" style="width:100%;">Hyper Refactor</button>
       <button id="btn-orchestrate" class="small success" style="width:100%;margin-top:5px;">Multi-Agent Consensus</button>
        </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Memory Management:</strong></p>
            <button id="btn-clear-cache" class="small" style="width:100%;margin-bottom:5px;">Clear Cache</button>
            <button id="btn-optimize-memory" class="small info" style="width:100%;margin-bottom:5">Optimize Memory</button>
            <button id="btn-export-session" class="small" style="width:100%;">Export Session</button>
        </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Quantum Settings:</strong></p>
            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                <input type="checkbox" id="quantum-mode" checked>
                <label for="quantum-mode">Quantu Fractal Mode</label>
            </div>
            <div style="display: flex; align-items: center; gap: 8px;">
                <input type="checkbox" id="hyperthreading" checked>
                <label for="hyperthreading">Hyperthreading</label>
            </div>
            <div style="display: flex; align-items: center; gap: 8px; margin-top: 5px;">
                <input type="checkbox" id="multi-agent-mode" checked>
                <label for="multi-agent-mode">Multi-Agent Cons/label>
            </div>
            <div style="display: flex; align-items: center; gap: 8px; margin-top: 5px;">
                <input type="checkbox" id="auto-save" checked>
                <label for="auto-save">Auto Save</label>
            </div>
        </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Orchestrator Settings:</strong></p>
            <div style="margin-bottom: 5px;">
                <label for="agent-count">Agent Count:</label>
                <input type="number" id="agent-count" min="2" max="8" value="5" style="width: 60px; background: var(--status-bg); color: white; border: 1px solid var(--muted-text); padding: 2px; border-radius: 3px;">
            </div>
            <div style="margin-bottom: 5px;">
                <label for="max-rounds">Max Rounds:</label>
                <input type="number" id="max-rounds" min="1" max="10" value="3" style="width: 60px; backround: var(--status-bg); color: white; border: 1px solid var(--muted-text); padding: 2px; border-radius: 3px;">
            </div>
            <div style="margin-bottom: 5px;">
                <label for="reasoning-depth">Reasoning Depth:</label>
                <input type="number" id="reasoning-depth" min="1" max="5" value="3" style="width: 60px; background: var(--status-bg); color: white; border: 1px solid var(--muted-text); padding: 2px; border-radius: 3px;">
            </div>
     </div>

        <div style="margin-top: 20px; font-size: 11px; color: var(--muted-text);">
            <p><strong>Recent Files:</strong></p>
            <div id="recent-files" style="max-height: 100px; overflow-y: auto;">
                <!-- Recent files will be populated here -->
            </div>
        </div>
    </aside>

    <!-- Quantum Editor Container -->
    <div class="editor-container">
        <div class="quantum-thinking" id="quantum-thinking"></div>
        <div ass="line-numbers" id="line-numbers"></div>
        <div
            class="editor-content"
            id="editor"
            contenteditable="true"
            spellcheck="false"
            data-gramm="false"
            data-gramm_editor="false"
            data-enable-grammarly="false"
        >// Quantum Fractal AI Editor - Ready
// Start coding or use the prompt below for AI assistance

function welcome() {
    return "Welcome to the Quantum Fractal AI Editor!";
}</v>
    </div>
</div>
<footer>
    <input id="prompt-input" placeholder="Enter quantum command (e.g., 'create a function to sort arrays')">
    <button id="send-button" class="success">QUANTUM PROCESS</button>
</footer>

<!-- Hidden elements -->
<input type="file" id="file-input" accept=".js,.html,.css,.txt,.json,.ts,.jsx,.tsx,.py,.php,.sql,.md,.xml,.yaml,.yml">
<div id="suggestions-panel"></div>

<!-- Panels -->
<div id="preview-panel">
    <div id="preview-header">
      pan>Quantum Preview</span>
        <button id="close-preview">×</button>
    </div>
    <iframe id="preview-content"></iframe>
</div>

<div id="ai-response-panel">
    <button id="close-ai-panel">×</button>
    <div id="ai-response-content">
        <div class="agent-card nexus agent-nexus">
            <div class="agent-title">Nexus</div>
            <div class="agent-subtitle">Quantum Orchestrator (Fractal Core)</div>
            <div class="agent-content">Idle. Awaiting qum command.</div>
            <div class="orchestration-log" id="nexus-log"></div>
            <div class="quantum-status">
                <div class="quantum-dot connected"></div>
                <span>Quantum State: Entangled</span>
            </div>
        </div>
        <div class="agent-card cognito agent-cognito">
            <div class="agent-title">Cognito</div>
            <div class="agent-subtitle">Fractal Analyzer (Quantum Loop)</div>
            <div class="agent-cont>Ready</div>
            <div class="orchestration-log" id="cognito-log"></div>
        </div>
        <div class="agent-card relay agent-relay">
            <div class="agent-title">Relay</div>
            <div class="agent-subtitle">Quantum Communicator (Wave)</div>
            <div class="agent-content">Ready</div>
            <div class="orchestration-log" id="relay-log"></div>
        </div>
        <div class="agent-card sentinel agent-sentinel">
            <div class="agitle">Sentinel</div>
            <div class="agent-subtitle">Quantum Monitor (Fractal Coin)</div>
            <div class="agent-content">Ready</div>
            <div class="orchestration-log" id="sentinel-log"></div>
        </div>
        <div class="agent-card echo agent-echo">
            <div class="agent-title">Echo</div>
            <div class="agent-subtitle">Quantum Reporter (Fractal Code)</div>
            <div class="agent-content">Awaiting quantum report...</div>
       <div class="orchestration-log" id="echo-log"></div>
        </div>
        <div class="consensus-panel" id="consensus-panel" style="display: none;">
            <div class="consensus-header">
                <span>Multi-Agent Consensus Results</span>
                <span class="entropy-badge" id="consensus-score">Score: 0</span>
            </div>
            <div id="candidates-list"></div>
        </div>
    </div>
</div>

<!-- GSAP for animations -->
<script src="https://njs.cloudflare.com/ajax/libs/gsap/3.9.1/gsap.min.js"></script>

<script>
    /* =========================================================================
       QUANTUM FRACTAL AI EDITOR - FULL FUNCTIONALITY
       ========================================================================== */

    // Global state
    window.quantumState = {
        isGenerating: true,
        isSpeaking: true,
        currentSession: null,
        recentFiles: [],
        settings: {
            quantumMode: tn            hyperthreading: true,
            multiAgentMode: true,
            autoSave: true,
            agentCount: 5,
            maxRounds: 1,
            reasoningDepth: 2
        }
    };

    /* =========================================================================
       MEMORY MANAGER - Enhanced with Full Features
       ========================================================================== */

    class QuantumMemoryManager {
        constructor() {
            this.storagey = 'quantum_editor_cache';
            this.settingsKey = 'quantum_editor_settings';
            this.recentFilesKey = 'quantum_recent_files';
            this.maxMemoryThreshold = 50 * 1024 * 1024;
            this.cacheLimit = 40960;
            this.memoryStatus = document.getElementById('memory-status');
            this.cleanupInterval = null;
            
            this.init();
        }

        init() {
            this.loadSettings();
            this.loadRecentFiles();
          startMemoryMonitoring();
            this.cleanupOldCache();
        }

        startMemoryMonitoring() {
            this.cleanupInterval = setInterval(() => {
                this.checkMemoryUsage();
            }, 3200);

            window.addEventListener('beforeunload', () => this.cleanup());
        }

        async checkMemoryUsage() {
            try {
                if ('memory' in performance) {
                    const memory = performance.memory;
                    const usedmemory.usedJSHeapSize;
                    const limit = memory.jsHeapSizeLimit;
                    
                    const usagePercent = (used / limit) * 100;
                    
                    if (usagePercent > 80) {
                        this.memoryStatus.textContent = 'RAM: CRITICAL';
                        this.memoryStatus.className = 'memory-status low';
                        this.emergencyCleanup();
                    } else if (usagePercent > 60) {
                      .memoryStatus.textContent = 'RAM: WARNING';
                        this.memoryStatus.className = 'memory-status warning';
                        this.aggressiveCleanup();
                    } else {
                        this.memoryStatus.textContent = 'RAM: OK';
                        this.memoryStatus.className = 'memory-status good';
                    }
                }
            } catch (error) {
                console.warn('Memory monitoring unavailable:', error);
            }
        }

        // Settings management
        loadSettings() {
            try {
                const stored = localStorage.getItem(this.settingsKey);
                if (stored) {
                    const settings = JSON.parse(stored);
                    window.quantumState.settings = { ...window.quantumState.settings, ...settings };
                    this.applySettings();
                }
            } catch (error) {
                console.warn('Settings load failed:', error);
          }
        }

        saveSettings() {
            try {
                localStorage.setItem(this.settingsKey, JSON.stringify(window.quantumState.settings));
            } catch (error) {
                console.warn('Settings save failed:', error);
            }
        }

        applySettings() {
            const settings = window.quantumState.settings;
            document.getElementById('quantum-mode').checked = settings.quantumMode;
            document.getElementById('hyperthread').checked = settings.hyperthreading;
            document.getElementById('multi-agent-mode').checked = settings.multiAgentMode;
            document.getElementById('auto-save').checked = settings.autoSave;
            document.getElementById('agent-count').value = settings.agentCount;
            document.getElementById('max-rounds').value = settings.maxRounds;
            document.getElementById('reasoning-depth').value = settings.reasoningDepth;
        }

        // Recent files management
    loadRecentFiles() {
            try {
                const stored = localStorage.getItem(this.recentFilesKey);
                if (stored) {
                    window.quantumState.recentFiles = JSON.parse(stored);
                    this.updateRecentFilesUI();
                }
            } catch (error) {
                console.warn('Recent files load failed:', error);
            }
        }

        saveRecentFiles() {
            try {
                localStorage.setItem(this.recentFilesKey, JSON.stringify(window.quantumState.recentFiles));
            } catch (error) {
                console.warn('Recent files save failed:', error);
            }
        }

        addRecentFile(filename, content) {
            // Remove if already exists
            window.quantumState.recentFiles = window.quantumState.recentFiles.filter(f => f.filename !== filename);
            
            // Add to beginning
            window.quantumState.recentFiles.unshift({
                filename,
                content: content.substring(0, 1000), // Store only preview
                timestamp: Date.now()
            });

            // Keep only last 10 files
            window.quantumState.recentFiles = window.quantumState.recentFiles.slice(0, 10);
            
            this.saveRecentFiles();
            this.updateRecentFilesUI();
        }

        updateRecentFilesUI() {
            const container = document.getElementById('recent-files');
            container.innerHTM = '';

            window.quantumState.recentFiles.forEach(file => {
                const item = document.createElement('div');
                item.className = 'suggestion-item';
                item.innerHTML = `
                    <div style="font-weight: bold;">${file.filename}</div>
                    <div style="font-size: 9px; color: var(--muted-text);">${new Date(file.timestamp).toLocaleDateString()}</div>
                `;
                item.addEventListener('click', () => {
             quantumEditor.setContent(file.content, quantumEditor.highlighter.detectLanguage(file.filename));
                    document.getElementById('file-meta').textContent = file.filename;
                    quantumEditor.currentFileName = file.filename;
                });
                container.appendChild(item);
            });

            if (window.quantumState.recentFiles.length === 0) {
                container.innerHTML = '<div style="padding: 8px; color: var(--muted-text); font-10px;">No recent files</div>';
            }
        }

        async store(key, data, priority = 'medium') {
            try {
                const cache = this.getCache();
                const dataSize = new Blob([JSON.stringify(data)]).size;
                if (dataSize > this.maxMemoryThreshold) {
                    throw new Error('Data too large for storage');
                }

                cache[key] = {
                    data: data,
                    timestamp: Date.now(),\                 priority: priority,
                    size: dataSize
                };

                if (Object.keys(cache).length > this.cacheLimit) {
                    this.cleanupCache();
                }

                await this.saveCache(cache);
                return true;
            } catch (error) {
                console.warn('Storage failed, falling back to memory:', error);
                if (!window.quantumMemoryCache) {
                    window.quantumMemoryCache  new Map();
                }
                window.quantumMemoryCache.set(key, data);
                return false;
            }
        }

        async retrieve(key) {
            try {
                const cache = this.getCache();
                if (cache[key]) {
                    return cache[key].data;
                }
                
                if (window.quantumMemoryCache && window.quantumMemoryCache.has(key)) {
                    return window.quantumMemoryCache.get(ke;
                }
                
                return null;
            } catch (error) {
                console.warn('Retrieval failed:', error);
                return null;
            }
        }

        cleanupCache() {
            try {
                const cache = this.getCache();
                const entries = Object.entries(cache);
                
                if (entries.length > this.cacheLimit) {
                    entries.sort((a, b) => a[1].timestamp - b[1].timesmp);
                    const toRemove = entries.slice(0, Math.floor(entries.length * 0.3));
                    toRemove.forEach(([key]) => delete cache[key]);
                    this.saveCache(cache);
                }
            } catch (error) {
                console.warn('Cache cleanup failed:', error);
            }
        }

        emergencyCleanup() {
            try {
                localStorage.removeItem(this.storageKey);
                sessionStorage.clear();
               
                if (window.quantumMemoryCache) {
                    window.quantumMemoryCache.clear();
                }
                
                if (window.gc) window.gc();
                this.clearLargeArrays();
                console.log('Emergency memory cleanup completed');
            } catch (error) {
                console.error('Emergency cleanup failed:', error);
            }
        }

        aggressiveCleanup() {
            try {
                const cache = thietCache();
                const entries = Object.entries(cache);
                const toKeep = entries.filter(([key, entry]) => 
                    entry.priority === 'high' && entry.size < 1024 * 1024
                );
                this.saveCache(Object.fromEntries(toKeep));
                
                if (window.quantumMemoryCache) {
                    const keys = Array.from(window.quantumMemoryCache.keys());
                    keys.slice(0, Math.floor(keys.length * 0.5)).forEach(k> 
                        window.quantumMemoryCache.delete(key)
                    );
                }
                console.log('Aggressive memory cleanup completed');
            } catch (error) {
                console.warn('Aggressive cleanup failed:', error);
            }
        }

        clearLargeArrays() {
            if (window.largeArrays) {
                window.largeArrays.clear();
            }
        }

        cleanupOldCache() {
            const cache = this.getC);
            const now = Date.now();
            const oneHour = 60 * 60 * 1000;
            
            Object.keys(cache).forEach(key => {
                if (now - cache[key].timestamp > oneHour) {
                    delete cache[key];
                }
            });
            this.saveCache(cache);
        }

        getCache() {
            try {
                const stored = localStorage.getItem(this.storageKey);
                return stored ? JSON.parse(stored) : {};
           } catch (error) {
                console.warn('Cache retrieval failed:', error);
                return {};
            }
        }

        async saveCache(cache) {
            try {
                localStorage.setItem(this.storageKey, JSON.stringify(cache));
            } catch (error) {
                console.warn('Cache save failed:', error);
            }
        }

        cleanup() {
            if (this.cleanupInterval) {
                clearInterval(this.cleanupInterval);
       }
        }

        async exportSession() {
            try {
                const sessionData = {
                    timestamp: Date.now(),
                    cache: this.getCache(),
                    memoryCache: window.quantumMemoryCache ? 
                        Array.from(window.quantumMemoryCache.entries()) : [],
                    recentFiles: window.quantumState.recentFiles,
                    settings: window.quantumState.settings
                };
                
               const blob = new Blob([JSON.stringify(sessionData, null, 2)], 
                    { type: 'application/json' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `quantum_session_${Date.now()}.json`;
                a.click();
                URL.revokeObjectURL(url);
                return true;
            } catch (error) {
                console.error('Session exfailed:', error);
                return false;
            }
        }

        async clearAllCache() {
            try {
                localStorage.removeItem(this.storageKey);
                localStorage.removeItem(this.settingsKey);
                localStorage.removeItem(this.recentFilesKey);
                if (window.quantumMemoryCache) {
                    window.quantumMemoryCache.clear();
                }
                sessionStorage.clear();
                return true;
           } catch (error) {
                console.error('Cache clearance failed:', error);
                return false;
            }
        }
    }
"""
                }
            ]
        }
    ],
    thinking={
        "type": "enabled",
        "budget_tokens": 63999
    }
)
print(message.content)
