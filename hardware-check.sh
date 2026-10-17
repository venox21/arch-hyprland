#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Hardware-Check – Automatischer Hardware- & Treiber-Check   ║
# ║  Sicher für Erstinstallation & System-Updates                ║
# ╚══════════════════════════════════════════════════════════════╝
set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HW_SCRIPT="${SCRIPT_DIR}/scripts/hardware-check.sh"

if [[ ! -f "${HW_SCRIPT}" ]]; then
    # Fallback: im installierten Pfad suchen
    HW_SCRIPT="${HOME}/.config/hypr/scripts/hardware-check.sh"
fi

if [[ -f "${HW_SCRIPT}" ]]; then
    exec bash "${HW_SCRIPT}" "$@"
else
    echo "Hardware-Check-Skript nicht gefunden."
    echo "Erwarteter Pfad: ${HW_SCRIPT}"
    exit 1
fi
