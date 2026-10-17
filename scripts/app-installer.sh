#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  App-Installer Starter                                       ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "${SCRIPT_DIR}")"

# Finde das Hauptskript
INSTALLER=""
for candidate in \
    "${REPO_DIR}/install-apps.sh" \
    "${HOME}/arch-hyprland/install-apps.sh" \
    "${HOME}/tokyo-hypr-dots/install-apps.sh" \
    "${HOME}/hyprland/install-apps.sh"; do
    if [[ -f "${candidate}" ]]; then
        INSTALLER="${candidate}"
        break
    fi
done

if [[ -n "${INSTALLER}" && -f "${INSTALLER}" ]]; then
    exec bash "${INSTALLER}" "$@"
else
    echo "Fehler: install-apps.sh konnte nicht gefunden werden!" >&2
    exit 1
fi
