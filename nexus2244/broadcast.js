import WebSocket from "ws";

const [agent, token, sha, genesis, md5] = process.argv.slice(2);

const ws = new WebSocket("ws://localhost:2244");

ws.on("open", () => {
  ws.send(JSON.stringify({ agent, token, sha, genesis, md5, time: Date.now() }));
  ws.close();
});
