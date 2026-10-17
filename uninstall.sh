#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night Hyprland Dots – Deinstallation                  ║
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
echo "║  Tokyo Night Hyprland Dots – Deinstallation              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [[ "${EUID}" -eq 0 ]]; then
    echo -e "${RED}Nicht als Root ausführen!${NC}"
    exit 1
fi

# ── Backup vor Deinstallation ─────────────────────────────────
echo -e "${BLUE}── Phase 1: Sicherung ──${NC}"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_DIR="${BACKUP_BASE}/pre-uninstall_${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

for dir in hypr waybar kitty rofi mako; do
    if [[ -d "${CONFIG_DIR}/${dir}" ]]; then
        cp -a "${CONFIG_DIR}/${dir}" "${BACKUP_DIR}/"
        echo -e "  ${GREEN}✓${NC} Gesichert: ${dir}/"
    fi
done

for file in "${HOME}/.zshrc" "${CONFIG_DIR}/starship.toml"; do
    if [[ -f "${file}" ]]; then
        cp -a "${file}" "${BACKUP_DIR}/"
        echo -e "  ${GREEN}✓${NC} Gesichert: $(basename "${file}")"
    fi
done

echo -e "  ${GREEN}Backup:${NC} ${BACKUP_DIR}"
echo ""

# ── Konfigurationen entfernen ─────────────────────────────────
echo -e "${BLUE}── Phase 2: Konfigurationen ──${NC}"

if confirm "Tokyo Night Konfigurationen entfernen?"; then
    REMOVE_CONFIGS=(
        "${CONFIG_DIR}/hypr/hyprland.lua"
        "${CONFIG_DIR}/hypr/colors.lua"
        "${CONFIG_DIR}/hypr/keybinds.lua"
        "${CONFIG_DIR}/hypr/monitors.lua"
        "${CONFIG_DIR}/hypr/rules.lua"
        "${CONFIG_DIR}/hypr/animations.lua"
        "${CONFIG_DIR}/hypr/autostart.lua"
        "${CONFIG_DIR}/hypr/input.lua"
        "${CONFIG_DIR}/hypr/scripts"
        "${CONFIG_DIR}/hypr/settings"
        "${CONFIG_DIR}/hypr/screenshot"
        "${CONFIG_DIR}/tokyo-shot"
        "${HOME}/.local/bin/tokyo-shot"
        "${HOME}/.local/share/applications/tokyo-shot.desktop"
        "${CONFIG_DIR}/hypr/hyprlock.conf"
        "${CONFIG_DIR}/hypr/hyprpaper.conf"
    )

    for item in "${REMOVE_CONFIGS[@]}"; do
        if [[ -e "${item}" ]]; then
            rm -rf "${item}"
            echo -e "  ${GREEN}✓${NC} Entfernt: ${item}"
        fi
    done

    # Waybar, Kitty, Rofi, Mako – nur nach Bestätigung
    for app in waybar kitty rofi mako; do
        if [[ -d "${CONFIG_DIR}/${app}" ]]; then
            if confirm "  ${app}-Konfiguration auch entfernen?"; then
                rm -rf "${CONFIG_DIR}/${app}"
                echo -e "  ${GREEN}✓${NC} Entfernt: ${app}/"
            fi
        fi
    done

    echo -e "  ${GREEN}Konfigurationen entfernt${NC}"
else
    echo -e "  ${YELLOW}Übersprungen${NC}"
fi
echo ""

# ── SDDM-Theme entfernen ─────────────────────────────────────
echo -e "${BLUE}── Phase 3: SDDM-Theme ──${NC}"

if confirm "SDDM Tokyo Night Theme entfernen?"; then
    if sudo test -d /usr/share/sddm/themes/tokyo-night; then
        sudo rm -rf /usr/share/sddm/themes/tokyo-night
        echo -e "  ${GREEN}✓${NC} SDDM-Theme entfernt"
    fi
    if sudo test -f /etc/sddm.conf.d/tokyo-night.conf; then
        sudo rm -f /etc/sddm.conf.d/tokyo-night.conf
        echo -e "  ${GREEN}✓${NC} SDDM-Konfiguration entfernt"
    fi
else
    echo -e "  ${YELLOW}Übersprungen${NC}"
fi
echo ""

# ── Pakete entfernen (optional) ───────────────────────────────
echo -e "${BLUE}── Phase 4: Pakete (optional) ──${NC}"
echo -e "${YELLOW}WARNUNG: Das Entfernen von Paketen kann andere Programme beeinflussen.${NC}"

if confirm "Installierte Pakete entfernen?"; then
    echo ""
    echo "Welche Pakete sollen entfernt werden?"
    echo "  1) Nur Hyprland-spezifische (hyprlock, hyprpaper, hyprpolkitagent)"
    echo "  2) Hyprland und Desktop-Tools (Waybar, Rofi, Mako, etc.)"
    echo "  3) Alles (inklusive Kitty, Zsh, Starship, etc.)"
    echo "  4) Nichts"
    echo -en "${YELLOW}Auswahl [1-4]: ${NC}"
    read -r choice

    PKGS_HYPR=(hyprlock hyprpaper hyprpolkitagent)
    PKGS_DESKTOP=(waybar rofi-wayland mako cliphist)
    PKGS_ALL=(kitty starship fastfetch)

    case "${choice}" in
        1) REMOVE_PKGS=("${PKGS_HYPR[@]}") ;;
        2) REMOVE_PKGS=("${PKGS_HYPR[@]}" "${PKGS_DESKTOP[@]}") ;;
        3) REMOVE_PKGS=("${PKGS_HYPR[@]}" "${PKGS_DESKTOP[@]}" "${PKGS_ALL[@]}") ;;
        *) REMOVE_PKGS=() ;;
    esac

    if [[ ${#REMOVE_PKGS[@]} -gt 0 ]]; then
        echo ""
        echo "Zu entfernen:"
        printf "  - %s\n" "${REMOVE_PKGS[@]}"
        echo ""

        if confirm "Sicher?"; then
            sudo pacman -Rns --noconfirm "${REMOVE_PKGS[@]}" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Pakete entfernt"
        fi
    fi
else
    echo -e "  ${YELLOW}Übersprungen${NC}"
fi

# ── Shell zurücksetzen ────────────────────────────────────────
echo ""
echo -e "${BLUE}── Phase 5: Shell ──${NC}"
if [[ "$(basename "${SHELL}")" == "zsh" ]]; then
    if confirm "Standard-Shell auf Bash zurücksetzen?"; then
        chsh -s "$(command -v bash)"
        echo -e "  ${GREEN}✓${NC} Shell auf Bash gesetzt"
    fi
fi

# ── Zusammenfassung ───────────────────────────────────────────
echo ""
echo -e "${MAGENTA}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Deinstallation abgeschlossen                            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${GREEN}Backup:${NC} ${BACKUP_DIR}"
echo -e "  Zum Wiederherstellen: ${BOLD}./restore-backup.sh ${BACKUP_DIR}${NC}"
echo ""
