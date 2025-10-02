#!/usr/bin/env node
import { spawn } from 'child_process';
import WebSocket, { WebSocketServer } from 'ws';
import fs from 'fs';
import path from 'path';

// ---------------------------
// Load .env.local
// ---------------------------
const envPath = path.resolve(process.env.HOME, '.env.local');
if (fs.existsSync(envPath)) {
    const envVars = fs.readFileSync(envPath, 'utf8')
        .split('\n')
        .filter(line => line && !line.startsWith('#'));
    envVars.forEach(line => {
        const [key,value] = line.split('=');
        process.env[key.trim()] = value.trim();
    });
}

// ---------------------------
// Setup WebSocket server
// ---------------------------
const PORT = process.env.AI_WS_PORT || 5000;
const wss = new WebSocketServer({ port: PORT });
const clients = [];

wss.on('connection', ws => {
    clients.push(ws);
    console.log('New dashboard connected');
    ws.on('close', () => {
        const idx = clients.indexOf(ws);
        if (idx>=0) clients.splice(idx,1);
    });
});

// Broadcast utility
function broadcast(event){
    const msg = JSON.stringify(event);
    clients.forEach(c=>c.readyState===WebSocket.OPEN && c.send(msg));
}

// ---------------------------
// Spawn local AI binary
// ---------------------------
const BIN_PATH = process.env.BIN_PATH || path.resolve(process.env.HOME,'bin');

const aiProc = spawn(path.resolve(BIN_PATH,'ai'), [], { stdio:['ignore','pipe','pipe'] });
aiProc.stdout.on('data', data=>{
    data.toString().split('\n').forEach(line=>{
        if(line.trim()){
            try { broadcast(JSON.parse(line)) }
            catch(e){ console.error('AI JSON parse error:', e,line) }
        }
    });
});
aiProc.stderr.on('data', data=>console.error('[AI ERR]', data.toString()));

// ---------------------------
// Spawn NFT/rooting binary
// ---------------------------
const phProc = spawn(path.resolve(BIN_PATH,'ph'), [], { stdio:['ignore','pipe','pipe'] });
phProc.stdout.on('data', data=>{
    data.toString().split('\n').forEach(line=>{
        if(line.trim()){
            try { broadcast(JSON.parse(line)) }
            catch(e){ console.error('PH JSON parse error:', e,line) }
        }
    });
});
phProc.stderr.on('data', data=>console.error('[PH ERR]', data.toString()));

// ---------------------------
// Clean exit
// ---------------------------
process.on('SIGINT', ()=>{
    console.log('Shutting down bridge...');
    aiProc.kill();
    phProc.kill();
    wss.close();
    process.exit();
});

console.log(`AI Bridge running. WebSocket on ws://localhost:${PORT}`);
