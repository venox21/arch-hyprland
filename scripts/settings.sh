#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Einstellungs-App starten                                    ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_DIR="$(dirname "${SCRIPT_DIR}")/settings"
APP="${SETTINGS_DIR}/app.py"

if [[ ! -f "${APP}" ]]; then
    # Fallback: Im installierten Pfad suchen
    APP="${HOME}/.config/hypr/settings/app.py"
fi

if [[ ! -f "${APP}" ]]; then
    notify-send -a "Einstellungen" "Fehler" "Einstellungs-App nicht gefunden" -u critical 2>/dev/null || true
    echo "Fehler: ${APP} nicht gefunden" >&2
    exit 1
fi

# Prüfe Abhängigkeiten
if ! python3 -c "import gi; gi.require_version('Gtk', '4.0'); gi.require_version('Adw', '1')" 2>/dev/null; then
    notify-send -a "Einstellungen" "Fehler" \
        "Python GTK4/Adwaita-Abhängigkeiten fehlen.\nInstalliere: python-gobject gtk4 libadwaita" \
        -u critical 2>/dev/null || true
    echo "Fehler: Python GTK4/Adwaita nicht verfügbar" >&2
    echo "Installiere: sudo pacman -S python-gobject gtk4 libadwaita" >&2
    exit 1
fi

exec python3 "${APP}" "$@"
