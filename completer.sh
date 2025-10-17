#!/bin/bash
set -e

# --- CONFIGURATION (Should match provisioning_script.sh) ---
LOOP_USER="loop"
REPO_DIR="/home/$LOOP_USER/_"

echo "--- Starting Nemodian Agent Repository Setup as user '$LOOP_USER' ---"
echo "This script will install Python dependencies and initialize submodules."

# Execute setup steps as the 'loop' user, ensuring the environment is sourced
sudo -u "$LOOP_USER" bash << EOF
    # Ensure all user environment variables (like NVM paths and local Python paths)
    # configured in the provisioning script are available.
    if [ -f "/home/$LOOP_USER/.bashrc" ]; then
        source "/home/$LOOP_USER/.bashrc"
    fi

    cd "$REPO_DIR"

    # 1. Update/Initialize Git submodules (if the project uses them)
    echo "1. Initializing Git submodules..."
    # The '|| true' allows the script to continue if the repo has no submodules
    # and the command fails due to being run outside a working tree, though 
    # 'git submodule update' should handle this gracefully in a cloned repo.
    git submodule update --init --recursive || true

    # 2. Install Python dependencies locally
    # The 'PYTHONUSERBASE' and path variables set in .bashrc ensure 
    # dependencies are installed into /home/loop/.env.local
    echo "2. Installing Python requirements into local user environment..."
    if [ -f "requirements.txt" ]; then
        # Use the python3 binary found in the path (which should now include ~/.env.local/bin)
        python3 -m pip install -r requirements.txt
        echo "Python dependencies installed successfully."
    else
        echo "Warning: 'requirements.txt' not found in $REPO_DIR. Skipping Python dependency install."
    fi

    # 3. Final confirmation
    echo "3. Setup complete for agent repository."
EOF

echo "✅ Repository completion script finished."
echo "The Nemodian AGI environment under the user '$LOOP_USER' is now fully set up."
