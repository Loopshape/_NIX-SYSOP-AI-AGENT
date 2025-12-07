#!/usr/bin/env bash
# --------------------------------------------
# Nemodian 2244 Crew-Orchestrator Installer with dedicated 'ai' user
# --------------------------------------------

set -euo pipefail
IFS=$'\n\t'

BASE="$HOME/_"
AI_DIR="$BASE/ai_orchestrator"
WEB_DIR="$BASE/web"
CREW_DIR="$AI_DIR/crew"
RESULTS_DIR="$AI_DIR/results"
LOGS_DIR="$AI_DIR/logs"

# -------------------------------
# 1️⃣ Create ai user if not exists
# -------------------------------
if ! id -u ai >/dev/null 2>&1; then
    echo "Creating 'ai' user..."
    sudo useradd -m -s /bin/bash ai
    sudo usermod -aG sudo ai   # optional: give sudo if needed
fi

# -------------------------------
# 2️⃣ Create shared group aiaccess
# -------------------------------
if ! getent group aiaccess >/dev/null; then
    echo "Creating group 'aiaccess'..."
    sudo groupadd aiaccess
fi

# Add users to group
sudo usermod -aG aiaccess loop
sudo usermod -aG aiaccess ai

# -------------------------------
# 3️⃣ Create folder structure
# -------------------------------
echo "Creating directories..."
mkdir -p "$CREW_DIR" "$RESULTS_DIR" "$LOGS_DIR" "$WEB_DIR"

# -------------------------------
# 4️⃣ Create Python orchestrator
# -------------------------------
cat > "$CREW_DIR/ai_orchestrator.py" << 'EOF'
#!/usr/bin/env python3
import subprocess, hashlib, json, sys, time, concurrent.futures

AGENTS = [
    ("core","gemma3-1b"),
    ("loop","gemma3-1b"),
    ("wave","deepseek-coder"),
    ("coin","gemma3-1b"),
    ("code","deepseek-coder")
]

OUTPUT_DIR = "/home/loop/_/ai_orchestrator/results"

def run_ollama(agent_name, model, prompt):
    try:
        result = subprocess.run(["ollama","run",model],
                                input=prompt.encode("utf-8"),
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
                                timeout=120)
        tokens = result.stdout.decode("utf-8").strip()
        sha256 = hashlib.sha256(tokens.encode("utf-8")).hexdigest()
        md5 = hashlib.md5(tokens.encode("utf-8")).hexdigest()
        return {"agent":agent_name,"model":model,"tokens":tokens,"sha256":sha256,"md5":md5,"timestamp":time.time()}
    except Exception as e:
        return {"agent":agent_name,"error":str(e)}

def assemble_final(sorted_responses):
    merged = "\n\n".join([r["tokens"] for r in sorted_responses])
    html = f"""<!DOCTYPE html>
<html><head><meta charset='utf-8'><title>AI Crew Output</title>
<style>body{{background:#111;color:#eee;font-family:monospace;margin:2rem;}}pre{{background:#222;padding:1rem;border-radius:8px;}}</style>
</head><body><pre>{merged}</pre></body></html>"""
    return html

def main():
    if len(sys.argv)<2:
        print(json.dumps({"error":"No prompt passed"}))
        return
    user_prompt=sys.argv[1]
    responses=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as exec:
        futures=[exec.submit(run_ollama,name,model,user_prompt) for (name,model) in AGENTS]
        for f in concurrent.futures.as_completed(futures):
            responses.append(f.result())
    valid=[r for r in responses if "tokens" in r]
    sorted_responses=sorted(valid,key=lambda x:x["sha256"])
    final_html=assemble_final(sorted_responses)
    with open(f"{OUTPUT_DIR}/final.html","w") as f:
        f.write(final_html)
    print(json.dumps({"status":"ok","agents":responses,"html_output":f"{OUTPUT_DIR}/final.html"},indent=2))

if __name__=="__main__":
    main()
EOF

chmod +x "$CREW_DIR/ai_orchestrator.py"
echo "Python orchestrator created."

# -------------------------------
# 5️⃣ Create PHP orchestrator
# -------------------------------
cat > "$WEB_DIR/orchestrator.php" << 'EOF'
<?php
header("Content-Type: application/json; charset=utf-8");
$prompt = $_POST["prompt"] ?? null;
if (!$prompt) { echo json_encode(["error"=>"No prompt provided"]); exit; }
// Run as 'ai' user
$python_path = escapeshellarg("/home/loop/_/ai_orchestrator/crew/ai_orchestrator.py");
$prompt_escaped = escapeshellarg($prompt);
$cmd = "sudo -u ai python3 $python_path $prompt_escaped 2>&1";
$output = shell_exec($cmd);
echo $output;
EOF

chmod 644 "$WEB_DIR/orchestrator.php"
echo "PHP entrypoint created."

# -------------------------------
# 6️⃣ Set folder permissions
# -------------------------------
# ai:owner, aiaccess:group, 775, setgid
sudo chown -R ai:aiaccess "$RESULTS_DIR" "$LOGS_DIR"
sudo chmod -R 775 "$RESULTS_DIR" "$LOGS_DIR"
sudo chmod g+s "$RESULTS_DIR" "$LOGS_DIR"

sudo chmod -R 755 "$AI_DIR" "$WEB_DIR"


# -------------------------------
# 7️⃣ Optional Apache symlink
# -------------------------------
read -p "Do you want to symlink web folder to /var/www/html/ai? [y/N]: " symlink
if [[ "$symlink" =~ ^[Yy]$ ]]; then
    sudo ln -sfn "$WEB_DIR" /var/www/html/ai
    sudo service apache2 restart
    echo "Symlink created: /var/www/html/ai → $WEB_DIR"
fi

# -------------------------------
# 8️⃣ Add passwordless sudo for Apache
# -------------------------------
echo "Adding passwordless sudo for www-data to run Python as ai..."
sudo bash -c "echo 'www-data ALL=(ai) NOPASSWD: /usr/bin/python3 $CREW_DIR/ai_orchestrator.py' > /etc/sudoers.d/ai_orchestrator"
sudo chmod 440 /etc/sudoers.d/ai_orchestrator

echo "Installation complete!"
echo "Run Crew via POST to orchestrator.php, e.g.:"
echo "curl -X POST -d 'prompt=create html canvas' http://localhost/ai/orchestrator.php"

