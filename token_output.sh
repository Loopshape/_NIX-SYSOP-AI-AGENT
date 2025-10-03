<pre style="background:#272822; color:#f8f8f2; padding:10px; border-radius:5px; overflow:auto;">
<span style="color:#66d9ef;">#!/usr/bin/env bash</span>
<span style="color:#75715e;"># Self-Updating AI CLI (English/German only)</span>
<span style="color:#f92672;">set</span> -euo pipefail
IFS=$'\n\t'

<span style="color:#f92672;"># --- Directories & Variables ---</span>
AI_HOME="${HOME}/.local_ai"
MODULES_DIR="$AI_HOME/modules"
DB="$AI_HOME/core.db"
SANDBOX="$AI_HOME/sandbox"
LOGS="$HOME/logs"
REPO="https://github.com/YourUser/_NIX-SYSOP-AI-AGENT-by-Aris-Arjuna-Noorsanto"

<span style="color:#66d9ef;">mkdir</span> -p "$AI_HOME" "$MODULES_DIR" "$SANDBOX" "$LOGS"

<span style="color:#f92672;">log</span>() { echo "[$(<span style="color:#fd971f;">$(date '+%H:%M:%S')</span>)] $*"; }

<span style="color:#f92672;"># --- Self-Heal: update AI CLI ---</span>
SELF="$AI_HOME/ai"
log "🔄 Checking for updates..."
<span style="color:#66d9ef;">curl</span> -sL "$REPO/main/ai.sh" -o "$SELF.tmp" && chmod +x "$SELF.tmp" && mv "$SELF.tmp" "$SELF"
alias ai="$SELF"

<span style="color:#f92672;"># --- Pull Modules ---</span>
<span style="color:#f92672;">for</span> mod <span style="color:#f92672;">in</span> blockchain nostr lightning termux url-parser snippet-assembler; <span style="color:#f92672;">do</span>
    <span style="color:#66d9ef;">curl</span> -sL "$REPO/modules/$mod.sh" -o "$MODULES_DIR/$mod.sh"
    chmod +x "$MODULES_DIR/$mod.sh"
<span style="color:#f92672;">done</span>

<span style="color:#f92672;"># --- Dependencies ---</span>
<span style="color:#f92672;">for</span> cmd <span style="color:#f92672;">in</span> python3 sqlite3 curl wget git unzip node npm ollama; <span style="color:#f92672;">do</span>
    <span style="color:#f92672;">if</span> ! command -v "$cmd" &>/dev/null; <span style="color:#f92672;">then</span>
        log "Installing $cmd..."
        <span style="color:#f92672;">case</span> "$cmd" <span style="color:#f92672;">in</span>
            python3|sqlite3|curl|wget|git|unzip|node|npm)
                apt install -y "$cmd"
                ;;
            ollama)
                curl -L -o /tmp/ollama.tar.gz https://ollama-releases.s3.amazonaws.com/ollama-cli-latest-linux.tar.gz
                tar -xzf /tmp/ollama.tar.gz -C /tmp
                chmod +x /tmp/ollama
                mv /tmp/ollama /usr/local/bin/
                ;;
        <span style="color:#f92672;">esac</span>
    <span style="color:#f92672;">fi</span>
<span style="color:#f92672;">done</span>

<span style="color:#f92672;"># --- Initialize DB ---</span>
<span style="color:#f92672;">if</span> [ ! -f "$DB" ]; <span style="color:#f92672;">then</span>
    log "Initializing AI database..."
    sqlite3 "$DB" "CREATE TABLE mindflow(id INTEGER PRIMARY KEY, session_id TEXT, model_name TEXT, output TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);"
    sqlite3 "$DB" "CREATE TABLE cache(prompt_hash TEXT PRIMARY KEY, final_answer TEXT);"
<span style="color:#f92672;">fi</span>

<span style="color:#f92672;"># --- Prompt ---</span>
PROMPT="${*:-}"
<span style="color:#f92672;">if</span> [ -z "$PROMPT" ]; <span style="color:#f92672;">then</span>
    read -rp "Enter your prompt: " PROMPT
<span style="color:#f92672;">fi</span>

<span style="color:#f92672;"># --- Cache Check ---</span>
HASH=$(echo -n "$PROMPT" | sha256sum | awk '{print $1}')
CACHED=$(sqlite3 "$DB" "SELECT final_answer FROM cache WHERE prompt_hash='$HASH';")
<span style="color:#f92672;">if</span> [ -n "$CACHED" ]; <span style="color:#f92672;">then</span>
    echo "$CACHED"
    exit 0
<span style="color:#f92672;">fi</span>

<span style="color:#f92672;"># --- Generate via Ollama ---</span>
MODEL="default-model"
RAW_OUTPUT=$(ollama generate "$MODEL" "$PROMPT" 2>/dev/null)

<span style="color:#f92672;"># --- Language Filter ---</span>
FILTERED_OUTPUT=$(echo "$RAW_OUTPUT" | sed 's/[^A-Za-z0-9äöüßÄÖÜ,.!?;:()"\x27 \t\n-]//g')

<span style="color:#f92672;"># --- Store Results ---</span>
SESSION=$(uuidgen)
sqlite3 "$DB" "INSERT INTO mindflow(session_id, model_name, output) VALUES('$SESSION','$MODEL','$(echo "$FILTERED_OUTPUT" | sed "s/'/''/g")');"
sqlite3 "$DB" "INSERT OR REPLACE INTO cache(prompt_hash, final_answer) VALUES('$HASH','$(echo "$FILTERED_OUTPUT" | sed "s/'/''/g")');"

<span style="color:#f92672;"># --- Output ---</span>
echo "$FILTERED_OUTPUT"
log "✅ AI CLI finished. English/German only enforced."
</pre>