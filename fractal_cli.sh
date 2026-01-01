#!/usr/bin/env bash
# AGENT NEMODIAN :: 5 MULTI-BRAIN v0.1 "NEHEMIAH BOOT KERNEL"
# Compact Kernel, Multi-Model, JSON Pipeline C1

AI_HOME="${AI_HOME:-$PWD/.ai_sandbox}"
DB_PATH="${DB_PATH:-$PWD/core.db}"
SESSION_ID=$(uuidgen 2>/dev/null||echo $RANDOM$RANDOM)
MODELS=("code" "coin" "2244" "core" "loop")
API_URL="${API_URL:-http://localhost:11434}"

mkdir -p "$AI_HOME"

check_tools(){
  for t in curl jq sqlite3; do
    command -v $t >/dev/null 2>&1 || echo "⚠️ $t not found, install for full functionality"
  done
}

send_json(){ curl -s -X POST "$API_URL" -H "Content-Type: application/json" -d "$1"; }

json_node(){ cat<<EOF
{"session":"$SESSION_ID","timestamp":"$(date -u +%s)","node":{"intent":"prompt_forward","vector_state":"initializing","entropy":0.42,"fractal_depth":1},"payload":{"type":"prompt","content":"$1"}}
EOF
}

multi_brain_process(){
  local prompt="$1"
  local ai_bridge="$HOME/_/ai/ai.sh"
  
  if [ -x "$ai_bridge" ]; then
    echo "⚡ Routing to NEXUS CORE..."
    "$ai_bridge" query CORE "$prompt"
  else
    local output="$prompt"
    for m in "${MODELS[@]}"; do
      output=$(echo "$output" | jq -R --arg m "$m" '{"model":$m,"input":.,"output":"\(.input) processed by \($m)"}')
      [[ "$output" == *"[FINAL_ANSWER]"* ]] && break
    done
    echo "$output"
  fi
}

ai_help(){
  cat <<EOF
AGENT NEMODIAN CLI – Commands
help                          Show this help
<text prompt>                 Send prompt to Multi-Brain pipeline
hash <file_or_string>         SHA256 hash
download <url> [file]         Download & save
wallet                        Show simulated BTC wallet
btc buy <amt>                 Buy BTC
btc sell <amt>                Sell BTC
serve                         Start minimal HTTP terminal
EOF
}

ai_hash(){ echo -n "$1" | sha256sum | awk '{print $1}'; }

ai_download(){
  local url="$1" file="$2"
  file=${file:-$(basename "$url")}
  curl -sSL "$url" -o "$file" && echo "Downloaded $file"
}

wallet_show(){
  sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS wallet(id INTEGER PRIMARY KEY,balance REAL,btc REAL);"
  sqlite3 "$DB_PATH" "INSERT INTO wallet(balance,btc) SELECT 1000,0 WHERE NOT EXISTS(SELECT 1 FROM wallet);"
  sqlite3 "$DB_PATH" "SELECT * FROM wallet;"
}

btc_buy(){ sqlite3 "$DB_PATH" "UPDATE wallet SET btc=btc+$1,balance=balance-$1 WHERE id=1;"; wallet_show; }
btc_sell(){ sqlite3 "$DB_PATH" "UPDATE wallet SET btc=btc-$1,balance=balance+$1 WHERE id=1;"; wallet_show; }

http_serve(){
  while true; do
    { echo -ne "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nAGENT NEMODIAN Web CLI Active\n"; } | nc -l -p 80 -q 1
  done
}

# Main REPL
check_tools
echo -e "\e[1;36mAGENT NEMODIAN v0.1 [Session $SESSION_ID]\e[0m"
while true; do
  echo -ne "\e[1;32m≫ \e[0m"; read -r cmd args
  case "$cmd" in
    help) ai_help ;;
    hash) ai_hash "$args" ;;
    download) ai_download $args ;;
    wallet) wallet_show ;;
    btc) case "$args" in buy*) btc_buy ${args#buy } ;; sell*) btc_sell ${args#sell } ;; esac ;;
    serve) http_serve ;;
    "") continue ;;
    *) multi_brain_process "$cmd $args" ;;
  esac
done
