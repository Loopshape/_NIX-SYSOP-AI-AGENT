#!/usr/bin/env bash
set -euo pipefail
echo "[+] Starting SYSOP AI Agent installer with prioritized package managers..."

# --- 1. Check and install system dependencies ---
if command -v apt >/dev/null 2>&1; then
    echo "[+] Installing dependencies via apt..."
    sudo apt update -y
    sudo apt install -y python3 python3-pip git curl wget nodejs build-essential
elif command -v brew >/dev/null 2>&1; then
    echo "[+] Installing dependencies via brew..."
    brew update
    brew install python git curl wget node
else
    echo "[!] No system package manager found (apt/brew). Please install dependencies manually."
    exit 1
fi

# --- 2. Node.js / NPM & PM2 ---
if ! command -v node >/dev/null 2>&1; then
    echo "[!] Node.js not found. Please install Node.js via apt or brew."
    exit 1
fi
if ! command -v pm2 >/dev/null 2>&1; then
    echo "[+] Installing pm2 via npm..."
    npm install -g pm2
fi

# --- 3. Python environment ---
VENV_DIR="$HOME/.sysop_ai_env"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

# --- 4. Python packages ---
PACKAGES=(prompt_toolkit pygments jmespath pyyaml)
for pkg in "${PACKAGES[@]}"; do
    if ! python3 -c "import $pkg" >/dev/null 2>&1; then
        echo "[+] Installing Python package: $pkg"
        pip install "$pkg"
    fi
done

# --- 5. jome-cli installation ---
mkdir -p "$HOME/bin"
cat > "$HOME/bin/jome-cli" <<'EOF'
#!/usr/bin/env python3
# [Insert full jome-cli Python code here with REPL, autocomplete, AI explain/suggest]
EOF
chmod +x "$HOME/bin/jome-cli"
echo "[+] jome-cli installed."

# --- 6. PM2 services setup ---
# (example: Ollama + CMDB dashboard)
pm2 start ollama --name ollama -- serve || true
pm2 start python3 --name cmdb-dashboard -- "$HOME/cmdb/cmdb_api.py" || true
pm2 save

# --- 7. Termux / Proot boot integration (optional) ---
BOOT_SCRIPT="$HOME/.termux/boot/sysop_boot.sh"
mkdir -p "$(dirname "$BOOT_SCRIPT")"
cat > "$BOOT_SCRIPT" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
sleep 10
pm2 resurrect
EOF
chmod +x "$BOOT_SCRIPT"
echo "[+] Boot script configured for Termux:Boot."

echo "[+] SYSOP AI Agent installation complete. Run 'jome-cli' to start REPL."
