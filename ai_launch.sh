#!/usr/bin/env bash
set -euo pipefail; IFS=$'\n\t'

AI_HOME="$HOME/.local_ai"
PROOT_ROOTFS="$HOME/.proot-distros/debian"
EMPTY_FILE="$PROOT_ROOTFS/sys/.empty"

log(){ echo "[$(date '+%H:%M:%S')] $*"; }

log "🔍 Prüfe Debian RootFS..."

if ! proot-distro list | grep -q '^debian$'; then
    log "⚠ Debian nicht installiert, starte Installation..."
    proot-distro install debian
fi

# .empty erstellen, falls fehlt
mkdir -p "$(dirname "$EMPTY_FILE")"
[ ! -f "$EMPTY_FILE" ] && touch "$EMPTY_FILE" && log "✅ Dummy .empty erstellt"

# Optional: QEMU installieren, falls Arch mismatch
if ! command -v qemu-aarch64-static >/dev/null 2>&1; then
    log "ℹ QEMU nicht gefunden, installiere qemu-user-static..."
    apt update && apt install -y qemu-user-static || true
fi

log "🔧 Teste /usr/bin/env in Debian..."
if ! proot-distro login debian -- bash -c "command -v env" >/dev/null 2>&1; then
    log "❌ /usr/bin/env fehlt, repariere Debian RootFS..."
    proot-distro login debian -- bash -c "apt update && apt install -y coreutils"
fi

log "✅ Debian-Proot bereit für AI-Script"
log "Starte AI CLI..."
ai "$@"
