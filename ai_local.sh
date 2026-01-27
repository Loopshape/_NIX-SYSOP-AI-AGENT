#!/usr/bin/env bash
#
# ai - Autonomic Synthesis Platform CLI
# A self-contained, multi-model autonomous AI reasoning CLI framework.
#

# ---
# 1. Core Architecture & Robustness
# ---
set -euo pipefail # Bulletproof execution

# --- Configuration ---
DB_FILE="core.db"
SWAP_DIR=".ai_swap"
SANDBOX_DIR=".ai_sandbox"
OLLAMA_URL="http://localhost:11434"
MAX_LOOPS=5
MIN_OUTPUT_LEN=150 # Min characters for loop extension heuristic

# --- Helper Functions ---
log() {
    # Logs to both console and a log file
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] - $1"
    echo "$message"
    echo "$message" >> ai_verbose.log
}

# Use bat for syntax highlighting if available, otherwise cat
highlight() {
    if command -v bat &> /dev/null; then
        bat --style=plain --paging=never --language=bash --theme="OneHalfDark" "$@"
    else
        cat "$@"
    fi
}

db_execute() {
    sqlite3 "$DB_FILE" "$1"
}

cleanup() {
    # Remove temporary files on exit
    rm -f /tmp/ai_model_*.output
}
trap cleanup EXIT

# ---
# 2. Setup & Initialization
# ---
setup_environment() {
    mkdir -p "$SWAP_DIR" "$SANDBOX_DIR"
    if [ ! -f "$DB_FILE" ]; then
        log "Initializing core database at '$DB_FILE'..."
        db_execute "
            CREATE TABLE IF NOT EXISTS mindflow (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT,
                loop_id INTEGER,
                model_name TEXT,
                output TEXT,
                rank INTEGER,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS task_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                tool_used TEXT,
                args TEXT,
                output_summary TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS cache (
                prompt_hash TEXT PRIMARY KEY,
                final_answer TEXT
            );
        "
    fi
}

# ---
# 3. Simulated AI Models & Processing
# Five interleaved models that run in parallel.
# ---

# code — always provides technical/code reasoning.
model_code() {
    local prompt="$1"
    echo "### Model: code
**Analysis:** The user's prompt requires a technical solution.
**Reasoning:** Based on the keywords in '$prompt', a shell script or a configuration snippet would be appropriate.
**Suggestion:**
\`\`\`bash
# Example solution for prompt:
echo 'Hello from the code model!'
for i in {1..3}; do
  echo \"Loop \$i\"
done
\`\`\`"
}

# coin — handles mood, time, historical context.
model_coin() {
    local prompt="$1"
    local current_hour=$(date +%H)
    local mood="neutral"
    if (( current_hour >= 5 && current_hour < 12 )); then
        mood="optimistic, morning focus"
    elif (( current_hour >= 12 && current_hour < 18 )); then
        mood="analytical, afternoon diligence"
    elif (( current_hour >= 18 || current_hour < 5 )); then
        mood="reflective, evening wrap-up"
    fi

    echo "### Model: coin
**Context:** Current time suggests a mood of '$mood'.
**Historical Perspective:** Considering previous interactions (simulated), the user prefers concise answers.
**Reasoning:** The prompt '$prompt' should be addressed with respect to the current context. The approach should be direct and factor in the time of day."
}

# 2244 — prioritizes language choice (German/English).
model_2244() {
    local prompt="$1"
    local lang="English"
    if [[ "$prompt" =~ (hallo|danke|bitte|wie) ]]; then
        lang="German"
    fi

    if [[ "$lang" == "German" ]]; then
        echo "### Model: 2244
**Language Analysis:** German keywords detected.
**Reasoning:** The primary response should be in German to match the user's likely preference.
**Output Language:** Deutsch."
    else
        echo "### Model: 2244
**Language Analysis:** No specific non-English keywords detected.
**Reasoning:** Defaulting to English as the primary communication language.
**Output Language:** English."
    fi
}

# core and loop — collaborate with other models in reasoning loops.
model_core() {
    local prompt="$1"
    echo "### Model: core
**Core Logic:** Synthesizing inputs to address the central query: '$prompt'.
**Collaboration:** The 'code' model's technical suggestion seems logical. The 'coin' model's context is valuable for tone.
**Synthesis:** I will build upon the technical foundation and incorporate the contextual mood."
}

model_loop() {
    local prompt="$1"
    echo "### Model: loop
**Iterative Reasoning:** This is an iteration on the prompt '$prompt'.
**Cross-Check:** I am reviewing the outputs from 'core', 'code', and 'coin'. There appears to be a consensus forming.
**Next Step:** The next loop should focus on refining the code example and providing a clear, final summary."
}

# ---
# 4. Core Reasoning Engine: The "Model Race"
# ---
run_reasoning_loop() {
    local initial_prompt="$1"
    local session_id=$(date +%s)-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
    log "Starting new reasoning session: $session_id"
    log "Initial Prompt: $initial_prompt"

    # Optional Caching Check
    local prompt_hash=$(echo -n "$initial_prompt" | sha256sum | awk '{print $1}')
    local cached_answer=$(db_execute "SELECT final_answer FROM cache WHERE prompt_hash = '$prompt_hash';")
    if [ -n "$cached_answer" ]; then
        log "Cache hit. Returning cached answer."
        echo -e "\n--- [CACHED FINAL ANSWER] ---\n$cached_answer"
        return
    fi

    local current_prompt="$initial_prompt"
    local combined_output=""
    local final_answer_detected=false

    for i in $(seq 1 $MAX_LOOPS); do
        log "--- Starting Loop $i/$MAX_LOOPS ---"
        log "Current Prompt: $current_prompt"

        # Model "Race": Run all models in parallel
        model_code "$current_prompt" > /tmp/ai_model_code.output &
        model_coin "$current_prompt" > /tmp/ai_model_coin.output &
        model_2244 "$current_prompt" > /tmp/ai_model_2244.output &
        model_core "$current_prompt" > /tmp/ai_model_core.output &
        model_loop "$current_prompt" > /tmp/ai_model_loop.output &
        wait # Wait for all background jobs to finish

        # Collect and rank outputs (simple ranking based on length)
        local outputs=()
        for model in code coin 2244 core loop; do
            local content=$(< /tmp/ai_model_${model}.output)
            local len=${#content}
            # Format: "length model_name content"
            outputs+=("$len $model $content")
        done

        # Sort by length (desc) to simulate ranking
        IFS=$'\n' sorted_outputs=($(sort -rn <<<"${outputs[*]}"))
        unset IFS

        log "Loop $i: Verbose Model Outputs (Ranked)"
        local loop_fused_output="--- Loop $i Fusion ---\n"
        local rank=1
        for item in "${sorted_outputs[@]}"; do
            local model_name=$(echo "$item" | awk '{print $2}')
            local model_output=$(echo "$item" | cut -d' ' -f3-)

            # Display and log to Mindflow DB
            echo -e "\n--- Rank: $rank, Model: $model_name ---\n$model_output"
            db_execute "INSERT INTO mindflow (session_id, loop_id, model_name, output, rank) VALUES ('$session_id', $i, '$model_name', '$(echo "$model_output" | sed "s/'/''/g")', $rank);"

            # Weighted Fusion: Give more weight (by order) to top-ranked models
            loop_fused_output+="$model_output\n"
            ((rank++))
        done

        combined_output+="$loop_fused_output"

        # Final Answer Detection
        if [[ "$combined_output" =~ \[FINAL_ANSWER\] ]]; then
            log "Final answer detected. Ending loops."
            final_answer_detected=true
            break
        fi

        # Update prompt for the next loop (Cross-loop reasoning)
        current_prompt="$initial_prompt\n\n--- Previous Loops Summary ---\n$combined_output"
    done

    # Generate final answer if not explicitly provided
    local final_answer
    if ! $final_answer_detected; then
        log "Max loops reached or heuristic met. Synthesizing final answer."
        final_answer="**Synthesized Answer from all loops:**\nBased on the collaborative reasoning across $MAX_LOOPS loops, the primary recommendation is to use the technical solution provided by the 'code' model, while being mindful of the contextual tone suggested by the 'coin' model. The final output has been fused from all model contributions.\n\n[FINAL_ANSWER]\n${combined_output}"
    else
        final_answer="$combined_output"
    fi

    # Store in cache
    db_execute "INSERT OR REPLACE INTO cache (prompt_hash, final_answer) VALUES ('$prompt_hash', '$(echo "$final_answer" | sed "s/'/''/g")');"

    echo -e "\n--- [FINAL ANSWER] ---\n"
    # Compress large outputs to swap
    if [ ${#final_answer} -gt 1024 ]; then
        local swap_file="$SWAP_DIR/$session_id.gz"
        echo "$final_answer" | gzip > "$swap_file"
        log "Final answer is large. Stored compressed at $swap_file"
        echo "Output stored in $swap_file"
    else
        echo -e "$final_answer"
    fi
}


# ---
# 5. Utilities & Enhancements
# ---
util_hash() {
    if [ -z "$1" ]; then echo "Usage: ai hash <string|file>"; return 1; fi
    if [ -f "$1" ]; then
        sha256sum "$1"
        log_task "hash" "$1" "Hashed file $1"
    else
        echo -n "$1" | sha256sum | awk '{print $1}'
        log_task "hash" "string" "Hashed provided string"
    fi
}

util_download() {
    if [ -z "$1" ]; then echo "Usage: ai download <url> [output_filename]"; return 1; fi
    local url="$1"
    local output_file="$SANDBOX_DIR/${2:-$(basename "$url")}"
    log "Downloading $url to $output_file"
    curl -L --fail --progress-bar -o "$output_file" "$url"
    log "Download complete."
    if [[ "$output_file" == *.zip ]]; then
        log "Extracting zip file..."
        unzip -d "$SANDBOX_DIR" "$output_file"
        log "Extraction complete."
    fi
    log_task "download" "$url" "Downloaded and extracted to $SANDBOX_DIR"
}

util_scan() {
    if [ -z "$1" ]; then echo "Usage: ai scan <pattern> [directory]"; return 1; fi
    local pattern="$1"
    local dir="${2:-.}"
    log "Scanning for pattern '$pattern' in directory '$dir'"
    grep -rE "$pattern" "$dir"
    log_task "scan" "$pattern in $dir" "Found matches for regex pattern"
}

util_lint() {
    if [ -z "$1" ]; then echo "Usage: ai lint <file>"; return 1; fi
    local file="$1"
    log "Linting/formatting $file"
    case "$file" in
        *.js|*.jsx|*.ts|*.tsx)
            command -v prettier &>/dev/null && prettier --write "$file" && log "Formatted with prettier"
            command -v eslint &>/dev/null && eslint --fix "$file" && log "Linted with eslint"
            ;;
        *.py)
            command -v black &>/dev/null && black "$file" && log "Formatted with black"
            ;;
        *)
            log "No linter found for this file type."
            ;;
    esac
    highlight "$file"
    log_task "lint" "$file" "Applied available linters/formatters"
}

# ---
# 6. Simulated Wallet & BTC Tools
# ---
WALLET_FILE=".ai_wallet.db"
util_wallet_init() {
    if [ ! -f "$WALLET_FILE" ]; then
        echo "balance_usd=10000.00" > "$WALLET_FILE"
        echo "btc_balance=0.0" >> "$WALLET_FILE"
        log "Simulated wallet created with \$10,000 USD."
    fi
}

util_wallet() {
    util_wallet_init
    log "Displaying wallet status"
    source "$WALLET_FILE"
    echo "--- Simulated Wallet ---"
    printf "USD Balance: \$%.2f\n" "$balance_usd"
    printf "BTC Balance: %.8f\n" "$btc_balance"
    echo "------------------------"
    log_task "wallet" "status" "Displayed wallet balances"
}

util_btc() {
    util_wallet_init
    if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: ai btc <buy|sell> <amount_usd>"; return 1; fi
    source "$WALLET_FILE"
    local action="$1"
    local amount_usd="$2"
    # Simulated static price for simplicity
    local btc_price=65000.00

    if [[ "$action" == "buy" ]]; then
        if (( $(echo "$balance_usd < $amount_usd" | bc -l) )); then
            echo "Error: Insufficient USD balance."
            return 1
        fi
        local btc_to_buy=$(echo "$amount_usd / $btc_price" | bc -l)
        balance_usd=$(echo "$balance_usd - $amount_usd" | bc -l)
        btc_balance=$(echo "$btc_balance + $btc_to_buy" | bc -l)
        log "Bought $btc_to_buy BTC for \$$amount_usd"
    elif [[ "$action" == "sell" ]]; then
        local btc_to_sell=$(echo "$amount_usd / $btc_price" | bc -l)
        if (( $(echo "$btc_balance < $btc_to_sell" | bc -l) )); then
            echo "Error: Insufficient BTC balance."
            return 1
        fi
        balance_usd=$(echo "$balance_usd + $amount_usd" | bc -l)
        btc_balance=$(echo "$btc_balance - $btc_to_sell" | bc -l)
        log "Sold $btc_to_sell BTC for \$$amount_usd"
    else
        echo "Invalid action. Use 'buy' or 'sell'."
        return 1
    fi

    # Update wallet file
    printf "balance_usd=%.2f\n" "$balance_usd" > "$WALLET_FILE"
    printf "btc_balance=%.8f\n" "$btc_balance" >> "$WALLET_FILE"
    util_wallet
    log_task "btc" "$action $amount_usd" "Simulated BTC transaction"
}

util_webkit_build() {
    log "Simulating WebKit build process..."
    if [ ! -d "$SANDBOX_DIR/WebKit" ]; then
        log "Cloning WebKit (simulation)..."
        sleep 2
        mkdir -p "$SANDBOX_DIR/WebKit"
        log "Clone complete."
    else
        log "WebKit source already present."
    fi
    log "Running build script (simulation)..."
    for i in {1..10}; do
        echo -n "Building [$(printf '%-10s' "$(printf '#%0.s' $(seq 1 $i))")] $((i * 10))% ..."
        echo -ne "\r"
        sleep 0.5
    done
    echo ""
    log "WebKit build simulation complete!"
    log_task "webkit-build" "" "Simulated a full WebKit clone and build"
}

# ---
# 7. Language & Creativity Fallback
# ---
check_ollama() {
    if ! curl -s --head "$OLLAMA_URL" | head -n 1 | grep "200 OK" > /dev/null; then
        echo "--- Empathic Fallback ---"
        echo "It seems the local Ollama server is offline."
        echo "While I can't connect to my core reasoning models, I can still help with my built-in utilities."
        echo "Try 'ai help' to see what I can do for you right now."
        echo "Take a moment, maybe grab a coffee. I'll be here when you get back."
        exit 1
    fi
}


# ---
# 8. CLI & User Interaction
# ---
show_help() {
    echo "ai - Autonomic Synthesis Platform CLI"
    echo "Usage: ai [command] [options] or ai \"<your prompt>\""
    echo ""
    echo "Core Commands:"
    echo "  <prompt>            Run the multi-model reasoning engine on a prompt."
    echo "  help                Show this help message."
    echo ""
    echo "Utilities:"
    echo "  hash <string|file>  Calculate SHA256 hash."
    echo "  download <url>      Download and unzip a file into the sandbox."
    echo "  scan <pattern> [dir] Scan for a regex pattern in files."
    echo "  lint <file>         Apply code linters/formatters (prettier, eslint, black)."
    echo ""
    echo "Simulators:"
    echo "  wallet              Show simulated crypto wallet balances."
    echo "  btc <buy|sell> <usd> Simulate a BTC transaction."
    echo "  webkit-build        Simulate cloning and building the WebKit project."
    echo ""
    echo "All verbose logs are stored in 'ai_verbose.log'."
    echo "Databases and swap files are in './core.db' and './.ai_swap/'."
}

# ---
# Main Execution Logic
# ---
main() {
    # Initialize environment on first run
    setup_environment

    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi

    # Check Ollama status before running reasoning loop
    # We only check this for the main reasoning prompt, not for utilities
    if [[ "$1" != "help" && "$1" != "hash" && "$1" != "download" && "$1" != "scan" && "$1" != "lint" && "$1" != "wallet" && "$1" != "btc" && "$1" != "webkit-build" ]]; then
        #check_ollama # NOTE: This is the hook for the actual check.
        # Since this script is a self-contained simulation, we'll keep it commented out
        # but the function exists for a real implementation.
        :
    fi

    local command="$1"
    shift # Consume the command

    case "$command" in
        help)
            show_help
            ;;
        hash)
            util_hash "$@"
            ;;
        download)
            util_download "$@"
            ;;
        scan)
            util_scan "$@"
            ;;
        lint)
            util_lint "$@"
            ;;
        wallet)
            util_wallet "$@"
            ;;
        btc)
            util_btc "$@"
            ;;
        webkit-build)
            util_webkit_build
            ;;
        *)
            # Default action: treat the input as a prompt for the reasoning engine
            run_reasoning_loop "$command $@"
            ;;
    esac
}

# Run the main function with all script arguments
main "$@"
