#!/usr/bin/env bash
# SYSOP AI Agent – Bulletproof Headless Installer
set -euo pipefail

echo "[+] Starting SYSOP AI Agent installer..."

# --- 1. System dependencies ---
echo "[+] Installing system packages..."
if command -v apt >/dev/null 2>&1; then
    sudo apt update -y
    sudo apt install -y python3 python3-venv python3-pip git curl wget nodejs build-essential
elif command -v brew >/dev/null 2>&1; then
    brew update
    brew install python git curl wget node
else
    echo "[!] No apt/brew found. Install dependencies manually."
    exit 1
fi

# --- 2. Node.js / PM2 ---
if ! command -v pm2 >/dev/null 2>&1; then
    npm install -g pm2
fi

# --- 3. Python virtual environment ---
VENV_DIR="$HOME/.sysop_ai_env"
python3 -m venv "$VENV_DIR"

# ⚡ Fix permissions to prevent Errno 13
chown -R $(whoami):$(whoami) "$VENV_DIR"
chmod +x "$VENV_DIR/bin/activate"

# Activate venv
source "$VENV_DIR/bin/activate"

# Install Python packages
pip install --upgrade pip
pip install prompt_toolkit pygments jmespath pyyaml

# --- 4. jome-cli installation (headless-safe, pure Python) ---
mkdir -p "$HOME/bin"
cat > "$HOME/bin/jome-cli" <<'EOF'
#!/usr/bin/env python3
import sys, subprocess, json, os, yaml
from pygments import highlight
from pygments.lexers import JsonLexer, YamlLexer
from pygments.formatters import TerminalFormatter

# Headless-safe REPL
def is_tty():
    try:
        return os.isatty(sys.stdin.fileno())
    except:
        return False

if is_tty():
    from prompt_toolkit import PromptSession
    session = PromptSession()
else:
    # Fallback REPL for non-TTY
    def input_fallback(prompt):
        print(prompt, end='', flush=True)
        return sys.stdin.readline().rstrip('\n')
    session = type('DummySession', (), {'prompt': input_fallback})()

# Interactive models only
INTERACTIVE_MODELS = ["2244:latest","code:latest","deepseek-r1:1.5b"]
MODEL = "2244:latest"

data = {}
current_file = None
commands = ['load','view','query','set','delete','merge','convert','explain','suggest','help','quit','exit']

def pretty_print(d, fmt='json'):
    s = json.dumps(d, indent=2) if fmt=='json' else yaml.safe_dump(d, default_flow_style=False)
    print(highlight(s, JsonLexer() if fmt=='json' else YamlLexer(), TerminalFormatter()))

def run_ai(prompt):
    try:
        out = subprocess.check_output(['ollama','run',MODEL,'--prompt',prompt])
        print(out.decode())
    except subprocess.CalledProcessError as e:
        print("[!] Ollama AI call failed (planner models ignored):", e)

# Main REPL loop
while True:
    try:
        cmd = session.prompt("jome> ").strip()
    except EOFError:
        print("\nExiting REPL.")
        break
    if not cmd: continue
    parts = cmd.split()
    c = parts[0].lower()
    if c in ['quit','exit']: break
    elif c=='help': print("Commands:", ", ".join(commands))
    elif c=='load' and len(parts)==2:
        current_file = parts[1]
        with open(current_file) as f:
            if current_file.endswith(('.yaml','.yml')):
                data.update(yaml.safe_load(f))
            else:
                data.update(json.load(f))
        print(f"[+] Loaded {current_file}")
    elif c=='view': pretty_print(data)
    elif c=='query' and len(parts)>=2:
        import jmespath
        expr = " ".join(parts[1:])
        pretty_print(jmespath.search(expr,data))
    elif c=='explain' and current_file: run_ai(open(current_file).read())
    elif c=='suggest' and current_file: run_ai("Suggest improvements for the following config:\n"+open(current_file).read())
    else:
        print(f"[!] Unknown command: {c}")
EOF

chmod +x "$HOME/bin/jome-cli"
echo "[+] jome-cli installed at $HOME/bin/jome-cli"

# --- 5. Environment variables ---
echo 'export QT_QPA_PLATFORM=offscreen' >> ~/.bashrc
echo 'export OLLAMA_HOME="$HOME/.ollama"' >> ~/.bashrc
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# --- 6. PM2 ecosystem ---
mkdir -p ~/sysop_pm2
cat > ~/sysop_pm2/ecosystem.config.js <<'EOF'
module.exports = {
  apps: [
    {
      name: "jome-cli",
      script: "/data/data/com.termux/files/home/bin/jome-cli",
      interpreter: "bash",
      autorestart: true,
      watch: false,
      env: {
        QT_QPA_PLATFORM: "offscreen",
        OLLAMA_HOME: "/data/data/com.termux/files/home/.ollama",
        PATH: "/data/data/com.termux/files/home/bin:$PATH"
      }
    },
    {
      name: "ollama-2244",
      script: "ollama",
      args: "run 2244:latest",
      autorestart: true,
      watch: false,
      env: {
        QT_QPA_PLATFORM: "offscreen",
        OLLAMA_HOME: "/data/data/com.termux/files/home/.ollama",
        PATH: "/data/data/com.termux/files/home/bin:$PATH"
      }
    }
  ]
};
EOF

pm2 start ~/sysop_pm2/ecosystem.config.js
pm2 save

# --- 7. Termux:Boot integration ---
BOOT_SCRIPT="$HOME/.termux/boot/sysop_boot.sh"
mkdir -p $(dirname "$BOOT_SCRIPT")
cat > "$BOOT_SCRIPT" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
sleep 10
proot-distro login debian --user loop -- pm2 resurrect
EOF
chmod +x "$BOOT_SCRIPT"

echo "[+] Termux:Boot auto-start configured"
echo "[+] Installation complete. Run 'jome-cli' to start headless-safe REPL."
