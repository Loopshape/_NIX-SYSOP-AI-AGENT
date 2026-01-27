#!/usr/bin/env bash
set -euo pipefail

echo "[+] Starting SYSOP AI enhanced CLI hub installer..."

# --- 1. System dependencies ---
if command -v apt >/dev/null 2>&1; then
    sudo apt update -y
    sudo apt install -y python3 python3-venv python3-pip jq xdotool xclip git curl wget nodejs npm build-essential
elif command -v brew >/dev/null 2>&1; then
    brew update
    brew install python jq xdotool node xclip
fi

# --- 2. Node.js / PM2 ---
if ! command -v pm2 >/dev/null 2>&1; then
    npm install -g pm2
fi

# --- 3. Python virtual environment ---
VENV_DIR="$HOME/.sysop_ai_env"
python3 -m venv "$VENV_DIR"
chown -R $(whoami):$(whoami) "$VENV_DIR"
chmod +x "$VENV_DIR/bin/activate"
source "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install prompt_toolkit pygments jmespath pyyaml

# --- 4. Enhanced jome-cli installation ---
mkdir -p ~/bin
cat > ~/bin/jome-cli <<'EOF'
#!/usr/bin/env python3
import os, sys, subprocess, json, yaml
from pygments import highlight
from pygments.lexers import JsonLexer, YamlLexer
from pygments.formatters import TerminalFormatter

try:
    from prompt_toolkit import PromptSession
    session = PromptSession()
except:
    def session_prompt(prompt):
        print(prompt, end='', flush=True)
        return sys.stdin.readline().rstrip('\n')
    session = type('DummySession', (), {'prompt': session_prompt})()

MODEL = "2244:latest"
HISTORY_FILE = os.path.expanduser("~/.jome_cli_history.json")
os.makedirs(os.path.dirname(HISTORY_FILE), exist_ok=True)

if os.path.exists(HISTORY_FILE):
    with open(HISTORY_FILE) as f:
        history = json.load(f)
else:
    history = []

def save_history(cmd):
    history.append(cmd)
    with open(HISTORY_FILE, "w") as f:
        json.dump(history, f, indent=2)

def pretty_print(data, fmt='json'):
    s = json.dumps(data, indent=2) if fmt=='json' else yaml.safe_dump(data, default_flow_style=False)
    print(highlight(s, JsonLexer() if fmt=='json' else YamlLexer(), TerminalFormatter()))

def run_ai(prompt):
    try:
        out = subprocess.check_output(['ollama','run',MODEL,'--prompt',prompt])
        print(out.decode())
    except subprocess.CalledProcessError as e:
        print("[!] AI call failed:", e)

def copy_to_clipboard(text):
    try:
        subprocess.run(['xclip','-selection','clipboard'], input=text.encode(), check=True)
        print("[+] Output copied to clipboard")
    except Exception:
        print("[!] Clipboard copy failed. Install xclip.")

commands = ['load','view','query','set','delete','merge','convert','explain','suggest','help','quit','exit','history','clip']

data = {}
current_file = None

while True:
    cmd = session.prompt("jome> ").strip()
    if not cmd: continue
    save_history(cmd)
    parts = cmd.split()
    c = parts[0].lower()

    if c in ['quit','exit']: break
    elif c=='help': print("Commands:", ", ".join(commands))
    elif c=='history': print("\n".join(history))
    elif c=='clip' and len(parts)>=2:
        copy_to_clipboard(" ".join(parts[1:]))
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
    elif c=='xdotool' or cmd.startswith("xdotool "):
        os.system(cmd)
    elif c=='jq' or cmd.startswith("jq "):
        os.system(cmd)
    elif c=='ai' and len(parts)>=2:
        run_ai(" ".join(parts[1:]))
    elif c=='explain' and current_file:
        run_ai(open(current_file).read())
    elif c=='suggest' and current_file:
        run_ai("Suggest improvements for the following config:\n"+open(current_file).read())
    else:
        print(f"[!] Unknown command: {c}")
EOF

chmod +x ~/bin/jome-cli
echo "[+] Enhanced jome-cli installed at ~/bin/jome-cli"

# --- 5. Environment variables ---
echo 'export QT_QPA_PLATFORM=offscreen' >> ~/.bashrc
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
      env: { QT_QPA_PLATFORM: "offscreen", PATH: "/data/data/com.termux/files/home/bin:$PATH" }
    }
  ]
};
EOF

pm2 start ~/sysop_pm2/ecosystem.config.js
pm2 save

echo "[+] Installation complete. Run 'jome-cli' to start your enhanced CLI hub."
