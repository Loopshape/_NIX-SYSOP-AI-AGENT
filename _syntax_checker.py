import os
import ast
import json
import subprocess
import sys

# Directories to skip
EXCLUDE_DIRS = {'node_modules', '.git', '.ai_backups', '.snapshots', '__pycache__', 'dist', 'build'}

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
        # Check for syntax errors only using bash -n
        result = subprocess.run(['bash', '-n', filepath], capture_output=True, text=True)
        if result.returncode != 0:
            return f"Bash Syntax Error: {result.stderr.strip()}"
        return None
    except Exception as e:
        return f"Error checking bash: {e}"

def check_js(filepath):
    try:
        # Node check syntax using node -c
        # Note: This requires Node.js to be installed.
        result = subprocess.run(['node', '-c', filepath], capture_output=True, text=True)
        if result.returncode != 0:
            return f"JS Syntax Error: {result.stderr.strip()}"
        return None
    except Exception as e:
        # If node is missing, we might want to just skip or log a warning
        return f"Error checking JS (Node.js might be missing): {e}"

def scan_dir(start_dir):
    issues = []
    for root, dirs, files in os.walk(start_dir):
        # Skip excluded directories in-place
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith('.')]
        
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
            elif ext in ('.js', '.mjs', '.cjs'):
                error = check_js(filepath)
            
            if error:
                issues.append((filepath, error))
                print(f"[FAIL] {filepath}: {error}")
            # else:
            #     print(f"[OK] {filepath}")

    return issues

if __name__ == "__main__":
    target = '.' if len(sys.argv) < 2 else sys.argv[1]
    print(f"Scanning {os.path.abspath(target)} for syntax errors...")
    found_issues = scan_dir(target)
    print(f"\nScan complete. Found {len(found_issues)} files with errors.")
    if found_issues:
        sys.exit(1)
    else:
        sys.exit(0)