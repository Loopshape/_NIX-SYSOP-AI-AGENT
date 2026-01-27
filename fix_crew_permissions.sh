#!/usr/bin/env bash
# --------------------------------------------
# Nemodian 2244 Crew Apache/WSL Permissions Fix
# --------------------------------------------

set -euo pipefail
IFS=$'\n\t'

BASE="$HOME/_"
AI_DIR="$BASE/ai_orchestrator"
CREW_DIR="$AI_DIR/crew"
RESULTS_DIR="$AI_DIR/results"
LOGS_DIR="$AI_DIR/logs"
PYTHON_SCRIPT="$CREW_DIR/ai_orchestrator.py"

echo "1️⃣ Making parent folders traversable by www-data..."
sudo chmod o+rx /home/loop
sudo chmod o+rx /home/loop/_
sudo chmod o+rx "$AI_DIR"
sudo chmod o+rx "$CREW_DIR"

echo "2️⃣ Ensuring Python orchestrator is executable..."
sudo chmod +x "$PYTHON_SCRIPT"

echo "3️⃣ Setting results/ and logs/ writable by ai user and www-data..."
sudo chown -R ai:aiaccess "$RESULTS_DIR" "$LOGS_DIR"
sudo chmod -R 775 "$RESULTS_DIR" "$LOGS_DIR"
sudo chmod g+s "$RESULTS_DIR" "$LOGS_DIR"

echo "4️⃣ Adding passwordless sudo for Apache to run Python as ai..."
SUDOERS_FILE="/etc/sudoers.d/ai_orchestrator"
sudo bash -c "echo 'www-data ALL=(ai) NOPASSWD: /usr/bin/python3 $PYTHON_SCRIPT' > $SUDOERS_FILE"
sudo chmod 440 "$SUDOERS_FILE"

echo "✅ All permissions and sudoers fixed!"
echo "Test with:"
echo "curl -X POST -d 'prompt=create html canvas' http://localhost:8080/ai/orchestrator.php"

