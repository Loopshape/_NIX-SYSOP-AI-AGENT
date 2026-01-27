#!/usr/bin/env bash
# =============================================================================
# AI System Parallel Upgrade – Auto-Upgrade All Deepseek / NEXUS Tasks
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

AI_DIR="${HOME}/_/ai"
SCRIPT_NAME="ai_system.sh"
BACKUP_DIR="${AI_DIR}/.backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
MAX_PARALLEL=4  # Adjust based on system load

mkdir -p "$BACKUP_DIR"

# -------------------------------------------------------------------------
# 1️⃣ Detect all Deepseek/NEXUS task directories
# -------------------------------------------------------------------------
echo "[INFO] Scanning for Deepseek/NEXUS tasks..."
TASK_DIRS=($(find "$AI_DIR" -maxdepth 2 -type f -name "$SCRIPT_NAME" -exec dirname {} \;))

if [[ ${#TASK_DIRS[@]} -eq 0 ]]; then
    echo "[WARN] No AI tasks found for upgrade."
    exit 0
fi

echo "[INFO] Found ${#TASK_DIRS[@]} task(s) to upgrade."

# -------------------------------------------------------------------------
# 2️⃣ Function to upgrade a single task
# -------------------------------------------------------------------------
upgrade_task() {
    local task_dir="$1"

    echo "[INFO] Upgrading task at $task_dir"

    # Backup existing script
    if [[ -f "$task_dir/$SCRIPT_NAME" ]]; then
        cp -v "$task_dir/$SCRIPT_NAME" "$BACKUP_DIR/${SCRIPT_NAME}.$(basename "$task_dir").${TIMESTAMP}.bak"
    fi

    # Backup logs & telemetry
    local log_file="$task_dir/.db/ai_system.log"
    local telemetry_file="$task_dir/.db/ai_telemetry.jsonl"

    [[ -f "$log_file" ]] && cp -v "$log_file" "$BACKUP_DIR/ai_system.log.$(basename "$task_dir").${TIMESTAMP}.bak"
    [[ -f "$telemetry_file" ]] && cp -v "$telemetry_file" "$BACKUP_DIR/ai_telemetry.jsonl.$(basename "$task_dir").${TIMESTAMP}.bak"

    # Copy updated script
    cp -v "./$SCRIPT_NAME" "$task_dir/$SCRIPT_NAME"
    chmod +x "$task_dir/$SCRIPT_NAME"

    # Optional: dry-run test
    "$task_dir/$SCRIPT_NAME" --dry-run reason "Upgrade test prompt"
    echo "[INFO] Upgrade complete for $task_dir"
}

# -------------------------------------------------------------------------
# 3️⃣ Export function for parallel execution
# -------------------------------------------------------------------------
export -f upgrade_task
export SCRIPT_NAME BACKUP_DIR TIMESTAMP

# -------------------------------------------------------------------------
# 4️⃣ Run upgrades in parallel
# -------------------------------------------------------------------------
echo "[INFO] Starting parallel upgrades with $MAX_PARALLEL jobs..."
printf "%s\n" "${TASK_DIRS[@]}" | xargs -n1 -P "$MAX_PARALLEL" -I {} bash -c 'upgrade_task "$@"' _ {}

echo "[INFO] All upgrades completed successfully."

