import WebSocket, { WebSocketServer } from "ws";

export const timeline = [];

const wss = new WebSocketServer({ port: 2244 });
let clients = [];

wss.on("connection", ws => {
  clients.push(ws);
  console.log("Client connected to NEXUS Stream");
  ws.on("close", () => clients = clients.filter(c => c !== ws));
});

export function broadcast(agent, token, sha, genesis, md5) {
  const msg = JSON.stringify({ agent, token, sha, genesis, md5, time: Date.now() });
  timeline.push(msg);
  clients.forEach(c => {
    if(c.readyState === WebSocket.OPEN) c.send(msg);
  });
}