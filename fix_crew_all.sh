#!/usr/bin/env bash
# --------------------------------------------
# Nemodian 2244 Crew: Full Permissions & Fix Script
# --------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# --------------------------
# Paths
# --------------------------
WEB_ROOT="/var/www/html/ai"
BASE="$HOME/_"
AI_DIR="$BASE/ai_orchestrator"
CREW_DIR="$AI_DIR/crew"
RESULTS_DIR="$AI_DIR/results"
LOGS_DIR="$AI_DIR/logs"
PYTHON_SCRIPT="$CREW_DIR/ai_orchestrator.py"

# --------------------------
# 1️⃣ Add loop to www-data
# --------------------------
echo "Adding loop to www-data group..."
sudo usermod -aG www-data loop

# --------------------------
# 2️⃣ Set web folder permissions
# --------------------------
echo "Setting web folder permissions..."
sudo chown -R www-data:www-data "$WEB_ROOT"
sudo chmod -R 775 "$WEB_ROOT"
sudo find "$WEB_ROOT" -type d -exec chmod g+s {} \;

# --------------------------
# 3️⃣ Fix Python orchestrator folders
# --------------------------
echo "Setting Python orchestrator permissions..."
sudo chown -R ai:aiaccess "$RESULTS_DIR" "$LOGS_DIR"
sudo chmod -R 775 "$RESULTS_DIR" "$LOGS_DIR"
sudo chmod g+s "$RESULTS_DIR" "$LOGS_DIR"

# Make Python script executable
sudo chmod +x "$PYTHON_SCRIPT"

# --------------------------
# 4️⃣ Make parent folders traversable by Apache
# --------------------------
echo "Making parent folders traversable..."
sudo chmod o+rx /home/loop
sudo chmod o+rx /home/loop/_
sudo chmod o+rx "$AI_DIR"
sudo chmod o+rx "$CREW_DIR"

# --------------------------
# 5️⃣ Configure passwordless sudo for Apache
# --------------------------
echo "Configuring sudoers for Apache..."
SUDOERS_FILE="/etc/sudoers.d/ai_orchestrator"
sudo bash -c "echo 'www-data ALL=(ai) NOPASSWD: /usr/bin/python3 $PYTHON_SCRIPT' > $SUDOERS_FILE"
sudo chmod 440 "$SUDOERS_FILE"

# --------------------------
# ✅ Finished
# --------------------------
echo "✅ All permissions, groups, and sudoers fixed!"
echo "• loop can edit web files directly."
echo "• Apache (www-data) can serve web files and run Python."
echo "• Python orchestrator (ai) can write to results/ and logs/."
echo ""
echo "Log out and log back in for group changes to take effect."
echo "Test with:"
echo "curl -X POST -d 'prompt=create html canvas' http://localhost:8080/ai/orchestrator.php"

