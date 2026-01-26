import { spawn } from "child_process";
import crypto from "crypto";
import { writeFileSync } from "fs";

export const agents = ["CORE","CUBE","LOOP","SIGN","LINE","COIN","WORK","CODE"];

export function hash(x){
  return crypto.createHash("sha256").update(x).digest("hex");
}

export async function runAgent(model, prompt, genesis){
  const h = hash(genesis+prompt+Date.now());
  return new Promise(resolve=>{
    const p = spawn("ollama", ["run", model], {stdio:["pipe","pipe","pipe"]});
    let output="";
    p.stdout.on("data", d=>{
      output += d.toString();
    });
    p.stdin.write(prompt+"\n");
    p.stdin.end();
    p.on("close",()=> resolve({state:h,output}));
  });
}
