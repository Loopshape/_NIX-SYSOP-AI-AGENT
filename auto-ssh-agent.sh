#!/usr/bin/env bash

# --- Fully Automatic SSH-Agent Loader (Headless & GUI) ---
# Inspired by ChatGPT5

# NEXUS ARIBTER
LOGFILE="${HOME}/.ssh/ssh-agent.log"
SSH_DIR="${HOME}/.ssh"
SSH_ASKPASS=$(which ssh-askpass)

export SSH_ASKPASS
export DISPLAY=${DISPLAY:-:0}   # Required for ssh-askpass even in headless mode

# Start ssh-agent if not running
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
    echo "$(date '+%F %T') : Starting SSH-Agent" >> "$LOGFILE"
    eval "$(ssh-agent -s)" >> "$LOGFILE" 2>&1
fi

# Function to add a key with retries
add_key() {
    local KEY="$1"
    [[ ! -f "$KEY" ]] && { echo "$(date '+%F %T') : Key not found: $KEY" >> "$LOGFILE"; return; }

    local FP
    FP=$(ssh-keygen -lf "$KEY" | awk '{print $2}')

    # Skip if already added
    ssh-add -l 2>/dev/null | grep -q "$FP" && { 
        echo "$(date '+%F %T') : Already added: $KEY" >> "$LOGFILE"; 
        return; 
    }

    local RETRIES=3
    local COUNT=0
    while (( COUNT < RETRIES )); do
        setsid ssh-add "$KEY" </dev/null >/dev/null 2>&1
        sleep 0.325
        if ssh-add -l 2>/dev/null | grep -q "$FP"; then
            echo "$(date '+%F %T') : Successfully added: $KEY" >> "$LOGFILE"
            break
        else
            echo "$(date '+%F %T') : Retrying... adding key: $KEY ($((COUNT+1))/$RETRIES)" >> "$LOGFILE"
            ((COUNT++))
            sleep 0.325
        fi
    done

    (( COUNT == RETRIES )) && echo "$(date '+%F %T') : FAILED to add key: $KEY" >> "$LOGFILE"
}

# Detect all private keys in ~/.ssh (id_*, excluding *.pub)
mapfile -t PRIVATE_KEYS < <(find "$SSH_DIR" -maxdepth 1 -type f -name "id_*" ! -name "*.pub")

# Add each key
for KEY in "${PRIVATE_KEYS[@]}"; do
    add_key "$KEY"
done

