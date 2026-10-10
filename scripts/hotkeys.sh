#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Hotkey-Manager starten                                      ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_DIR="$(dirname "${SCRIPT_DIR}")/settings"
APP="${SETTINGS_DIR}/hotkey_manager.py"

if [[ ! -f "${APP}" ]]; then
    APP="${HOME}/.config/hypr/settings/hotkey_manager.py"
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
