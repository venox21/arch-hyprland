#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Backup wiederherstellen                                     ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

CONFIG_DIR="${HOME}/.config"
BACKUP_BASE="${HOME}/.config/tokyo-hypr-backup"

confirm() {
    local prompt="$1"
    local response
    echo -en "${YELLOW}${prompt} [j/N] ${NC}"
    read -r response
    [[ "${response,,}" =~ ^(j|ja|y|yes)$ ]]
}

echo ""
echo -e "${MAGENTA}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Tokyo Night – Backup wiederherstellen                   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Backup-Verzeichnis bestimmen ──────────────────────────────
BACKUP_DIR="${1:-}"

if [[ -z "${BACKUP_DIR}" ]]; then
    echo "Verfügbare Backups:"
    echo ""

    if [[ ! -d "${BACKUP_BASE}" ]]; then
        echo -e "${RED}Kein Backup-Verzeichnis gefunden: ${BACKUP_BASE}${NC}"
        exit 1
    fi

    mapfile -t BACKUPS < <(find "${BACKUP_BASE}" -maxdepth 1 -mindepth 1 -type d | sort -r)

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        echo -e "${RED}Keine Backups gefunden.${NC}"
        exit 1
    fi

    for i in "${!BACKUPS[@]}"; do
        BNAME="$(basename "${BACKUPS[${i}]}")"
        # Anzahl der Dateien im Backup
        COUNT="$(find "${BACKUPS[${i}]}" -maxdepth 1 | wc -l)"
        echo "  $((i + 1))) ${BNAME} (${COUNT} Elemente)"
    done

    echo ""
    echo -en "${YELLOW}Backup-Nummer wählen (1-${#BACKUPS[@]}): ${NC}"
    read -r SELECTION

    if [[ ! "${SELECTION}" =~ ^[0-9]+$ ]] || [[ "${SELECTION}" -lt 1 ]] || [[ "${SELECTION}" -gt ${#BACKUPS[@]} ]]; then
        echo -e "${RED}Ungültige Auswahl.${NC}"
        exit 1
    fi

    BACKUP_DIR="${BACKUPS[$((SELECTION - 1))]}"
fi

# ── Backup prüfen ────────────────────────────────────────────
if [[ ! -d "${BACKUP_DIR}" ]]; then
    echo -e "${RED}Backup-Verzeichnis nicht gefunden: ${BACKUP_DIR}${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Backup: ${BACKUP_DIR}${NC}"
echo ""
echo "Inhalt:"
ls -la "${BACKUP_DIR}/" | tail -n +2
echo ""

# ── Manifest anzeigen ─────────────────────────────────────────
if [[ -f "${BACKUP_DIR}/manifest.txt" ]]; then
    echo -e "${BLUE}Manifest:${NC}"
    cat "${BACKUP_DIR}/manifest.txt"
    echo ""
fi

# ── Wiederherstellung ─────────────────────────────────────────
if ! confirm "Dieses Backup wiederherstellen?"; then
    echo "Abgebrochen."
    exit 0
fi

echo ""

# Ordner-basierte Konfigurationen
for dir in hypr waybar kitty rofi mako; do
    if [[ -d "${BACKUP_DIR}/${dir}" ]]; then
        if confirm "  ${dir}/ wiederherstellen?"; then
            # Aktuellen Zustand sichern
            if [[ -d "${CONFIG_DIR}/${dir}" ]]; then
                rm -rf "${CONFIG_DIR}/${dir}"
            fi
            cp -a "${BACKUP_DIR}/${dir}" "${CONFIG_DIR}/${dir}"
            echo -e "  ${GREEN}✓${NC} ${dir}/ wiederhergestellt"
        fi
    fi
done

# Einzeldateien
if [[ -f "${BACKUP_DIR}/.zshrc" ]]; then
    if confirm "  .zshrc wiederherstellen?"; then
        cp -a "${BACKUP_DIR}/.zshrc" "${HOME}/.zshrc"
        echo -e "  ${GREEN}✓${NC} .zshrc wiederhergestellt"
    fi
fi

if [[ -f "${BACKUP_DIR}/starship.toml" ]]; then
    if confirm "  starship.toml wiederherstellen?"; then
        cp -a "${BACKUP_DIR}/starship.toml" "${CONFIG_DIR}/starship.toml"
        echo -e "  ${GREEN}✓${NC} starship.toml wiederhergestellt"
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}Wiederherstellung abgeschlossen.${NC}"
echo ""
echo "Empfehlung: Hyprland-Konfiguration neu laden mit:"
echo "  hyprctl reload"
echo ""
