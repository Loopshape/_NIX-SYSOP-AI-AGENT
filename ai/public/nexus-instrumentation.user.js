// ==UserScript==
// @name         NEXUS-2244 Browser Instrumentation
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  DOM capture and event streaming for NEXUS-2244
// @author       NEXUS-CORE
// @match        *://*/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    const WS_URL = 'ws://localhost:8765';
    let socket = null;

    function connect() {
        socket = new WebSocket(WS_URL);
        socket.onopen = () => console.log('[NEXUS] Connected to Orchestrator');
        socket.onclose = () => setTimeout(connect, 5000);
    }

    function captureDOM() {
        if (!socket || socket.readyState !== WebSocket.OPEN) return;

        const payload = {
            type: 'DOM_STREAM',
            data: {
                url: window.location.href,
                title: document.title,
                html: document.documentElement.outerHTML,
                text_content: document.body.innerText,
                timestamp: Date.now()
            }
        };

        socket.send(JSON.stringify(payload));
    }

    // Capture every 30 seconds or on significant changes
    setInterval(captureDOM, 30000);
    window.addEventListener('load', captureDOM);

    // Visual Feedback Layer
    const feedback = document.createElement('div');
    feedback.style.position = 'fixed';
    feedback.style.bottom = '10px';
    feedback.style.right = '10px';
    feedback.style.padding = '5px 10px';
    feedback.style.background = 'rgba(0, 242, 255, 0.8)';
    feedback.style.color = '#000';
    feedback.style.fontSize = '10px';
    feedback.style.zIndex = '9999';
    feedback.style.fontFamily = 'monospace';
    feedback.innerText = 'NEXUS-2244 ACTIVE';
    document.body.appendChild(feedback);

    connect();
})();
