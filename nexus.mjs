// nexus.mjs
import crypto from "crypto";
import fetch from "node-fetch";

const PYTHON_BRIDGE = "http://127.0.0.1:7777";

export function genesisHash(input) {
  return crypto.createHash("sha256").update(input).digest("hex");
}

export function routeAgent(hash) {
  return parseInt(hash.slice(0, 8), 16) % 8;
}

const agents = [
  "LOOP", "LINE", "CODE", "CUBE",
  "WORK", "CORE", "SIGN", "COIN"
];

export async function handleRequest(prompt) {
  const genesis = genesisHash(prompt);
  const slot = routeAgent(genesis);
  const agent = agents[slot];

  const payload = {
    prompt,
    genesis,
    agent,
    slot
  };

  const res = await fetch(PYTHON_BRIDGE + "/infer", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });

  const data = await res.json();
  return data;
}

