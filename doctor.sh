#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Doctor – Post-Install-Diagnose                              ║
# ║  Nach dem Neustart ausführen                                 ║
# ╚══════════════════════════════════════════════════════════════╝
set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Weiterleitung an das vollständige Diagnoseskript
DIAG_SCRIPT="${SCRIPT_DIR}/scripts/diagnostics.sh"

if [[ ! -f "${DIAG_SCRIPT}" ]]; then
    # Fallback: im installierten Pfad suchen
    DIAG_SCRIPT="${HOME}/.config/hypr/scripts/diagnostics.sh"
fi

if [[ -f "${DIAG_SCRIPT}" ]]; then
    exec bash "${DIAG_SCRIPT}" "$@"
else
    echo "Diagnose-Skript nicht gefunden."
    echo "Erwarteter Pfad: ${DIAG_SCRIPT}"
    exit 1
fi
