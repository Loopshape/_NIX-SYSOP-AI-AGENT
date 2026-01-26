const toolSelect = document.getElementById('tool-select');
const toolArg = document.getElementById('tool-arg');
const runToolBtn = document.getElementById('run-tool');
const toolResult = document.getElementById('tool-result');
const agentGrid = document.getElementById('agent-grid');

const agents = ['core', 'cube', 'loop', 'sign', 'line', 'coin', 'work', 'code'];

// Initialize agent status grid
agents.forEach(name => {
    const div = document.createElement('div');
    div.className = 'log-entry';
    div.style.textAlign = 'center';
    div.innerHTML = `<strong>${name.toUpperCase()}</strong><br><span id="status-${name}">IDLE</span>`;
    agentGrid.appendChild(div);
});

runToolBtn.addEventListener('click', async () => {
    const tool = toolSelect.value;
    const arg = toolArg.value;
    
    toolResult.textContent = 'Executing...';
    
    try {
        const response = await fetch('/api/tools/execute', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                tool,
                args: { path: arg },
                memory_hash: 'manual-execution'
            })
        });
        const data = await response.json();
        toolResult.textContent = JSON.stringify(data.result, null, 2);
    } catch (err) {
        toolResult.textContent = `Error: ${err.message}`;
    }
});

// WebSocket listener for status updates
const ws = new WebSocket(`ws://${window.location.hostname}:8765`);
ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    if (msg.type === 'AGENT_ACTIVE') {
        const span = document.getElementById(`status-${msg.agent}`);
        if (span) {
            span.textContent = 'THINKING';
            span.style.color = 'var(--accent-color)';
            setTimeout(() => {
                span.textContent = 'IDLE';
                span.style.color = '';
            }, 5000);
        }
    }
};
