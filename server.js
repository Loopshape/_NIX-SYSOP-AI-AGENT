#!/bin/env node

import express from "express";
import bodyParser from "body-parser";
import Database from "better-sqlite3";
import crypto from "crypto";
import fetch from "node-fetch";

const app = express();
app.use(bodyParser.json({limit:"50mb"}));

const db = new Database("nexus.db");

db.exec(`
CREATE TABLE IF NOT EXISTS memory (
  id TEXT PRIMARY KEY,
  parent TEXT,
  time INTEGER,
  agent TEXT,
  prompt TEXT,
  response TEXT,
  domdiff TEXT,
  entropy REAL
);
`);

function hash(x){
  return crypto.createHash("sha256").update(x).digest("hex");
}

async function ollama(prompt){
  const r = await fetch("http://localhost:11434/api/generate",{
    method:"POST",
    headers:{ "Content-Type":"application/json" },
    body: JSON.stringify({ model:"gemma3:1b", prompt, stream:false })
  });
  return (await r.json()).response;
}

let lastNode = null;

app.post("/event", async (req,res)=>{
  const {dom, diff, prompt} = req.body;

  const response = await ollama(
    `You are NEXUS. Analyze DOM and diff.\nDOM:\n${dom}\nDIFF:\n${JSON.stringify(diff)}\nUser:${prompt}`
  );

  const entropy = diff.length + response.length;
  const id = hash(Date.now()+response);

  db.prepare(`INSERT INTO memory VALUES (?,?,?,?,?,?,?,?)`)
    .run(id,lastNode,Date.now(),"CORE",prompt,response,JSON.stringify(diff),entropy);

  lastNode = id;

  res.json({response,id});
});

app.get("/memory", (req,res)=>{
  res.json(db.prepare("SELECT * FROM memory").all());
});

app.listen(3000, ()=>console.log("NEXUS online on :3000"));

