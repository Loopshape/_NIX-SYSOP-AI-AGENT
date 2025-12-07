#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SNIPPETS="$ROOT/snippets"
TEMPLATES="$ROOT/templates"
DIST="$ROOT/dist"
MANIFEST="$ROOT/orchestrator/manifest/manifest.json"
GENESIS="$ROOT/orchestrator/genesis/genesis.sha256"
LOGS="$ROOT/orchestrator/logs"
TMP="$ROOT/orchestrator/tmp"

mkdir -p "$DIST" "$LOGS" "$TMP"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

#####################################
# SCAN: generate manifest.json
#####################################
cmd_scan() {
  log "Scanning snippets & templates..."
  mkdir -p "$(dirname "$MANIFEST")"

  echo "[" > "$MANIFEST"
  first=true
  for file in $(find "$SNIPPETS" "$TEMPLATES" -type f -name "*.html" -o -name "*.js" -o -name "*.css" | sort); do
    [ "$first" = true ] && first=false || echo "," >> "$MANIFEST"
    hash=$(sha256sum "$file" | awk '{print $1}')
    echo "  {\"file\":\"$file\", \"hash\":\"$hash\"}" >> "$MANIFEST"
  done
  echo "]" >> "$MANIFEST"
  log "Manifest generated at $MANIFEST"
}

#####################################
# ASSEMBLE WITH RECURSIVE INCLUDE
#####################################
assemble_file() {
  local file="$1"
  local depth="${2:-0}"

  if [ "$depth" -gt 10 ]; then
    log "[WARN] Maximum include depth reached at $file"
    return
  fi

  if [ ! -f "$file" ]; then
    log "[WARN] Include file not found: $file"
    return
  fi

  local content
  content=$(cat "$file")

  # ENVVAR substitution {{VAR}}
  content=$(echo "$content" | sed -E 's/\{\{([A-Z0-9_]+)\}\}/'"$(printenv \1 || echo "")"'/g')

  # Include substitution {{include:filename}}
  while grep -q "{{include:[^}]\+}}" <<< "$content"; do
    content=$(echo "$content" | sed -E "s#\{\{include:([^}]+)\}\}#$(assemble_file "$ROOT/\1" $((depth+1)) | sed 's#/#\\/#g')#g")
  done

  echo "$content"
}

#####################################
# ASSEMBLE TEMPLATE
#####################################
cmd_assemble_template() {
  log "Assembling templates recursively..."

  OUTPUT="$DIST/index.html"
  > "$OUTPUT"
  > "$TMP/assembly.sha256"

  jq -c '.[]' "$MANIFEST" | while read -r item; do
    file=$(echo "$item" | jq -r '.file')
    chunk=$(assemble_file "$file")

    echo "$chunk" >> "$OUTPUT"

    # Compute chunk hash
    echo "$file $(echo "$chunk" | sha256sum | awk '{print $1}')" >> "$TMP/assembly.sha256"
  done

  # Compute combined genesis hash
  combined=$(cat "$TMP/assembly.sha256" | awk '{print $2}' | sha256sum | awk '{print $1}')
  echo "$combined" > "$GENESIS"

  log "Assembled $OUTPUT"
  log "Combined genesis hash: $combined"

  # Log assembly
  cp "$OUTPUT" "$LOGS/index-$(date '+%Y%m%d-%H%M%S').html"
}

#####################################
# MAIN
#####################################
CMD="${1:-}"

case "$CMD" in
  scan) cmd_scan ;;
  assemble-template) cmd_assemble_template ;;
  *)
    echo "Usage: $0 {scan|assemble-template}"
    exit 1
    ;;
esac

