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
# ASSEMBLE TEMPLATE
#####################################
cmd_assemble_template() {
  log "Assembling templated output..."

  OUTPUT="$DIST/index.html"
  > "$OUTPUT"
  > "$TMP/assembly.sha256"

  jq -c '.[]' "$MANIFEST" | while read -r item; do
    file=$(echo "$item" | jq -r '.file')
    chunk=$(cat "$file")

    # Replace {{VAR}} with environment variables if exist
    chunk=$(echo "$chunk" | sed -E 's/\{\{([A-Z0-9_]+)\}\}/'"$(printenv \1 || echo "")"'/g')

    echo "$chunk" >> "$OUTPUT"

    # Compute chunk hash
    echo "$file $(echo "$chunk" | sha256sum | awk '{print $1}')" >> "$TMP/assembly.sha256"
  done

  # Compute combined hash
  combined=$(cat "$TMP/assembly.sha256" | awk '{print $2}' | sha256sum | awk '{print $1}')
  echo "$combined" > "$GENESIS"

  log "Assembled $OUTPUT"
  log "Assembly combined hash written to $GENESIS"

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

