#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Waybar sicher neu starten                                   ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Wayland-Umgebung ermitteln (wichtig bei SSH / TTY) ─────────
if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    wp_sock="$(find "${XDG_RUNTIME_DIR}" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' 2>/dev/null | head -n 1 || true)"
    if [[ -n "${wp_sock}" ]]; then
        export WAYLAND_DISPLAY="$(basename "${wp_sock}")"
    fi
fi

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
