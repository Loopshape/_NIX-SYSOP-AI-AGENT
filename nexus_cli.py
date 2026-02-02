#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import requests
import sqlite3
import hashlib
import glob
import aiohttp
import socket
from typing import List, Dict, Any, Optional
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax
from rich.live import Live
from rich.table import Table
import typer

app = typer.Typer()
console = Console()

# --- Connectivity Check ---

def check_connectivity(host="8.8.8.8", port=53, timeout=3):
    """Checks for active internet connection."""
    try:
        socket.setdefaulttimeout(timeout)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
        return True
    except socket.error:
        return False

# --- Configuration ---
IS_ONLINE = check_connectivity()
OLLAMA_URL = "http://localhost:11434/api/chat"
DEFAULT_MODEL = "glm-4.7:cloud" if IS_ONLINE else "llama3.2:3b"
MEMORY_DB = "ai/.db/ai_memory.db"
NOTES_FILE = "ai_notes.json"

if IS_ONLINE:
    console.print(f"[bold green]ONLINE MODE DETECTED[/bold green] - Default Model: {DEFAULT_MODEL}")
else:
    console.print(f"[bold red]OFFLINE MODE DETECTED[/bold red] - Default Model: {DEFAULT_MODEL}")

# --- Toolbelt Implementation ---

def soap_call(url: str, action: str, body: str) -> str:
    """Performs a SOAP call."""
    headers = {
        "Content-Type": "text/xml; charset=utf-8",
        "SOAPAction": action
    }
    try:
        res = requests.post(url, data=body, headers=headers, timeout=15)
        return f"Status: {res.status_code}\nResponse: {res.text}"
    except Exception as e:
        return f"SOAP call failed: {e}"

def batch_process(tasks: List[Dict[str, Any]]) -> str:
    """Processes multiple tools in batch."""
    results = []
    for task in tasks:
        tool_name = task.get("tool")
        args = task.get("args", {})
        if tool_name in TOOLS and tool_name != "batch_process":
            try:
                res = TOOLS[tool_name](**args)
                results.append({"tool": tool_name, "result": res})
            except Exception as e:
                results.append({"tool": tool_name, "error": str(e)})
        else:
            results.append({"tool": tool_name, "error": "Unknown or restricted tool"})
    return json.dumps(results, indent=2)

def read_file(path: str) -> str:
    """Reads a file and returns its content."""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        return f"Error reading file: {e}"

def write_file(path: str, content: str) -> str:
    """Writes content to a file."""
    try:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        return f"File written successfully to {path}"
    except Exception as e:
        return f"Error writing file: {e}"

def list_files(path: str = ".") -> str:
    """Lists files in a directory."""
    try:
        files = os.listdir(path)
        return "\n".join(files)
    except Exception as e:
        return f"Error listing files: {e}"

def rest_call(method: str, url: str, data: Optional[Dict] = None, headers: Optional[Dict] = None) -> str:
    """Performs a REST API call."""
    try:
        res = requests.request(method, url, json=data, headers=headers, timeout=10)
        return f"Status: {res.status_code}\nResponse: {res.text}"
    except Exception as e:
        return f"REST call failed: {e}"

def db_query(query: str) -> str:
    """Executes a SQL query on the local memory database."""
    try:
        conn = sqlite3.connect(MEMORY_DB)
        cursor = conn.cursor()
        cursor.execute(query)
        if query.strip().upper().startswith("SELECT"):
            rows = cursor.fetchall()
            return json.dumps(rows, indent=2)
        else:
            conn.commit()
            return f"Query executed. Rows affected: {cursor.rowcount}"
    except Exception as e:
        return f"Database error: {e}"
    finally:
        if 'conn' in locals(): conn.close()

def execute_bash(command: str) -> str:
    """Executes a bash command."""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
        return f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
    except Exception as e:
        return f"Bash execution failed: {e}"

# --- New Tools ---

def fetch_url(url: str) -> str:
    """Fetches content from a URL."""
    try:
        res = requests.get(url, timeout=10)
        return f"Status: {res.status_code}\nContent: {res.text[:2000]}..." # Truncate for safety
    except Exception as e:
        return f"URL fetch failed: {e}"

def compute_hash(content: str, algorithm: str = "sha256") -> str:
    """Computes hash of content."""
    try:
        if algorithm not in hashlib.algorithms_available:
            return f"Algorithm {algorithm} not available."
        h = hashlib.new(algorithm)
        h.update(content.encode('utf-8'))
        return h.hexdigest()
    except Exception as e:
        return f"Hashing failed: {e}"

def git_ops(command: str, path: str = ".") -> str:
    """Performs git operations."""
    if not command.startswith("git "):
        command = "git " + command
    return execute_bash(f"cd {path} && {command}")

def search_files(pattern: str, path: str = ".") -> str:
    """Searches for files matching a glob pattern."""
    try:
        files = glob.glob(os.path.join(path, pattern), recursive=True)
        return "\n".join(files[:50]) # Limit to 50 results
    except Exception as e:
        return f"Search failed: {e}"

def manage_notes(action: str, title: str = "", content: str = "") -> str:
    """Manages a simple JSON-based notebook."""
    try:
        notes = {}
        if os.path.exists(NOTES_FILE):
            with open(NOTES_FILE, 'r') as f:
                notes = json.load(f)
        
        if action == "add":
            notes[title] = {"content": content, "timestamp": str(os.path.getmtime(NOTES_FILE) if os.path.exists(NOTES_FILE) else 0)}
            with open(NOTES_FILE, 'w') as f:
                json.dump(notes, f, indent=2)
            return f"Note '{title}' added."
        elif action == "read":
            return notes.get(title, {}).get("content", "Note not found.")
        elif action == "list":
            return "\n".join(notes.keys())
        elif action == "delete":
            if title in notes:
                del notes[title]
                with open(NOTES_FILE, 'w') as f:
                    json.dump(notes, f, indent=2)
                return f"Note '{title}' deleted."
            return "Note not found."
        else:
            return "Invalid action. Use add, read, list, delete."
    except Exception as e:
        return f"Note operation failed: {e}"

def seed_memory(fact: str, category: str = "general") -> str:
    """Seeds the memory database with a fact."""
    try:
        conn = sqlite3.connect(MEMORY_DB)
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE IF NOT EXISTS facts (id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, fact TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)")
        cursor.execute("INSERT INTO facts (category, fact) VALUES (?, ?)", (category, fact))
        conn.commit()
        return "Memory seeded successfully."
    except Exception as e:
        return f"Memory seed failed: {e}"
    finally:
        if 'conn' in locals(): conn.close()

def analyze_code(path: str) -> str:
    """Performs basic static analysis on a file."""
    try:
        if not os.path.exists(path):
            return "File not found."
        
        content = read_file(path)
        lines = content.split('\n')
        
        analysis = {
            "path": path,
            "size": len(content),
            "lines": len(lines),
            "todo_count": content.lower().count("todo"),
            "fixme_count": content.lower().count("fixme"),
            "imports": [l for l in lines if l.strip().startswith("import ") or l.strip().startswith("from ")],
            "functions": [l.strip() for l in lines if "def " in l or "function " in l]
        }
        return json.dumps(analysis, indent=2)
    except Exception as e:
        return f"Analysis failed: {e}"

TOOLS = {
    "read_file": read_file,
    "write_file": write_file,
    "list_files": list_files,
    "rest_call": rest_call,
    "soap_call": soap_call,
    "db_query": db_query,
    "execute_bash": execute_bash,
    "batch_process": batch_process,
    "fetch_url": fetch_url,
    "compute_hash": compute_hash,
    "git_ops": git_ops,
    "search_files": search_files,
    "manage_notes": manage_notes,
    "seed_memory": seed_memory,
    "analyze_code": analyze_code
}

# --- Orchestration ---

def get_tool_schemas():
    return [
        {
            "name": "read_file",
            "description": "Read content from a file",
            "parameters": {"path": "string"}
        },
        {
            "name": "write_file",
            "description": "Write content to a file",
            "parameters": {"path": "string", "content": "string"}
        },
        {
            "name": "list_files",
            "description": "List files in a directory",
            "parameters": {"path": "string"}
        },
        {
            "name": "rest_call",
            "description": "Perform a REST API call",
            "parameters": {"method": "string", "url": "string", "data": "object", "headers": "object"}
        },
        {
            "name": "soap_call",
            "description": "Perform a SOAP call",
            "parameters": {"url": "string", "action": "string", "body": "string"}
        },
        {
            "name": "db_query",
            "description": "Execute a SQL query on memory DB",
            "parameters": {"query": "string"}
        },
        {
            "name": "execute_bash",
            "description": "Run a bash command",
            "parameters": {"command": "string"}
        },
        {
            "name": "batch_process",
            "description": "Process multiple tool calls in one go",
            "parameters": {"tasks": "list of objects with 'tool' and 'args'"}
        },
        {
            "name": "fetch_url",
            "description": "Fetch content from a URL",
            "parameters": {"url": "string"}
        },
        {
            "name": "compute_hash",
            "description": "Compute hash of content",
            "parameters": {"content": "string", "algorithm": "string (optional)"}
        },
        {
            "name": "git_ops",
            "description": "Run git commands",
            "parameters": {"command": "string", "path": "string (optional)"}
        },
        {
            "name": "search_files",
            "description": "Search for files using glob patterns",
            "parameters": {"pattern": "string", "path": "string (optional)"}
        },
        {
            "name": "manage_notes",
            "description": "Manage personal notes",
            "parameters": {"action": "add/read/list/delete", "title": "string", "content": "string"}
        },
        {
            "name": "seed_memory",
            "description": "Save a fact to long-term memory",
            "parameters": {"fact": "string", "category": "string (optional)"}
        },
        {
            "name": "analyze_code",
            "description": "Analyze code structure and stats",
            "parameters": {"path": "string"}
        }
    ]

async def chat_with_nexus(prompt: str, model: str = DEFAULT_MODEL):
    system_prompt = f"""
You are NEXUS-CLI, an advanced AI agent. 
You have access to tools that can interact with the local file system, databases, and network.
Tools available: {json.dumps(get_tool_schemas())}

If you need to use a tool, respond ONLY with a JSON object in this format:
{{"tool": "tool_name", "args": {{"arg1": "val1"}}}}

If you want to generate code or provide a text response, just respond normally.
Focus on being helpful and efficient.
"""
    
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": prompt}
    ]

    while True:
        payload = {
            "model": model,
            "messages": messages,
            "stream": True  # Enable streaming
        }
        
        full_content = ""
        console.print(f"[bold magenta]NEXUS ({model}):[/bold magenta] ", end="")
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(OLLAMA_URL, json=payload) as response:
                    response.raise_for_status()
                    
                    async for line in response.content:
                        if line:
                            try:
                                body = json.loads(line)
                                chunk = body.get("message", {}).get("content", "")
                                if chunk:
                                    console.print(chunk, end="")
                                    full_content += chunk
                                if body.get("done", False):
                                    break
                            except:
                                pass
            console.print() # Newline after stream
            
        except Exception as e:
            console.print(f"\n[bold red]Error communicating with Ollama:[/bold red] {e}")
            return

        # Check if it's a tool call
        try:
            clean_content = full_content.strip()
            if clean_content.startswith("```json"):
                clean_content = clean_content.split("```json")[1].split("```")[0].strip()
            elif clean_content.startswith("```"):
                clean_content = clean_content.split("```")[1].split("```")[0].strip()
                
            tool_call = json.loads(clean_content)
            if "tool" in tool_call and tool_call["tool"] in TOOLS:
                tool_name = tool_call["tool"]
                args = tool_call.get("args", {})
                
                console.print(f"[bold blue]Executing Tool:[/bold blue] {tool_name}({args})")
                result = TOOLS[tool_name](**args)
                console.print(f"[bold green]Result:[/bold green] {result[:500]}...")
                
                # Feed the result back to the model
                messages.append({"role": "assistant", "content": full_content})
                messages.append({"role": "user", "content": f"Tool result: {result}"})
                continue # Continue the loop to let the model finish
        except (json.JSONDecodeError, TypeError):
            pass

        break

@app.command()
def prompt(text: str, model: str = DEFAULT_MODEL):
    """Send a natural language prompt to NEXUS."""
    import asyncio
    asyncio.run(chat_with_nexus(text, model))

@app.command()
def shell():
    """Enter interactive REPL mode."""
    console.print("[bold cyan]Welcome to NEXUS-CLI Shell[/bold cyan]")
    while True:
        try:
            user_input = console.input("[bold yellow]NEXUS > [/bold yellow]")
            if user_input.lower() in ["exit", "quit"]:
                break
            import asyncio
            asyncio.run(chat_with_nexus(user_input))
        except KeyboardInterrupt:
            break

@app.command()
def build(requirement: str, output_path: str, model: str = DEFAULT_MODEL):
    """Generate code for a specific requirement and save it to a file."""
    system_prompt = f"""
You are NEXUS-BUILDER, an expert software architect.
Your task is to generate high-quality, production-ready code based on the user's requirements.
Respond ONLY with the source code. No preamble, no explanation, no markdown blocks.
"""
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": requirement}
        ],
        "stream": False
    }
    
    console.print(f"[bold cyan]Generating code for:[/bold cyan] {requirement}")
    try:
        response = requests.post(OLLAMA_URL, json=payload)
        response.raise_for_status()
        content = response.json()['message']['content']
        
        # Strip potential markdown if the model didn't follow instructions
        if content.startswith("```"):
            content = "\n".join(content.split("\n")[1:-1])
            
        with open(output_path, 'w') as f:
            f.write(content)
        console.print(f"[bold green]Code saved to {output_path}[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Build failed:[/bold red] {e}")

@app.command()
def index():
    """Recursively scans and indexes the project into the persistent DB."""
    console.print("[bold cyan]Starting Recursive Project Scan...[/bold cyan]")
    try:
        # Run external script to keep CLI lightweight
        subprocess.run([sys.executable, "nexus_indexer.py"], check=True)
    except Exception as e:
        console.print(f"[bold red]Indexing Failed:[/bold red] {e}")

@app.command()
def suggestions():
    """Lists optimization suggestions found by the indexer."""
    try:
        conn = sqlite3.connect(MEMORY_DB)
        c = conn.cursor()
        c.execute("SELECT path, optimization_status FROM project_index WHERE optimization_status != 'OPTIMAL'")
        rows = c.fetchall()
        
        if not rows:
            console.print("[green]No optimizations needed. Project is clean.[/green]")
            return

        table = Table(title="Optimization Candidates")
        table.add_column("File", style="cyan")
        table.add_column("Status", style="magenta")
        for r in rows:
            table.add_row(r[0], r[1])
        console.print(table)
        console.print("\nRun [bold yellow]nexus-cli optimize <file>[/bold yellow] to apply suggestions (Not implemented yet).")
        conn.close()
    except Exception as e:
        console.print(f"[red]Error reading DB: {e}[/red]")

if __name__ == "__main__":
    app()
