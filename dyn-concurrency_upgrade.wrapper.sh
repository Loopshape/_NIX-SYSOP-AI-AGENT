#!/usr/bin/env bash
# =============================================================================
# AI System Parallel Upgrade – Auto-Upgrade All Deepseek / NEXUS Tasks
# with Dynamic Concurrency Throttling
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

AI_DIR="${HOME}/_/ai"
SCRIPT_NAME="ai_system.sh"
BACKUP_DIR="${AI_DIR}/.backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
MAX_PARALLEL=4   # fallback max jobs if CPU info is unavailable
CPU_LOAD_THRESHOLD=75  # max CPU % before throttling
MEMORY_THRESHOLD=75    # max RAM % usage before throttling
SLEEP_INTERVAL=5       # seconds to wait if system is busy

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
# 2️⃣ Function to check system load and throttle concurrency
# -------------------------------------------------------------------------
wait_for_resources() {
    while true; do
        local cpu_load=$(awk -v n=1 '{print 100 - $5}' <(mpstat $n 1 | tail -1)) 2>/dev/null || cpu_load=50
        local mem_usage=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
        if (( cpu_load < CPU_LOAD_THRESHOLD && mem_usage < MEMORY_THRESHOLD )); then
            break
        fi
        echo "[WARN] System busy (CPU: $cpu_load%, MEM: $mem_usage%), waiting $SLEEP_INTERVAL sec..."
        sleep "$SLEEP_INTERVAL"
    done
}

# -------------------------------------------------------------------------
# 3️⃣ Function to upgrade a single task
# -------------------------------------------------------------------------
upgrade_task() {
    local task_dir="$1"
    echo "[INFO] Preparing to upgrade task at $task_dir"

    wait_for_resources  # throttle if system is busy

    # Backup existing script
    [[ -f "$task_dir/$SCRIPT_NAME" ]] && \
        cp -v "$task_dir/$SCRIPT_NAME" "$BACKUP_DIR/${SCRIPT_NAME}.$(basename "$task_dir").${TIMESTAMP}.bak"

    # Backup logs & telemetry
    [[ -f "$task_dir/.db/ai_system.log" ]] && \
        cp -v "$task_dir/.db/ai_system.log" "$BACKUP_DIR/ai_system.log.$(basename "$task_dir").${TIMESTAMP}.bak"
    [[ -f "$task_dir/.db/ai_telemetry.jsonl" ]] && \
        cp -v "$task_dir/.db/ai_telemetry.jsonl" "$BACKUP_DIR/ai_telemetry.jsonl.$(basename "$task_dir").${TIMESTAMP}.bak"

    # Copy updated script
    cp -v "./$SCRIPT_NAME" "$task_dir/$SCRIPT_NAME"
    chmod +x "$task_dir/$SCRIPT_NAME"

    # Dry-run test
    "$task_dir/$SCRIPT_NAME" --dry-run reason "Upgrade test prompt"
    echo "[INFO] Upgrade complete for $task_dir"
}

# -------------------------------------------------------------------------
# 4️⃣ Export function for parallel execution
# -------------------------------------------------------------------------
export -f upgrade_task wait_for_resources
export SCRIPT_NAME BACKUP_DIR TIMESTAMP CPU_LOAD_THRESHOLD MEMORY_THRESHOLD SLEEP_INTERVAL

# -------------------------------------------------------------------------
# 5️⃣ Run upgrades with dynamic throttling
# -------------------------------------------------------------------------
echo "[INFO] Starting upgrades with dynamic throttling..."

for task_dir in "${TASK_DIRS[@]}"; do
    upgrade_task "$task_dir" &
    # Limit active jobs dynamically
    while (( $(jobs -rp | wc -l) >= MAX_PARALLEL )); do
        sleep 1
    done
done

wait
echo "[INFO] All upgrades completed successfully."

