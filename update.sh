#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night Hyprland – Schnelles Update- & Sync-Skript      ║
# ║  Synchronisiert alle Dotfiles, Skripte und Einstellungen     ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Repo-Verzeichnis ermitteln
REPO_DIR="${SCRIPT_DIR}"
if [[ ! -f "${REPO_DIR}/config/swaync/config.json" ]]; then
    for candidate in "${HOME}/arch-hyrland" "${HOME}/tokyo-hypr-dots" "${HOME}/arch-hyprland" "${HOME}/hyprland"; do
        if [[ -f "${candidate}/config/swaync/config.json" ]]; then
            REPO_DIR="${candidate}"
            break
        fi
    done
fi

echo ""
echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}${BOLD}║  Tokyo Night Hyprland – Update & Synchronisation        ║${NC}"
echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}[1/5] Repository aktualisieren...${NC}"
if command -v git &>/dev/null && [[ -d "${REPO_DIR}/.git" ]]; then
    cd "${REPO_DIR}"
    git pull origin main || git pull || true
    echo -e "  ${GREEN}✓${NC} Git-Repository auf dem neuesten Stand"
else
    echo -e "  ${YELLOW}⚠${NC} Kein Git-Verzeichnis gefunden – überspringe git pull"
fi

echo -e "${BLUE}[2/5] Konfigurationen kopieren...${NC}"
CONFIG_DIR="${HOME}/.config"
mkdir -p \
    "${CONFIG_DIR}/hypr" \
    "${CONFIG_DIR}/hypr/scripts" \
    "${CONFIG_DIR}/hypr/settings" \
    "${CONFIG_DIR}/hypr/wallpapers" \
    "${CONFIG_DIR}/waybar" \
    "${CONFIG_DIR}/swaync" \
    "${CONFIG_DIR}/rofi" \
    "${CONFIG_DIR}/kitty" \
    "${CONFIG_DIR}/gtk-3.0" \
    "${CONFIG_DIR}/gtk-4.0"

# Waybar
if [[ -d "${REPO_DIR}/config/waybar" ]]; then
    cp -f "${REPO_DIR}/config/waybar/"* "${CONFIG_DIR}/waybar/" 2>/dev/null || true
    if [[ -d "${REPO_DIR}/config/waybar/layouts" ]]; then
        mkdir -p "${CONFIG_DIR}/waybar/layouts"
        cp -rf "${REPO_DIR}/config/waybar/layouts/"* "${CONFIG_DIR}/waybar/layouts/" 2>/dev/null || true
    fi
fi
# SwayNC
[[ -d "${REPO_DIR}/config/swaync" ]] && cp -f "${REPO_DIR}/config/swaync/"* "${CONFIG_DIR}/swaync/" 2>/dev/null || true
# Hyprland Lua
[[ -d "${REPO_DIR}/config/hypr" ]] && cp -f "${REPO_DIR}/config/hypr/"*.lua "${CONFIG_DIR}/hypr/" 2>/dev/null || true
# Hyprlock / Hyprpaper
[[ -f "${REPO_DIR}/config/hyprlock/hyprlock.conf" ]] && cp -f "${REPO_DIR}/config/hyprlock/hyprlock.conf" "${CONFIG_DIR}/hypr/hyprlock.conf" 2>/dev/null || true
[[ -f "${REPO_DIR}/config/hyprpaper/hyprpaper.conf" ]] && cp -f "${REPO_DIR}/config/hyprpaper/hyprpaper.conf" "${CONFIG_DIR}/hypr/hyprpaper.conf" 2>/dev/null || true
# Rofi
[[ -d "${REPO_DIR}/config/rofi" ]] && cp -f "${REPO_DIR}/config/rofi/"* "${CONFIG_DIR}/rofi/" 2>/dev/null || true
# Kitty
[[ -f "${REPO_DIR}/config/kitty/kitty.conf" ]] && cp -f "${REPO_DIR}/config/kitty/kitty.conf" "${CONFIG_DIR}/kitty/kitty.conf" 2>/dev/null || true
# GTK
[[ -d "${REPO_DIR}/config/gtk-3.0" ]] && cp -f "${REPO_DIR}/config/gtk-3.0/"* "${CONFIG_DIR}/gtk-3.0/" 2>/dev/null || true
[[ -d "${REPO_DIR}/config/gtk-4.0" ]] && cp -f "${REPO_DIR}/config/gtk-4.0/"* "${CONFIG_DIR}/gtk-4.0/" 2>/dev/null || true
# Settings App
[[ -d "${REPO_DIR}/settings" ]] && cp -f "${REPO_DIR}/settings/"*.py "${CONFIG_DIR}/hypr/settings/" 2>/dev/null || true
# Tokyo Shot (Screenshot-Manager & Editor)
if [[ -d "${REPO_DIR}/screenshot" ]]; then
    mkdir -p "${CONFIG_DIR}/hypr/screenshot"
    cp -f "${REPO_DIR}/screenshot/"*.py "${CONFIG_DIR}/hypr/screenshot/" 2>/dev/null || true
    chmod +x "${CONFIG_DIR}/hypr/screenshot/"*.py 2>/dev/null || true
fi
# Skripte (inkl. tokyo-shot)
[[ -d "${REPO_DIR}/scripts" ]] && cp -f "${REPO_DIR}/scripts/"* "${CONFIG_DIR}/hypr/scripts/" 2>/dev/null || true
chmod +x "${CONFIG_DIR}/hypr/scripts/"* 2>/dev/null || true
mkdir -p "${HOME}/.local/bin"
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-shot" "${HOME}/.local/bin/tokyo-shot" 2>/dev/null || true
if [[ -d "${REPO_DIR}/assets/desktop" ]]; then
    mkdir -p "${HOME}/.local/share/applications"
    cp -f "${REPO_DIR}/assets/desktop/"*.desktop "${HOME}/.local/share/applications/" 2>/dev/null || true
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
fi
# Wallpapers
[[ -d "${REPO_DIR}/assets/wallpapers" ]] && cp -n "${REPO_DIR}/assets/wallpapers/"* "${CONFIG_DIR}/hypr/wallpapers/" 2>/dev/null || true

# Desktop-PC Schutz: Falls kein Backlight vorhanden ist, Widget entfernen
if [[ ! -d /sys/class/backlight || -z "$(ls -A /sys/class/backlight 2>/dev/null)" ]]; then
    if command -v jq &>/dev/null && [[ -f "${CONFIG_DIR}/swaync/config.json" ]]; then
        jq '.widgets |= map(select(. != "backlight"))' "${CONFIG_DIR}/swaync/config.json" > "${CONFIG_DIR}/swaync/config.json.tmp" 2>/dev/null && mv "${CONFIG_DIR}/swaync/config.json.tmp" "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
    fi
fi

echo -e "  ${GREEN}✓${NC} Alle Konfigurationsdateien erfolgreich kopiert"

echo -e "${BLUE}[3/5] Design & Icons konfigurieren...${NC}"
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    if pacman -Qi papirus-icon-theme &>/dev/null; then
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Papirus-Dark Icon-Theme aktiv"
    else
        echo -e "  ${YELLOW}⚠${NC} Papirus-Icon-Theme nicht installiert (optional: sudo pacman -S papirus-icon-theme)"
    fi
fi

# Polkit & Sudoers-Regeln für Systemzeit (erlaubt Ändern von Uhrzeit & Zeitzone in den GUI-Einstellungen)
if sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then
    if [[ -f "${REPO_DIR}/assets/polkit/10-tokyo-timedate.rules" ]]; then
        sudo mkdir -p /etc/polkit-1/rules.d
        sudo cp -f "${REPO_DIR}/assets/polkit/10-tokyo-timedate.rules" /etc/polkit-1/rules.d/10-tokyo-timedate.rules 2>/dev/null || true
        sudo chmod 644 /etc/polkit-1/rules.d/10-tokyo-timedate.rules 2>/dev/null || true
    fi
    if [[ -f "${REPO_DIR}/assets/sudoers/10-tokyo-timedate" ]]; then
        sudo mkdir -p /etc/sudoers.d
        sudo cp -f "${REPO_DIR}/assets/sudoers/10-tokyo-timedate" /etc/sudoers.d/10-tokyo-timedate 2>/dev/null || true
        sudo chmod 0440 /etc/sudoers.d/10-tokyo-timedate 2>/dev/null || true
    fi
    echo -e "  ${GREEN}✓${NC} Berechtigungen für Uhrzeit & Zeitzone eingerichtet"
fi

echo -e "${BLUE}[4/5] Optionale Pakete & Abhängigkeiten prüfen...${NC}"
MISSING_PKGS=()
for pkg in papirus-icon-theme blueman python-gobject gtk4 libadwaita python-cairo gum; do
    if ! pacman -Qi "${pkg}" &>/dev/null; then
        MISSING_PKGS+=("${pkg}")
    fi
done

if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    echo -e "  ${YELLOW}Hinweis: Folgende Pakete fehlen für GUI-Tools & Installer:${NC} ${MISSING_PKGS[*]}"
    echo -e "  Installieren mit: ${BOLD}sudo pacman -S --needed ${MISSING_PKGS[*]}${NC}"
fi

if [[ -f "${REPO_DIR}/scripts/hardware-check.sh" ]]; then
    echo -e "  ${BLUE}Tipp:${NC} Hardware- & Treiber-Check jederzeit ausführen mit: ${BOLD}./hardware-check.sh${NC}"
fi

echo -e "${BLUE}[5/5] Dienste neu laden...${NC}"
# SwayNC neu laden / starten
if command -v swaync-client &>/dev/null && pgrep -x swaync &>/dev/null; then
    swaync-client -R 2>/dev/null || true
    swaync-client -rs 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} SwayNC Konfiguration und CSS neu geladen"
else
    pkill -x swaync 2>/dev/null || true
    sleep 0.3
    if [[ -x "${CONFIG_DIR}/hypr/scripts/control-center.sh" ]]; then
        "${CONFIG_DIR}/hypr/scripts/control-center.sh" --toggle 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} SwayNC gestartet"
    fi
fi

# Waybar neu laden
if pgrep -x waybar &>/dev/null; then
    pkill -SIGUSR2 waybar 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Waybar neu geladen"
fi

echo ""
echo -e "${GREEN}${BOLD}Update abgeschlossen! Alle Fehlerbehebungen sind aktiv.${NC}"
echo ""
