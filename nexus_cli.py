#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import requests
import sqlite3
from typing import List, Dict, Any, Optional
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax
from rich.live import Live
from rich.table import Table
import typer

app = typer.Typer()
console = Console()

# --- Configuration ---
OLLAMA_URL = "http://localhost:11434/api/chat"
DEFAULT_MODEL = "glm-4.7:cloud"
MEMORY_DB = "ai/.db/ai_memory.db"

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
            res = TOOLS[tool_name](**args)
            results.append({"tool": tool_name, "result": res})
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

TOOLS = {
    "read_file": read_file,
    "write_file": write_file,
    "list_files": list_files,
    "rest_call": rest_call,
    "soap_call": soap_call,
    "db_query": db_query,
    "execute_bash": execute_bash,
    "batch_process": batch_process
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
            "description": "Execute a SQL query",
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
            "stream": False
        }
        
        try:
            response = requests.post(OLLAMA_URL, json=payload)
            response.raise_for_status()
            res_json = response.json()
            content = res_json['message']['content']
        except Exception as e:
            console.print(f"[bold red]Error communicating with Ollama:[/bold red] {e}")
            return

        # Check if it's a tool call
        try:
            clean_content = content.strip()
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
                messages.append({"role": "assistant", "content": content})
                messages.append({"role": "user", "content": f"Tool result: {result}"})
                continue # Continue the loop to let the model finish
        except (json.JSONDecodeError, TypeError):
            pass

        # If not a tool call or finished tool execution
        console.print(Panel(content, title="NEXUS Response", border_style="magenta"))
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

if __name__ == "__main__":
    app()
