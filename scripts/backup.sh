#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Backup-Skript                                               ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

BACKUP_BASE="${HOME}/.config/tokyo-hypr-backup"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_DIR="${BACKUP_BASE}/${TIMESTAMP}"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Tokyo Night Hyprland – Backup                          ║"
echo "╚══════════════════════════════════════════════════════════╝"

# Zu sichernde Konfigurationen
CONFIGS=(
    "${HOME}/.config/hypr"
    "${HOME}/.config/waybar"
    "${HOME}/.config/kitty"
    "${HOME}/.config/rofi"
    "${HOME}/.config/mako"
    "${HOME}/.zshrc"
    "${HOME}/.config/starship.toml"
)

mkdir -p "${BACKUP_DIR}"

echo ""
echo "Backup-Verzeichnis: ${BACKUP_DIR}"
echo ""

MANIFEST="${BACKUP_DIR}/manifest.txt"
echo "# Tokyo Night Hyprland Backup" > "${MANIFEST}"
echo "# Erstellt: ${TIMESTAMP}" >> "${MANIFEST}"
echo "# Benutzer: ${USER}" >> "${MANIFEST}"
echo "" >> "${MANIFEST}"

BACKED_UP=0
for config in "${CONFIGS[@]}"; do
    if [[ -e "${config}" ]]; then
        BASENAME="$(basename "${config}")"
        cp -a "${config}" "${BACKUP_DIR}/${BASENAME}"
        echo "  ✓ Gesichert: ${config}"
        echo "${config} -> ${BACKUP_DIR}/${BASENAME}" >> "${MANIFEST}"
        BACKED_UP=$((BACKED_UP + 1))
    else
        echo "  ○ Übersprungen (nicht vorhanden): ${config}"
    fi
done

echo ""
echo "Gesichert: ${BACKED_UP} Konfigurationen"
echo "Backup-Pfad: ${BACKUP_DIR}"
echo ""
echo "Zum Wiederherstellen:"
echo "  ./restore-backup.sh ${BACKUP_DIR}"
