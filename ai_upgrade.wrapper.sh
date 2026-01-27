#!/usr/bin/env bash
# =============================================================================
# AI System Upgrade Wrapper – Safe Auto-Upgrade for WSL AI Orchestration
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

AI_DIR="${HOME}/_/ai"
SCRIPT_NAME="ai_system.sh"
BACKUP_DIR="${AI_DIR}/.backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

mkdir -p "$BACKUP_DIR"

# -------------------------------------------------------------------------
# 1️⃣ Backup existing script
# -------------------------------------------------------------------------
if [[ -f "$AI_DIR/$SCRIPT_NAME" ]]; then
    echo "[INFO] Backing up existing script..."
    cp -v "$AI_DIR/$SCRIPT_NAME" "$BACKUP_DIR/${SCRIPT_NAME}.${TIMESTAMP}.bak"
fi

# -------------------------------------------------------------------------
# 2️⃣ Backup logs & telemetry
# -------------------------------------------------------------------------
LOG_FILE="${AI_DIR}/.db/ai_system.log"
TELEMETRY_FILE="${AI_DIR}/.db/ai_telemetry.jsonl"

if [[ -f "$LOG_FILE" ]]; then
    echo "[INFO] Backing up logs..."
    cp -v "$LOG_FILE" "$BACKUP_DIR/ai_system.log.${TIMESTAMP}.bak"
fi

if [[ -f "$TELEMETRY_FILE" ]]; then
    echo "[INFO] Backing up telemetry..."
    cp -v "$TELEMETRY_FILE" "$BACKUP_DIR/ai_telemetry.jsonl.${TIMESTAMP}.bak"
fi

# -------------------------------------------------------------------------
# 3️⃣ Apply new script
# -------------------------------------------------------------------------
echo "[INFO] Installing updated AI system script..."
cp -v "./$SCRIPT_NAME" "$AI_DIR/$SCRIPT_NAME"
chmod +x "$AI_DIR/$SCRIPT_NAME"

# -------------------------------------------------------------------------
# 4️⃣ Verification
# -------------------------------------------------------------------------
if [[ -x "$AI_DIR/$SCRIPT_NAME" ]]; then
    echo "[INFO] Upgrade successful. Script is executable."
else
    echo "[ERROR] Upgrade failed. Check permissions."
    exit 1
fi

# -------------------------------------------------------------------------
# 5️⃣ Optional: Run test dry-run
# -------------------------------------------------------------------------
echo "[INFO] Running test dry-run..."
"$AI_DIR/$SCRIPT_NAME" --dry-run reason "Upgrade test prompt"

echo "[INFO] Upgrade process completed successfully."

