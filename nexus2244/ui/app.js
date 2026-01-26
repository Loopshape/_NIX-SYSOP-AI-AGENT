const ws = new WebSocket("ws://localhost:2244");
ws.onmessage = e => {
  const m = JSON.parse(e.data);
  document.getElementById("genesis").textContent = "Genesis: " + m.genesis;
  const streams = document.getElementById("streams");
  const div = document.createElement("div");
  div.innerHTML = `<b>${m.agent}</b>: ${m.token}`;
  streams.appendChild(div);
  window.scrollTo(0, document.body.scrollHeight);
};
ws.onopen = () => console.log("Connected to NEXUS-2244");
