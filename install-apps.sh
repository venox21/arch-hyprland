#!/usr/bin/env bash
# Falls das Skript mit 'sh' (oder dash) aufgerufen wurde, sofort mit 'bash' neu starten:
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night Hyprland – Interaktiver TUI App-Installer       ║
# ║  Installiert beliebte Anwendungen via Pacman & yay (AUR)     ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SCRIPT="${SCRIPT_DIR}/scripts/app-installer.sh"

if [[ ! -f "${APP_SCRIPT}" ]]; then
    APP_SCRIPT="${HOME}/.config/hypr/scripts/app-installer.sh"
fi

if [[ -f "${APP_SCRIPT}" ]]; then
    exec bash "${APP_SCRIPT}" "$@"
else
    echo "Fehler: scripts/app-installer.sh nicht gefunden!" >&2
    exit 1
fi
