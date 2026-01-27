#!/usr/bin/env node

import { SentenceTransformer } from 'sentence-transformers';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite3';
import crypto from 'crypto';
import fs from 'fs';

async function main() {
    // Read text from stdin
    let text = '';
    process.stdin.setEncoding('utf8');
    
    for await (const chunk of process.stdin) {
        text += chunk;
    }
    
    if (!text.trim()) {
        console.error('No text provided to vectorize');
        process.exit(1);
    }
    
    // Generate hashes
    const md5 = crypto.createHash('md5').update(text).digest('hex');
    const sha256 = crypto.createHash('sha256').update(text).digest('hex');
    
    try {
        // Initialize sentence transformer
        const model = new SentenceTransformer('all-MiniLM-L6-v2');
        const embedding = await model.encode(text);
        
        // Convert to buffer for storage
        const vectorBuffer = Buffer.from(embedding);
        
        // Store in SQLite
        const db = await open({
            filename: 'memory/vectors.db',
            driver: sqlite3.Database
        });
        
        await db.run(`
            CREATE TABLE IF NOT EXISTS vectors (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                md5 TEXT UNIQUE NOT NULL,
                sha256 TEXT NOT NULL,
                vector BLOB NOT NULL,
                text TEXT NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        `);
        
        await db.run(
            `INSERT OR REPLACE INTO vectors (md5, sha256, vector, text) VALUES (?, ?, ?, ?)`,
            [md5, sha256, vectorBuffer, text]
        );
        
        await db.close();
        
        // Output result
        console.log(JSON.stringify({
            status: 'success',
            md5,
            sha256,
            vector_dimensions: embedding.length,
            text_preview: text.substring(0, 100) + '...'
        }));
        
    } catch (error) {
        console.error('Vectorization error:', error);
        console.log(JSON.stringify({
            status: 'error',
            error: error.message,
            md5,
            sha256
        }));
        process.exit(1);
    }
}

main().catch(console.error);