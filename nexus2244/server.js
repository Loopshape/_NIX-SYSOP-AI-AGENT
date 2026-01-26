import { WebSocketServer, WebSocket } from "ws";
import fs from "fs";

if (process.argv[1].endsWith("server.js")) {
  const wss = new WebSocketServer({ port: 2244 });
  let clients = [];

  wss.on("connection", ws => {
    clients.push(ws);
    ws.on("close", () => clients = clients.filter(c => c !== ws));
    ws.on("message", data => {
      const msg = data.toString();
      clients.forEach(c => {
        if (c.readyState === WebSocket.OPEN) c.send(msg);
      });
    });
  });
  console.log("NEXUS Server running on port 2244");
}

export function broadcast(agent, token, sha, genesis, md5) {
  const ws = new WebSocket("ws://localhost:2244");
  ws.on("open", () => {
    ws.send(JSON.stringify({ agent, token, sha, genesis, md5, time: Date.now() }));
    ws.on("error", () => {});
    setTimeout(() => ws.close(), 10);
  });
  ws.on("error", () => {});
}
