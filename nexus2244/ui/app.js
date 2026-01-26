const ws = new WebSocket("ws://localhost:2244");
ws.onmessage = e => {
  const m = JSON.parse(e.data);
  document.getElementById("streams").innerHTML +=
    `<div><b>${m.agent}</b>: ${m.token}</div>`;
};