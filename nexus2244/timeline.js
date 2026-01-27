import fs from 'fs';
import crypto from 'crypto';

export class TimelineEngine {
    constructor(dbPath = 'memory/timeline.db') {
        this.dbPath = dbPath;
        this.ensureDatabase();
    }
    
    ensureDatabase() {
        if (!fs.existsSync(this.dbPath)) {
            fs.writeFileSync(this.dbPath, '');
        }
    }
    
    saveState(md5, data) {
        const entry = {
            md5,
            data,
            timestamp: Date.now(),
            hash: crypto.createHash('sha256')
                .update(JSON.stringify(data))
                .digest('hex')
        };
        
        fs.appendFileSync(
            this.dbPath,
            JSON.stringify(entry) + '\n'
        );
        
        return entry.hash;
    }
    
    replay(md5) {
        if (!fs.existsSync(this.dbPath)) {
            return [];
        }
        
        const content = fs.readFileSync(this.dbPath, 'utf8');
        return content
            .split('\n')
            .filter(line => line.trim())
            .map(line => JSON.parse(line))
            .filter(entry => entry.md5 === md5);
    }
    
    getBranch(md5) {
        if (!fs.existsSync(this.dbPath)) {
            return [];
        }
        
        const content = fs.readFileSync(this.dbPath, 'utf8');
        const entries = content
            .split('\n')
            .filter(line => line.trim())
            .map(line => JSON.parse(line));
        
        // Build tree structure
        const tree = [];
        const visited = new Set();
        
        function buildTree(currentMd5, depth = 0) {
            if (visited.has(currentMd5) || depth > 20) return [];
            
            visited.add(currentMd5);
            const children = entries.filter(e => e.data?.parent === currentMd5);
            
            return children.map(child => ({
                ...child,
                children: buildTree(child.md5, depth + 1)
            }));
        }
        
        return buildTree(md5);
    }
    
    calculateEntropy(md5) {
        const entries = this.replay(md5);
        if (entries.length === 0) return 0.0;
        
        // Calculate token diversity
        const allText = entries.map(e => e.data?.text || '').join(' ');
        const tokens = allText.split(/\s+/).filter(t => t.length > 0);
        
        if (tokens.length === 0) return 0.0;
        
        const tokenCounts = {};
        tokens.forEach(token => {
            tokenCounts[token] = (tokenCounts[token] || 0) + 1;
        });
        
        const total = tokens.length;
        let entropy = 0;
        
        Object.values(tokenCounts).forEach(count => {
            const probability = count / total;
            entropy -= probability * Math.log2(probability);
        });
        
        return entropy;
    }
}