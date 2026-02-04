import os
import ast
import json
import subprocess
import sys

def check_python(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            source = f.read()
        compile(source, filepath, 'exec')
        return None
    except SyntaxError as e:
        return f"Python Syntax Error: {e}"
    except Exception as e:
        return f"Error reading/parsing: {e}"

def check_json(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            json.load(f)
        return None
    except json.JSONDecodeError as e:
        return f"JSON Syntax Error: {e}"
    except Exception as e:
        return f"Error reading: {e}"

def check_bash(filepath):
    try:
        # Check for syntax errors only
        result = subprocess.run(['bash', '-n', filepath], capture_output=True, text=True)
        if result.returncode != 0:
            return f"Bash Syntax Error: {result.stderr.strip()}"
        return None
    except Exception as e:
        return f"Error checking bash: {e}"

def check_js(filepath):
    try:
        # Node check syntax
        result = subprocess.run(['node', '-c', filepath], capture_output=True, text=True)
        if result.returncode != 0:
            return f"JS Syntax Error: {result.stderr.strip()}"
        return None
    except Exception as e:
        return f"Error checking JS: {e}"

def scan_dir(start_dir):
    issues = []
    for root, dirs, files in os.walk(start_dir):
        # Skip hidden directories
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        for file in files:
            filepath = os.path.join(root, file)
            ext = os.path.splitext(file)[1].lower()
            
            error = None
            if ext == '.py':
                error = check_python(filepath)
            elif ext == '.json':
                error = check_json(filepath)
            elif ext == '.sh':
                error = check_bash(filepath)
            elif ext == '.js' or ext == '.mjs':
                error = check_js(filepath)
            
            if error:
                issues.append((filepath, error))
                print(f"[FAIL] {filepath}: {error}")
            # else:
            #     print(f"[OK] {filepath}")

    return issues

if __name__ == "__main__":
    print("Scanning for syntax errors...")
    found_issues = scan_dir('.')
    print(f"\nFound {len(found_issues)} files with errors.")
