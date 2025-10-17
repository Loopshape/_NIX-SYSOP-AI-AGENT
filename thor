#!/usr/bin/env bash
# AGENT NEMODIAN :: 5 MULTI-BRAIN v0.7 "MINDFLOW VISUALIZER"
# Node JSON + Subnodes + Ollama + Multi-Brain Fusion + Fraktal Entropy + Terminal Mindflow Map

AI_HOME="${AI_HOME:-$PWD/.ai_sandbox}"
DB_PATH="${DB_PATH:-$PWD/core.db}"
SESSION_ID=$(uuidgen 2>/dev/null||echo $RANDOM$RANDOM)
MODELS=("code" "coin" "2244" "core" "loop")
API_URL="${API_URL:-http://localhost:11434}"

mkdir -p "$AI_HOME"

check_tools(){ for t in curl jq sqlite3 bc; do command -v $t >/dev/null 2>&1 || echo "⚠️ $t not found"; done; }
check_ollama(){ curl -sSf "$API_URL" >/dev/null 2>&1 && OLLAMA=1 || OLLAMA=0; }

sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS nodes(
id TEXT PRIMARY KEY,
timestamp INTEGER,
intent TEXT,
vector TEXT,
entropy REAL,
fractal_depth INTEGER,
content TEXT,
brain_outputs TEXT,
qbit_factor REAL
);"

# --- Weighted Cross-Node Vector Fusion ---
vector_fusion(){ local node_vector="$1"; local weights="$2"; echo "$node_vector" | jq --argjson w "$weights" '[.[] * ($w|.[0])] '; }

collapse_qbit(){
  local node_json="$1"
  local vector_sum="$2"
  local ollama_weight="${3:-0}"
  local entropy="$4"
  local rand=$(awk -v seed=$RANDOM 'BEGIN{srand(seed);print rand()}')
  local factor=$(echo "$vector_sum*0.3 + $ollama_weight*0.4 + $entropy*0.2 + $rand*0.1" | bc -l)
  node_json=$(echo "$node_json" | jq --argjson q "$factor" '.qbit_factor=$q')
  if (( $(echo "$factor>0.6"|bc -l) )); then
    echo "$node_json" | jq --arg fa "[FINAL_ANSWER]" '.payload.content += $fa'
  else
    echo "$node_json" | jq '.payload.content'
  fi
}

process_node(){
  local node_json="$1"
  local depth=$(echo "$node_json" | jq '.node.fractal_depth')
  local intent=$(echo "$node_json" | jq -r '.node.intent')
  local content=$(echo "$node_json" | jq -r '.payload.content')
  local entropy=$(echo "$node_json" | jq '.node.entropy')
  local vector=$(echo "$node_json" | jq -r '.node.vector // [0.5,0.5,0.5]')
  local ollama_out=""

  if [ "$OLLAMA" -eq 1 ]; then
    prompt_json=$(jq -n --arg p "$content" '{prompt:$p,session:"'$SESSION_ID'"}')
    ollama_out=$(curl -s -X POST "$API_URL" -H "Content-Type: application/json" -d "$prompt_json")
  fi

  for m in "${MODELS[@]}"; do vector=$(echo "$vector" | jq '[.[] * 1.01]'); done

  local node_id=$(echo "$node_json" | jq -r '.node.id')
  local brain_outputs=$(echo "${MODELS[*]}" | tr ' ' ',')
  brain_outputs=$(echo "$brain_outputs,$ollama_out")

  local subdepth=$((depth-1))
  if (( $(echo "$entropy>0.3 && subdepth>0" | bc -l) )); then
    subnode=$(echo "$node_json" | jq --arg c "$content" --argjson d $subdepth \
      '{node:{id:"sub_'$node_id'",intent:"sub_'+$intent+'",vector:[0.1,0.2,0.3],entropy:0.25,fractal_depth:$d},payload:{type:"prompt",content:$c}}')
    process_node "$subnode"
  fi

  local sum=$(echo "$vector" | jq 'add')
  local ollama_weight=$(echo "$ollama_out" | jq -r 'length/1000' 2>/dev/null || echo 0)
  local qbit_factor=$(echo "$sum*0.3 + $ollama_weight*0.4 + $entropy*0.2" | bc -l)

  sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO nodes VALUES('$node_id',$(date +%s),'$intent','$vector',$entropy,$depth,'$content','$brain_outputs',$qbit_factor);"

  collapse_qbit "$node_json" "$sum" "$ollama_weight" "$entropy"
}

multi_brain_process(){
  local prompt="$1"
  local node=$(jq -n --arg p "$prompt" '{session:"'$SESSION_ID'",timestamp:'"$(date -u +%s)"',node:{id:"node_001",intent:"process",vector:[0.5,0.5,0.5],entropy:0.42,fractal_depth:2},payload:{type:"prompt",content:$p}}')
  process_node "$node"
}

# --- Mindflow Replay & Visual Map ---
mindflow_replay(){
  local nid="$1"
  local rows=$(sqlite3 -separator '|' "$DB_PATH" "SELECT id,intent,fractal_depth,entropy,qbit_factor FROM nodes WHERE id LIKE '$nid%' ORDER BY timestamp;")
  echo -e "\e[1;36mMindflow Map for $nid\e[0m"
  while IFS='|' read -r id intent depth entropy qbit; do
    local indent=""
    for ((i=0;i<depth;i++)); do indent="$indent  "; done
    local color="\e[34m" # blue default
    (( $(echo "$entropy>0.5"|bc -l) )) && color="\e[31m" # red high entropy
    (( $(echo "$qbit>0.7"|bc -l) )) && color="\e[32m" # green high qbit
    echo -e "${indent}${color}${id} | ${intent} | entropy:${entropy} | qbit:${qbit}\e[0m"
  done <<< "$rows"
}

# --- Utilities ---
ai_help(){ cat <<EOF
AGENT NEMODIAN CLI v0.7
help                  Show this help
<text prompt>         Send prompt to Node-Qbit pipeline with Ollama + Optimizer
hash <file_or_string> SHA256 hash
download <url> [file] Download & save
wallet                Show simulated BTC wallet
btc buy <amt>         Buy BTC
btc sell <amt>        Sell BTC
replay <node_id>      Mindflow replay of Node + Subnodes + Optimizer info
mindflow <node_id>    Visual Mindflow map in terminal
serve                 Start minimal HTTP terminal
EOF
}

ai_hash(){ echo -n "$1" | sha256sum | awk '{print $1}'; }
ai_download(){ local url="$1" file="$2"; file=${file:-$(basename "$url")}; curl -sSL "$url" -o "$file" && echo "Downloaded $file"; }
wallet_show(){ sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS wallet(id INTEGER PRIMARY KEY,balance REAL,btc REAL);" sqlite3 "$DB_PATH" "INSERT INTO wallet(balance,btc) SELECT 1000,0 WHERE NOT EXISTS(SELECT 1 FROM wallet);" sqlite3 "$DB_PATH" "SELECT * FROM wallet;"; }
btc_buy(){ sqlite3 "$DB_PATH" "UPDATE wallet SET btc=btc+$1,balance=balance-$1 WHERE id=1;"; wallet_show; }
btc_sell(){ sqlite3 "$DB_PATH" "UPDATE wallet SET btc=btc-$1,balance=balance+$1 WHERE id=1;"; wallet_show; }
http_serve(){ while true; do { echo -ne "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nAGENT NEMODIAN Web CLI Active\n"; } | nc -l -p 80 -q 1; done; }

# --- Main REPL ---
check_tools
check_ollama
echo -e "\e[1;36mAGENT NEMODIAN v0.7 [Session $SESSION_ID] Ollama: $OLLAMA\e[0m"
while true; do
  echo -ne "\e[1;32m≫ \e[0m"; read -r cmd args
  case "$cmd" in
    help) ai_help ;;
    hash) ai_hash "$args" ;;
    download) ai_download $args ;;
    wallet) wallet_show ;;
    btc) case "$args" in buy*) btc_buy ${args#buy } ;; sell*) btc_sell ${args#sell } ;; esac ;;
    replay) mindflow_replay "$args" ;;
    mindflow) mindflow_replay "$args" ;;
    serve) http_serve ;;
    "") continue ;;
    *) multi_brain_process "$cmd $args" ;;
  esac
done
