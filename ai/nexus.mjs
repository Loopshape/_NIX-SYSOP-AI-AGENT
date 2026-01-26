import { spawn } from "child_process";
import WebSocket from "ws";
import crypto from "crypto";
import { db } from "./memory.mjs";

export function hash(x){
  return crypto.createHash("sha256").update(x).digest("hex");
}

export function runAgent(model, prompt, genesis){
  return new Promise((resolve)=>{
    const h = hash(genesis + prompt + Date.now());

    const p = spawn("ollama", ["run", model], { stdio:["pipe","pipe","pipe"] });

    p.stdin.write(prompt+"\n");
    p.stdin.end();

    let output="";

    p.stdout.on("data", d=>{
      output += d.toString();
      db.storeTokenStream(h, d.toString(), model);
      ws.broadcast(d.toString());
    });

    p.on("close",()=>{
      resolve({state:h, output});
    });
  });
}

