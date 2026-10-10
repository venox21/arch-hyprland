#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Zwischenablage-Manager mit cliphist + Rofi                  ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

if ! command -v cliphist &>/dev/null; then
    notify-send -a "Clipboard" "Fehler" "cliphist ist nicht installiert" -u critical
    exit 1
fi

if ! command -v rofi &>/dev/null; then
    notify-send -a "Clipboard" "Fehler" "rofi ist nicht installiert" -u critical
    exit 1
fi

# Clipboard-Historie über Rofi anzeigen und auswählen
SELECTED="$(cliphist list | rofi -dmenu \
    -i \
    -p "  Zwischenablage" \
    -theme-str 'window { width: 600px; }' \
    -theme-str 'listview { lines: 12; }' \
    -theme ~/.config/rofi/config.rasi \
    2>/dev/null)" || exit 0

# Ausgewählten Eintrag in die Zwischenablage kopieren
echo -n "${SELECTED}" | cliphist decode | wl-copy

notify-send -a "Clipboard" "Zwischenablage" "Eintrag kopiert" -t 1500 2>/dev/null || true
