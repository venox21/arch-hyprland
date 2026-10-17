#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Shot – Screenshot-Skript für Hyprland                 ║
# ║  Nutzt Tokyo Shot (GTK4 + Annotation Editor) mit Fallback   ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Wenn tokyo-shot existiert, übergebe den Befehl
for candidate in \
    "${SCRIPT_DIR}/tokyo-shot" \
    "${HOME}/.local/bin/tokyo-shot" \
    "${HOME}/.config/hypr/scripts/tokyo-shot"; do
    if [[ -f "${candidate}" ]]; then
        exec bash "${candidate}" "$@"
    fi
done

if command -v tokyo-shot &>/dev/null; then
    exec tokyo-shot "$@"
fi

# Fallback: Direkt über grim + slurp
SCREENSHOT_DIR="${HOME}/Bilder/Screenshots"
mkdir -p "${SCREENSHOT_DIR}"

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
FILENAME="${SCREENSHOT_DIR}/screenshot_${TIMESTAMP}.png"

notify() {
    local msg="$1"
    if command -v notify-send &>/dev/null; then
        notify-send -a "Tokyo Shot" -i camera-photo "Screenshot" "${msg}" -t 3500
    fi
}

case "${1:-full}" in
    gui)
        # Wenn tokyo-shot GUI nicht direkt im Pfad liegt, suche in gängigen Pfaden
        for app_py in \
            "${SCRIPT_DIR}/../screenshot/app.py" \
            "${HOME}/.config/hypr/screenshot/app.py" \
            "${HOME}/Desktop/hyprland/tokyo-hypr-dots/screenshot/app.py" \
            "${HOME}/arch-hyprland/screenshot/app.py" \
            "${HOME}/tokyo-hypr-dots/screenshot/app.py"; do
            if [[ -f "${app_py}" ]]; then
                exec python3 "${app_py}" --gui
            fi
        done
        notify "Tokyo Shot GUI konnte nicht gefunden werden."
        exit 1
        ;;
    full)
        grim "${FILENAME}"
        wl-copy < "${FILENAME}" 2>/dev/null || true
        notify "Ganzer Bildschirm gespeichert:\n${FILENAME}"
        ;;
    area)
        AREA="$(slurp -d -b '#1a1b2666' -c '#7aa2f7ff' -s '#7aa2f722' -w 2 2>/dev/null)" || { notify "Auswahl abgebrochen"; exit 0; }
        grim -g "${AREA}" "${FILENAME}"
        wl-copy < "${FILENAME}" 2>/dev/null || true
        notify "Bereich gespeichert:\n${FILENAME}"
        ;;
    window)
        GEOMETRY="$(hyprctl activewindow -j 2>/dev/null | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null)" || {
            notify "Kein aktives Fenster gefunden"
            exit 1
        }
        grim -g "${GEOMETRY}" "${FILENAME}"
        wl-copy < "${FILENAME}" 2>/dev/null || true
        notify "Fenster gespeichert:\n${FILENAME}"
        ;;
    *)
        echo "Verwendung: $0 {full|area|window|gui}" >&2
        exit 1
        ;;
esac
