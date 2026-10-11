#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Hotkey-Manager starten                                      ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Wayland & Hyprland Umgebung ermitteln (SSH / TTY Support) ──
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    wp_sock="$(find "${XDG_RUNTIME_DIR}" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' 2>/dev/null | head -n 1 || true)"
    if [[ -n "${wp_sock}" ]]; then
        export WAYLAND_DISPLAY="$(basename "${wp_sock}")"
    fi
fi

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    sig="$(ls -1 "${XDG_RUNTIME_DIR}/hypr" 2>/dev/null | grep -v '\.lock' | head -n 1 || true)"
    if [[ -n "${sig}" ]]; then
        export HYPRLAND_INSTANCE_SIGNATURE="${sig}"
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_DIR="$(dirname "${SCRIPT_DIR}")/settings"
APP="${SETTINGS_DIR}/hotkey_manager.py"

if [[ ! -f "${APP}" ]]; then
    APP="${HOME}/.config/hypr/settings/hotkey_manager.py"
fi

if [[ ! -f "${APP}" ]]; then
    for candidate in "${HOME}/tokyo-hypr-dots" "${HOME}/arch-hyprland" "${HOME}/arch-hyrland" "${HOME}/hyprland"; do
        if [[ -f "${candidate}/settings/hotkey_manager.py" ]]; then
            APP="${candidate}/settings/hotkey_manager.py"
            break
        fi
    done
fi

if [[ ! -f "${APP}" ]]; then
    notify-send -a "Hotkeys" "Fehler" "Hotkey-Manager nicht gefunden" -u critical 2>/dev/null || true
    echo "Fehler: ${APP} nicht gefunden" >&2
    exit 1
fi

if ! python3 -c "import gi; gi.require_version('Gtk', '4.0'); gi.require_version('Adw', '1')" 2>/dev/null; then
    notify-send -a "Hotkeys" "Fehler" \
        "Python GTK4/Adwaita-Abhängigkeiten fehlen." \
        -u critical 2>/dev/null || true
    exit 1
fi

exec python3 "${APP}" "$@"
