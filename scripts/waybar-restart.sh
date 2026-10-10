#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Waybar sicher neu starten                                   ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

echo "Waybar wird neu gestartet..."

# Bestehende Waybar-Prozesse sauber beenden
if pgrep -x waybar &>/dev/null; then
    pkill -x waybar
    # Warten bis der Prozess beendet ist (max 3 Sekunden)
    for i in $(seq 1 30); do
        if ! pgrep -x waybar &>/dev/null; then
            break
        fi
        sleep 0.1
    done

    # Falls immer noch läuft, erzwingen
    if pgrep -x waybar &>/dev/null; then
        pkill -9 -x waybar 2>/dev/null || true
        sleep 0.2
    fi
fi

# Waybar neu starten
mkdir -p "${HOME}/.cache"
waybar > "${HOME}/.cache/waybar.log" 2>&1 &
disown

echo "Waybar erfolgreich neu gestartet."
notify-send -a "Waybar" "Waybar" "Erfolgreich neu gestartet" -t 2000 2>/dev/null || true
