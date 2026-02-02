#!/usr/bin/env python3
import os
import sqlite3
import hashlib
import math
import time
import uuid
import ast
from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

console = Console()
DB_PATH = "ai/.db/ai_memory.db"

# --- Utils ---

def calculate_entropy(content: str) -> float:
    if not content: return 0.0
    prob = [float(content.count(c)) / len(content) for c in dict.fromkeys(list(content))]
    return -sum([p * math.log(p) / math.log(2.0) for p in prob])

def generate_hashes(content: str):
    sha256 = hashlib.sha256(content.encode('utf-8', errors='ignore')).hexdigest()
    md5 = hashlib.md5(content.encode('utf-8', errors='ignore')).hexdigest()
    return sha256, md5

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS project_index (
            path TEXT PRIMARY KEY,
            sha256 TEXT,
            md5 TEXT,
            entropy REAL,
            last_modified REAL,
            file_type TEXT,
            optimization_status TEXT,
            suggested_content TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    return conn

# --- Optimization Logic ---

def analyze_and_optimize(path, content):
    """
    Simple heuristic analysis.
    Returns (status, suggested_content_or_none)
    """
    ext = os.path.splitext(path)[1]
    suggestion = None
    status = "OPTIMAL"
    
    if ext == ".py":
        try:
            tree = ast.parse(content)
            # Check 1: Docstrings
            has_docstring = False
            if tree.body and isinstance(tree.body[0], ast.Expr) and isinstance(tree.body[0].value, ast.Str):
                has_docstring = True
            
            # Check 2: Print vs Logging (naive)
            has_print = "print(" in content
            
            optimizations = []
            if not has_docstring:
                optimizations.append("# TODO: Add module docstring")
            if has_print:
                optimizations.append("# OPTIMIZE: Consider using 'logging' instead of 'print'")
            
            if optimizations:
                status = "NEEDS_OPTIMIZATION"
                # Prepend suggestions to content
                header = "\n".join(optimizations) + "\n"
                suggestion = header + content
                
        except SyntaxError:
            status = "SYNTAX_ERROR"
    
    return status, suggestion

# --- Main Indexer ---

def scan_and_index():
    conn = init_db()
    c = conn.cursor()
    
    root_dir = "."
    ignore_dirs = {".git", "node_modules", "venv", "__pycache__", ".db", ".vscode", "dist"}
    
    indexed_count = 0
    optimized_count = 0
    
    table = Table(title="Recursive Project Scan")
    table.add_column("File", style="cyan")
    table.add_column("Status", style="magenta")
    table.add_column("Entropy", style="green")

    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Filter directories
        dirnames[:] = [d for d in dirnames if d not in ignore_dirs]
        
        for f in filenames:
            full_path = os.path.join(dirpath, f)
            if full_path.startswith("./"):
                full_path = full_path[2:]
                
            try:
                # Read file
                try:
                    with open(full_path, 'r', encoding='utf-8') as file:
                        content = file.read()
                except UnicodeDecodeError:
                    # Skip binary files
                    continue
                
                # Metrics
                sha, md5 = generate_hashes(content)
                entropy = calculate_entropy(content)
                mtime = os.path.getmtime(full_path)
                
                # Optimize
                opt_status, suggestion = analyze_and_optimize(full_path, content)
                
                # DB Upsert
                c.execute("""
                    INSERT OR REPLACE INTO project_index 
                    (path, sha256, md5, entropy, last_modified, file_type, optimization_status, suggested_content, timestamp)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (full_path, sha, md5, entropy, mtime, os.path.splitext(f)[1], opt_status, suggestion, datetime.now()))
                
                table.add_row(full_path, opt_status, f"{entropy:.2f}")
                
                indexed_count += 1
                if opt_status != "OPTIMAL":
                    optimized_count += 1
                    
            except Exception as e:
                console.print(f"[red]Error processing {full_path}: {e}[/red]")

    conn.commit()
    conn.close()
    
    console.print(table)
    console.print(Panel(f"Scan Complete.\nIndexed: {indexed_count}\nOptimized Candidates: {optimized_count}", title="NEXUS Indexer", border_style="green"))

if __name__ == "__main__":
    scan_and_index()
