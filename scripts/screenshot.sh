#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Screenshot-Skript für Hyprland                              ║
# ║  Verwendet grim + slurp + wl-copy                            ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

SCREENSHOT_DIR="${HOME}/Bilder/Screenshots"
mkdir -p "${SCREENSHOT_DIR}"

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
FILENAME="${SCREENSHOT_DIR}/screenshot_${TIMESTAMP}.png"

notify() {
    local msg="$1"
    if command -v notify-send &>/dev/null; then
        notify-send -a "Screenshot" -i camera-photo "Screenshot" "${msg}" -t 3000
    fi
}

case "${1:-full}" in
    full)
        grim "${FILENAME}"
        wl-copy < "${FILENAME}"
        notify "Ganzer Bildschirm gespeichert:\n${FILENAME}"
        ;;
    area)
        AREA="$(slurp 2>/dev/null)" || { notify "Auswahl abgebrochen"; exit 0; }
        grim -g "${AREA}" "${FILENAME}"
        wl-copy < "${FILENAME}"
        notify "Bereich gespeichert:\n${FILENAME}"
        ;;
    window)
        # Aktives Fenster: Geometrie über hyprctl
        GEOMETRY="$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" || {
            notify "Kein aktives Fenster gefunden"
            exit 1
        }
        grim -g "${GEOMETRY}" "${FILENAME}"
        wl-copy < "${FILENAME}"
        notify "Fenster gespeichert:\n${FILENAME}"
        ;;
    *)
        echo "Verwendung: $0 {full|area|window}" >&2
        exit 1
        ;;
esac
