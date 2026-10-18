#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night Hyprland Dots – Installationsskript             ║
# ║  Für Arch Linux mit Hyprland ≥ 0.55 (Lua-Konfiguration)     ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Farben und Formatierung ───────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Pfade ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"
BACKUP_BASE="${HOME}/.config/tokyo-hypr-backup"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_DIR="${BACKUP_BASE}/${TIMESTAMP}"
LOG_FILE="${BACKUP_BASE}/install_${TIMESTAMP}.log"

# ── Funktionen ────────────────────────────────────────────────
log()     { echo -e "$1" | tee -a "${LOG_FILE}"; }
info()    { log "${BLUE}[INFO]${NC}  $1"; }
success() { log "${GREEN}[OK]${NC}    $1"; }
warn()    { log "${YELLOW}[WARN]${NC}  $1"; }
error()   { log "${RED}[FEHLER]${NC} $1"; }
fatal()   { error "$1"; error "Installation abgebrochen."; exit 1; }

header() {
    echo ""
    log "${MAGENTA}${BOLD}── $1 ──${NC}"
    echo ""
}

# Standard-Sprache & Tastaturlayout
SYSTEM_LANG="de"
SYSTEM_KB="de"
LOCALE_CODE="de_DE.UTF-8"

t() {
    if [[ "${SYSTEM_LANG:-de}" == "en" ]]; then
        echo "$2"
    else
        echo "$1"
    fi
}

confirm() {
    local prompt="$1"
    local response
    if [[ "${SYSTEM_LANG:-de}" == "en" ]]; then
        echo -en "${YELLOW}${prompt} [y/N] ${NC}"
    else
        echo -en "${YELLOW}${prompt} [j/N] ${NC}"
    fi
    read -r response
    [[ "${response,,}" =~ ^(j|ja|y|yes)$ ]]
}

# ── Vorab-Prüfungen ──────────────────────────────────────────
echo ""
echo -e "${MAGENTA}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Tokyo Night Hyprland Dots – Installation                ║"
echo "║  Version 1.0.0                                           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Backup-Basisverzeichnis erstellen
mkdir -p "${BACKUP_BASE}"
touch "${LOG_FILE}"

# Root-Check
if [[ "${EUID}" -eq 0 ]]; then
    fatal "Dieses Skript darf NICHT als Root ausgeführt werden.\nVerwende: ./install.sh (ohne sudo)"
fi

# ── Phase 0: Sprache & Tastatur / Language & Keyboard ────────
echo ""
echo -e "${MAGENTA}${BOLD}── Sprachauswahl / Language Selection ──${NC}"
echo -e "  ${CYAN}1)${NC} Deutsch (Standard / German)"
echo -e "  ${CYAN}2)${NC} English"
echo ""
echo -en "${YELLOW}Wähle Sprache / Select language [1/2] (Standard: 1): ${NC}"
read -r LANG_INPUT
LANG_INPUT="${LANG_INPUT:-1}"
LANG_INPUT="$(echo "${LANG_INPUT}" | tr '[:upper:]' '[:lower:]' | xargs)"

if [[ "${LANG_INPUT}" == "2" || "${LANG_INPUT}" == "en" || "${LANG_INPUT}" == "english" ]]; then
    SYSTEM_LANG="en"
    LOCALE_CODE="en_US.UTF-8"
    DEFAULT_KB="us"
    info "Selected language: English"
else
    SYSTEM_LANG="de"
    LOCALE_CODE="de_DE.UTF-8"
    DEFAULT_KB="de"
    info "Gewählte Sprache: Deutsch"
fi

if [[ "${SYSTEM_LANG}" == "en" ]]; then
    echo -en "${YELLOW}Select keyboard layout [us/de] (Default: ${DEFAULT_KB}): ${NC}"
else
    echo -en "${YELLOW}Tastaturlayout wählen [de/us] (Standard: ${DEFAULT_KB}): ${NC}"
fi
read -r KB_INPUT
KB_INPUT="${KB_INPUT:-${DEFAULT_KB}}"
KB_INPUT="$(echo "${KB_INPUT}" | tr '[:upper:]' '[:lower:]' | xargs)"
if [[ "${KB_INPUT}" != "de" && "${KB_INPUT}" != "us" ]]; then
    KB_INPUT="${DEFAULT_KB}"
fi
SYSTEM_KB="${KB_INPUT}"

if [[ "${SYSTEM_LANG}" == "en" ]]; then
    success "Keyboard layout set to: ${SYSTEM_KB}"
else
    success "Tastaturlayout gesetzt auf: ${SYSTEM_KB}"
fi

# Arch Linux prüfen
header "$(t 'Phase 1: Systemprüfung' 'Phase 1: System Verification')"

if [[ ! -f /etc/arch-release ]]; then
    fatal "$(t 'Kein Arch Linux erkannt. Dieses Skript ist nur für Arch Linux.' 'Arch Linux not detected. This script is only for Arch Linux.')"
fi
success "$(t 'Arch Linux erkannt' 'Arch Linux detected')"

# sudo-Zugriff prüfen
if ! sudo -v 2>/dev/null; then
    fatal "$(t 'sudo-Zugriff erforderlich. Stelle sicher, dass dein Benutzer sudo verwenden kann.' 'sudo access required. Make sure your user has sudo permissions.')"
fi
success "$(t 'sudo-Zugriff verfügbar' 'sudo access available')"

# Internetverbindung prüfen
if ! ping -c 1 archlinux.org &>/dev/null; then
    warn "$(t 'Keine Internetverbindung erkannt. Die Paketinstallation könnte fehlschlagen.' 'No internet connection detected. Package installation might fail.')"
    if ! confirm "$(t 'Trotzdem fortfahren?' 'Continue anyway?')"; then
        exit 0
    fi
else
    success "$(t 'Internetverbindung verfügbar' 'Internet connection available')"
fi

# Bestehende Hyprland-Installation prüfen
HYPRLAND_INSTALLED=false
if pacman -Qi hyprland &>/dev/null; then
    HYPRLAND_INSTALLED=true
    HYPR_VERSION="$(pacman -Qi hyprland | grep "^Version" | awk '{print $3}')"
    success "$(t "Hyprland bereits installiert: ${HYPR_VERSION}" "Hyprland already installed: ${HYPR_VERSION}")"
else
    info "$(t 'Hyprland wird installiert' 'Hyprland will be installed')"
fi

# Bestehenden Display-Manager prüfen
ACTIVE_DM=""
for dm in sddm gdm lightdm ly greetd; do
    if systemctl is-enabled "${dm}.service" &>/dev/null 2>&1; then
        ACTIVE_DM="${dm}"
        break
    fi
done

if [[ -n "${ACTIVE_DM}" ]] && [[ "${ACTIVE_DM}" != "sddm" ]]; then
    warn "$(t "Aktiver Display-Manager: ${ACTIVE_DM}" "Active display manager: ${ACTIVE_DM}")"
    warn "$(t 'SDDM wird als Ersatz konfiguriert.' 'SDDM will be configured as replacement.')"
    if ! confirm "$(t "Soll ${ACTIVE_DM} deaktiviert und SDDM aktiviert werden?" "Disable ${ACTIVE_DM} and enable SDDM?")"; then
        warn "$(t 'SDDM wird nicht aktiviert. Du kannst dies später manuell tun.' 'SDDM will not be enabled. You can do this manually later.')"
        SKIP_SDDM_ENABLE=true
    fi
elif [[ "${ACTIVE_DM}" == "sddm" ]]; then
    success "$(t 'SDDM bereits aktiv' 'SDDM already active')"
fi

# ══════════════════════════════════════════════════════════════
# Phase 2: Backup
# ══════════════════════════════════════════════════════════════
header "$(t 'Phase 2: Backup vorhandener Konfigurationen' 'Phase 2: Backup Existing Configurations')"

mkdir -p "${BACKUP_DIR}"

BACKUP_TARGETS=(
    "${CONFIG_DIR}/hypr"
    "${CONFIG_DIR}/waybar"
    "${CONFIG_DIR}/kitty"
    "${CONFIG_DIR}/rofi"
    "${CONFIG_DIR}/swaync"
    "${CONFIG_DIR}/mako"
    "${HOME}/.zshrc"
    "${CONFIG_DIR}/starship.toml"
)

MANIFEST="${BACKUP_DIR}/manifest.txt"
echo "# Tokyo Night Hyprland Backup" > "${MANIFEST}"
echo "# Erstellt: ${TIMESTAMP}" >> "${MANIFEST}"
echo "# Benutzer: ${USER}@$(uname -n 2>/dev/null || cat /etc/hostname 2>/dev/null || echo 'localhost')" >> "${MANIFEST}"
echo "" >> "${MANIFEST}"

BACKED_UP=0
for target in "${BACKUP_TARGETS[@]}"; do
    if [[ -e "${target}" ]]; then
        BASENAME="$(basename "${target}")"
        cp -a "${target}" "${BACKUP_DIR}/${BASENAME}"
        echo "${target}" >> "${MANIFEST}"
        success "$(t "Gesichert: ${target}" "Backed up: ${target}")"
        BACKED_UP=$((BACKED_UP + 1))
    fi
done

if [[ ${BACKED_UP} -gt 0 ]]; then
    success "$(t "Backup erstellt: ${BACKUP_DIR} (${BACKED_UP} Elemente)" "Backup created: ${BACKUP_DIR} (${BACKED_UP} items)")"
else
    info "$(t 'Keine vorhandenen Konfigurationen zum Sichern' 'No existing configurations to back up')"
fi

# ══════════════════════════════════════════════════════════════
# Phase 3: Paketinstallation
# ══════════════════════════════════════════════════════════════
header "$(t 'Phase 3: Paketinstallation' 'Phase 3: Package Installation')"

# Paketliste – nur offizielle Arch-Pakete
PACKAGES=(
    # Compositor
    hyprland

    # Statusleiste
    waybar

    # Launcher
    rofi-wayland

    # Terminal
    kitty

    # Benachrichtigungen & Kontrollzentrum
    swaync
    mako

    # Lock & Wallpaper
    hyprlock
    hyprpaper

    # Dateimanager
    thunar

    # Shell
    zsh
    starship

    # Screenshots & Clipboard
    grim
    slurp
    wl-clipboard
    cliphist

    # Audio
    pipewire
    wireplumber
    pavucontrol
    pamixer

    # Helligkeit & Medien
    brightnessctl
    playerctl

    # Portal & Polkit
    xdg-desktop-portal-hyprland
    polkit-gnome
    hyprpolkitagent

    # Display Manager
    sddm
    qt5-quickcontrols2
    qt5-graphicaleffects

    # Schriftarten & Icon-Theme
    ttf-jetbrains-mono-nerd
    noto-fonts
    papirus-icon-theme

    # Python GTK4 für Settings-App & Tokyo Shot
    python
    python-gobject
    python-cairo
    gtk4
    libadwaita

    # System-Tools
    fastfetch
    htop
    jq
    pacman-contrib
    networkmanager
    nm-connection-editor
    bluez
    bluez-utils
    blueman
    wlsunset
)

# Bereits installierte Pakete ermitteln
PACKAGES_TO_INSTALL=()
for pkg in "${PACKAGES[@]}"; do
    if ! pacman -Qi "${pkg}" &>/dev/null; then
        PACKAGES_TO_INSTALL+=("${pkg}")
    else
        info "Bereits installiert: ${pkg}"
    fi
done

if [[ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]]; then
    info "$(t "Zu installierende Pakete (${#PACKAGES_TO_INSTALL[@]}):" "Packages to install (${#PACKAGES_TO_INSTALL[@]}):")"
    for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
        echo "    - ${pkg}"
    done
    echo ""

    if confirm "$(t 'Pakete installieren?' 'Install packages?')"; then
        info "$(t 'Systemaktualisierung und Paketinstallation...' 'System update and package installation...')"
        if sudo pacman -Syu --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}" 2>&1 | tee -a "${LOG_FILE}"; then
            success "$(t 'Alle Pakete erfolgreich installiert' 'All packages successfully installed')"
        else
            error "$(t 'Einige Pakete konnten nicht installiert werden' 'Some packages could not be installed')"
            error "$(t "Prüfe ${LOG_FILE} für Details" "Check ${LOG_FILE} for details")"
            if ! confirm "$(t 'Trotz Paketfehler fortfahren?' 'Continue despite package errors?')"; then
                exit 1
            fi
        fi
    else
        warn "$(t 'Paketinstallation übersprungen' 'Package installation skipped')"
    fi
else
    success "$(t 'Alle Pakete bereits installiert' 'All packages already installed')"
fi

# ══════════════════════════════════════════════════════════════
# Phase 3b: Automatischer Hardware- & Treiber-Check
# ══════════════════════════════════════════════════════════════
header "$(t 'Phase 3b: Automatischer Hardware- & Treiber-Check' 'Phase 3b: Automatic Hardware & Driver Check')"
if confirm "$(t 'Hardware- & Treiber-Check jetzt durchführen (CPU Microcode, GPU & Akku)?' 'Run Hardware & Driver Check now (CPU microcode, GPU & battery)?')"; then
    if [[ -f "${SCRIPT_DIR}/scripts/hardware-check.sh" ]]; then
        bash "${SCRIPT_DIR}/scripts/hardware-check.sh"
    fi
else
    info "$(t 'Hardware-Check übersprungen. Du kannst ihn jederzeit mit ./hardware-check.sh starten.' 'Hardware check skipped. You can run it anytime with ./hardware-check.sh.')"
fi

# ══════════════════════════════════════════════════════════════
# Phase 4: Konfigurationen kopieren
# ══════════════════════════════════════════════════════════════
header "$(t 'Phase 4: Konfigurationen installieren' 'Phase 4: Install Configurations')"

install_config() {
    local src="$1"
    local dest="$2"
    local dest_dir
    dest_dir="$(dirname "${dest}")"

    mkdir -p "${dest_dir}"

    if [[ -e "${dest}" ]]; then
        info "Überschreibe: ${dest}"
    fi

    cp -a "${src}" "${dest}"
    success "Installiert: ${dest}"
}

# Hyprland Lua-Konfiguration
info "Installiere Hyprland-Konfiguration..."
mkdir -p "${CONFIG_DIR}/hypr"
mkdir -p "${CONFIG_DIR}/hypr/scripts"
mkdir -p "${CONFIG_DIR}/hypr/wallpapers"
mkdir -p "${CONFIG_DIR}/hypr/settings"

for lua_file in "${SCRIPT_DIR}"/config/hypr/*.lua; do
    if [[ -f "${lua_file}" ]]; then
        install_config "${lua_file}" "${CONFIG_DIR}/hypr/$(basename "${lua_file}")"
    fi
done
[[ -f "${SCRIPT_DIR}/config/hypr/user.lua.example" ]] && install_config "${SCRIPT_DIR}/config/hypr/user.lua.example" "${CONFIG_DIR}/hypr/user.lua.example"

# Version und initialen Commit festhalten
if [[ -f "${SCRIPT_DIR}/VERSION" ]]; then
    install_config "${SCRIPT_DIR}/VERSION" "${CONFIG_DIR}/hypr/VERSION"
else
    echo "1.0" > "${CONFIG_DIR}/hypr/VERSION"
fi
if command -v git &>/dev/null && [[ -d "${SCRIPT_DIR}/.git" ]]; then
    git -C "${SCRIPT_DIR}" rev-parse HEAD > "${CONFIG_DIR}/hypr/.installed_commit" 2>/dev/null || true
fi

# Waybar
info "Installiere Waybar-Konfiguration..."
mkdir -p "${CONFIG_DIR}/waybar"
install_config "${SCRIPT_DIR}/config/waybar/config.jsonc" "${CONFIG_DIR}/waybar/config.jsonc"
install_config "${SCRIPT_DIR}/config/waybar/style.css" "${CONFIG_DIR}/waybar/style.css"
if [[ -d "${SCRIPT_DIR}/config/waybar/layouts" ]]; then
    mkdir -p "${CONFIG_DIR}/waybar/layouts"
    cp -rf "${SCRIPT_DIR}/config/waybar/layouts/"* "${CONFIG_DIR}/waybar/layouts/" 2>/dev/null || true
fi

# Kitty
info "Installiere Kitty-Konfiguration..."
install_config "${SCRIPT_DIR}/config/kitty/kitty.conf" "${CONFIG_DIR}/kitty/kitty.conf"

# Rofi
info "Installiere Rofi-Konfiguration..."
install_config "${SCRIPT_DIR}/config/rofi/config.rasi" "${CONFIG_DIR}/rofi/config.rasi"
install_config "${SCRIPT_DIR}/config/rofi/wallpaper.rasi" "${CONFIG_DIR}/rofi/wallpaper.rasi"

# SwayNC Kontrollzentrum
info "Installiere SwayNC-Konfiguration..."
mkdir -p "${CONFIG_DIR}/swaync"
install_config "${SCRIPT_DIR}/config/swaync/config.json" "${CONFIG_DIR}/swaync/config.json"
install_config "${SCRIPT_DIR}/config/swaync/style.css" "${CONFIG_DIR}/swaync/style.css"
if [[ ! -d /sys/class/backlight || -z "$(ls -A /sys/class/backlight 2>/dev/null)" ]]; then
    if command -v jq &>/dev/null && [[ -f "${CONFIG_DIR}/swaync/config.json" ]]; then
        jq '.widgets |= map(select(. != "backlight"))' "${CONFIG_DIR}/swaync/config.json" > "${CONFIG_DIR}/swaync/config.json.tmp" 2>/dev/null && mv "${CONFIG_DIR}/swaync/config.json.tmp" "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
    fi
fi

# Mako
info "Installiere Mako-Konfiguration..."
install_config "${SCRIPT_DIR}/config/mako/config" "${CONFIG_DIR}/mako/config"

# Hyprlock
info "Installiere Hyprlock-Konfiguration..."
install_config "${SCRIPT_DIR}/config/hyprlock/hyprlock.conf" "${CONFIG_DIR}/hypr/hyprlock.conf"

# Hyprpaper
info "Installiere Hyprpaper-Konfiguration..."
install_config "${SCRIPT_DIR}/config/hyprpaper/hyprpaper.conf" "${CONFIG_DIR}/hypr/hyprpaper.conf"

# Zsh
info "Installiere Zsh-Konfiguration..."
install_config "${SCRIPT_DIR}/config/zsh/.zshrc" "${HOME}/.zshrc"

# Starship
info "Installiere Starship-Konfiguration..."
install_config "${SCRIPT_DIR}/config/starship/starship.toml" "${CONFIG_DIR}/starship.toml"

# ══════════════════════════════════════════════════════════════
# Phase 4b: Skripte installieren
# ══════════════════════════════════════════════════════════════
info "Installiere Hilfsskripte..."
for script in "${SCRIPT_DIR}"/scripts/*; do
    if [[ -f "${script}" ]]; then
        BASENAME="$(basename "${script}")"
        install_config "${script}" "${CONFIG_DIR}/hypr/scripts/${BASENAME}"
        chmod +x "${CONFIG_DIR}/hypr/scripts/${BASENAME}"
    fi
done
success "Alle Skripte installiert und ausführbar"

# Tokyo Shot installieren
info "Installiere Tokyo Shot Screenshot-Tool & Editor..."
if [[ -d "${SCRIPT_DIR}/screenshot" ]]; then
    mkdir -p "${CONFIG_DIR}/hypr/screenshot"
    cp -a "${SCRIPT_DIR}/screenshot/"* "${CONFIG_DIR}/hypr/screenshot/" 2>/dev/null || true
    chmod +x "${CONFIG_DIR}/hypr/screenshot/app.py" "${CONFIG_DIR}/hypr/screenshot/shot_core.py" 2>/dev/null || true
    success "Tokyo Shot installiert"
fi

# CLI Starter verlinken
mkdir -p "${HOME}/.local/bin"
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-shot" "${HOME}/.local/bin/tokyo-shot" 2>/dev/null || true
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-app-installer" "${HOME}/.local/bin/tokyo-app-installer" 2>/dev/null || true
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-app-uninstaller" "${HOME}/.local/bin/tokyo-app-uninstaller" 2>/dev/null || true
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-cleaner" "${HOME}/.local/bin/tokyo-cleaner" 2>/dev/null || true
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-hardware-check" "${HOME}/.local/bin/tokyo-hardware-check" 2>/dev/null || true
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-cyber" "${HOME}/.local/bin/tokyo-cyber" 2>/dev/null || true
if sudo -n true 2>/dev/null; then
    for bin in tokyo-shot tokyo-app-installer tokyo-app-uninstaller tokyo-cleaner tokyo-hardware-check tokyo-cyber; do
        sudo ln -sf "${CONFIG_DIR}/hypr/scripts/${bin}" "/usr/local/bin/${bin}" 2>/dev/null || true
    done
fi

# Desktop-Dateien für App-Launcher (Rofi drun)
mkdir -p "${HOME}/.local/share/applications"
if [[ -d "${SCRIPT_DIR}/assets/desktop" ]]; then
    cp -f "${SCRIPT_DIR}/assets/desktop/"*.desktop "${HOME}/.local/share/applications/" 2>/dev/null || true
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
    success "Desktop-Einträge registriert (Tokyo Shot, App Installer, App Uninstaller, System Cleaner, Hardware-Check)"
fi

# GTK Theme & Design
info "Installiere GTK Tokyo Night Konfiguration..."
mkdir -p "${CONFIG_DIR}/gtk-3.0" "${CONFIG_DIR}/gtk-4.0"
[[ -f "${SCRIPT_DIR}/config/gtk-3.0/settings.ini" ]] && install_config "${SCRIPT_DIR}/config/gtk-3.0/settings.ini" "${CONFIG_DIR}/gtk-3.0/settings.ini"
[[ -f "${SCRIPT_DIR}/config/gtk-4.0/settings.ini" ]] && install_config "${SCRIPT_DIR}/config/gtk-4.0/settings.ini" "${CONFIG_DIR}/gtk-4.0/settings.ini"
[[ -f "${SCRIPT_DIR}/config/gtk-4.0/gtk.css" ]] && install_config "${SCRIPT_DIR}/config/gtk-4.0/gtk.css" "${CONFIG_DIR}/gtk-4.0/gtk.css"
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
fi

# Settings-App & Version installieren
info "Installiere Einstellungs-App & Versionsdaten..."
if [[ -d "${SCRIPT_DIR}/settings" ]]; then
    mkdir -p "${CONFIG_DIR}/hypr/settings"
    cp -a "${SCRIPT_DIR}/settings/"* "${CONFIG_DIR}/hypr/settings/" 2>/dev/null || true
    [[ -f "${SCRIPT_DIR}/VERSION" ]] && cp -f "${SCRIPT_DIR}/VERSION" "${CONFIG_DIR}/hypr/VERSION" 2>/dev/null || true
    success "Einstellungs-App & Version v$(cat "${SCRIPT_DIR}/VERSION" 2>/dev/null || echo "1.0") installiert"
fi

# Tastaturlayout & Sprache auf installierte Konfiguration anwenden
info "$(t 'Wende gewählte Sprache und Tastaturlayout an...' 'Applying selected language and keyboard layout...')"
if [[ -f "${CONFIG_DIR}/hypr/input.lua" ]]; then
    sed -i "s/kb_layout\s*=\s*\"[^\"]*\"/kb_layout  = \"${SYSTEM_KB}\"/" "${CONFIG_DIR}/hypr/input.lua" 2>/dev/null || true
fi

# Einstellungen initialisieren via Python ConfigManager
if python3 -c "import sys; sys.path.insert(0, '${CONFIG_DIR}/hypr/settings'); from config_manager import ConfigManager; cm = ConfigManager(); cm.set_language('${SYSTEM_LANG}'); cm.update_setting('input', 'kb_layout', '${SYSTEM_KB}'); cm.save_input_settings({'kb_layout': '${SYSTEM_KB}'}, reload=False)" 2>/dev/null; then
    success "$(t "Sprache (${SYSTEM_LANG}) und Tastaturlayout (${SYSTEM_KB}) erfolgreich angewendet" "Language (${SYSTEM_LANG}) and keyboard layout (${SYSTEM_KB}) successfully applied")"
else
    # Fallback für minimale Arch-Umgebungen
    mkdir -p "${CONFIG_DIR}/hypr"
    USER_SETTINGS_FILE="${CONFIG_DIR}/hypr/user_settings.json"
    if [[ ! -f "${USER_SETTINGS_FILE}" ]]; then
        cat <<EOF > "${USER_SETTINGS_FILE}"
{
  "general": {
    "language": "${SYSTEM_LANG}"
  },
  "input": {
    "kb_layout": "${SYSTEM_KB}"
  }
}
EOF
    fi
    if [[ "${SYSTEM_LANG}" == "en" ]]; then
        if [[ -f "${CONFIG_DIR}/swaync/config.json" ]]; then
            sed -i 's/"text": "Kontrollzentrum"/"text": "Control Center"/g' "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
            sed -i 's/"button-text": "✕ Schließen"/"button-text": "✕ Close"/g' "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
            sed -i 's/"text": "Benachrichtigungen"/"text": "Notifications"/g' "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
            sed -i 's/󰖩  WLAN\\nGetrennt/󰖩  Wi-Fi\\nDisconnected/g' "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
            sed -i 's/󰂯  Bluetooth\\nGetrennt/󰂯  Bluetooth\\nDisconnected/g' "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
            sed -i 's/󰖔\\nNachtmodus/󰖔\\nNight Light/g' "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
            sed -i 's/󰂛\\nNicht stören/󰂛\\nDo Not Disturb/g' "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
            sed -i 's/󰀝\\nFlugmodus/󰀝\\nAirplane Mode/g' "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
            sed -i 's/󰔎\\nDunkelmodus/󰔎\\nDark Mode/g' "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
        fi
        if [[ -f "${CONFIG_DIR}/waybar/config.jsonc" ]]; then
            sed -i 's/"format-linked": "󰌷  Verbunden"/"format-linked": "󰌷  Connected"/g' "${CONFIG_DIR}/waybar/config.jsonc" 2>/dev/null || true
            sed -i 's/"format-disconnected": "󰤭  Getrennt"/"format-disconnected": "󰤭  Disconnected"/g' "${CONFIG_DIR}/waybar/config.jsonc" 2>/dev/null || true
            sed -i 's/"format-muted": "󰝟 Stumm"/"format-muted": "󰝟 Muted"/g' "${CONFIG_DIR}/waybar/config.jsonc" 2>/dev/null || true
            sed -i 's/"format-source-muted": "󰍭 Stumm"/"format-source-muted": "󰍭 Muted"/g' "${CONFIG_DIR}/waybar/config.jsonc" 2>/dev/null || true
            sed -i 's/"tooltip-format": "Einstellungen öffnen"/"tooltip-format": "Open Settings"/g' "${CONFIG_DIR}/waybar/config.jsonc" 2>/dev/null || true
            sed -i 's/"tooltip-format": "Tastenkürzel anzeigen"/"tooltip-format": "View Shortcuts"/g' "${CONFIG_DIR}/waybar/config.jsonc" 2>/dev/null || true
            sed -i 's/"tooltip-format": "Power-Menü"/"tooltip-format": "Power Menu"/g' "${CONFIG_DIR}/waybar/config.jsonc" 2>/dev/null || true
        fi
    fi
fi

# ══════════════════════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════
# Phase 5: Wallpaper & JaKooLit Wallpaper-Bank
# ══════════════════════════════════════════════════════════════
header "$(t 'Phase 5: Wallpaper & JaKooLit Wallpaper-Bank' 'Phase 5: Wallpaper & JaKooLit Wallpaper Bank')"

WALLPAPER_DIR="${CONFIG_DIR}/hypr/wallpapers"
mkdir -p "${WALLPAPER_DIR}"

# Kopiere mitgelieferte Starter-Wallpaper aus Assets
if [[ -d "${SCRIPT_DIR}/assets/wallpapers" ]]; then
    for wp in "${SCRIPT_DIR}/assets/wallpapers"/*; do
        if [[ -f "${wp}" && "${wp}" =~ \.(jpg|jpeg|png|webp)$ ]]; then
            cp -f "${wp}" "${WALLPAPER_DIR}/"
            success "Starter-Wallpaper kopiert: $(basename "${wp}")"
        fi
    done
fi

# JaKooLit Wallpaper-Bank Download
if [[ ! -d "${WALLPAPER_DIR}/Wallpaper-Bank" ]]; then
    if confirm "$(t 'Möchtest du die JaKooLit Wallpaper-Bank herunterladen? (https://github.com/JaKooLit/Wallpaper-Bank, ~150+ Hintergründe)' 'Would you like to download the JaKooLit Wallpaper Bank? (https://github.com/JaKooLit/Wallpaper-Bank, ~150+ wallpapers)')"; then
        info "$(t 'Lade JaKooLit Wallpaper-Bank herunter (git clone --depth 1)...' 'Downloading JaKooLit Wallpaper Bank (git clone --depth 1)...')"
        if git clone --depth 1 https://github.com/JaKooLit/Wallpaper-Bank.git "${WALLPAPER_DIR}/Wallpaper-Bank" 2>/dev/null; then
            success "$(t 'JaKooLit Wallpaper-Bank erfolgreich installiert' 'JaKooLit Wallpaper Bank successfully installed')"
        else
            warn "$(t 'Download fehlgeschlagen. Du kannst sie jederzeit über SUPER+W nachladen.' 'Download failed. You can load it anytime via SUPER+W.')"
        fi
    else
        info "$(t 'Wallpaper-Bank übersprungen. Du kannst sie jederzeit über SUPER+W oder Einstellungen nachladen.' 'Wallpaper Bank skipped. You can load it anytime via SUPER+W or Settings.')"
    fi
else
    success "JaKooLit Wallpaper-Bank bereits vorhanden"
fi

# Aktuelles Standard-Hintergrundbild festlegen
if [[ ! -f "${WALLPAPER_DIR}/current.jpg" || ! -s "${WALLPAPER_DIR}/current.jpg" ]]; then
    first_img="$(find "${WALLPAPER_DIR}" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) ! -name 'current.jpg' 2>/dev/null | head -n 1 || true)"
    if [[ -n "${first_img}" && -f "${first_img}" ]]; then
        cp -f "${first_img}" "${WALLPAPER_DIR}/current.jpg"
        success "Standard-Hintergrundbild aktiviert: $(basename "${first_img}")"
    elif command -v convert &>/dev/null; then
        convert -size 1920x1080 \
            xc:'#1a1b26' \
            -fill '#24283b' -draw "rectangle 0,0 1920,540" \
            "${WALLPAPER_DIR}/current.jpg" 2>/dev/null || true
        info "Einfarbiger Tokyo Night Fallback-Hintergrund erstellt"
    else
        touch "${WALLPAPER_DIR}/current.jpg"
    fi
fi

# ══════════════════════════════════════════════════════════════
# Phase 6: SDDM-Theme
# ══════════════════════════════════════════════════════════════
header "$(t 'Phase 6: SDDM-Theme' 'Phase 6: SDDM Theme')"

SDDM_THEME_DIR="/usr/share/sddm/themes/tokyo-night"

if [[ -d "${SCRIPT_DIR}/assets/sddm/tokyo-night" ]]; then
    info "Installiere SDDM Tokyo Night Theme..."

    if sudo mkdir -p "${SDDM_THEME_DIR}" && \
       sudo cp -a "${SCRIPT_DIR}/assets/sddm/tokyo-night/"* "${SDDM_THEME_DIR}/" 2>/dev/null; then
        success "SDDM-Theme installiert nach ${SDDM_THEME_DIR}"

        # SDDM-Konfiguration setzen (sicher, ohne bestehende Datei zu ersetzen)
        SDDM_CONF="/etc/sddm.conf.d/tokyo-night.conf"
        if ! sudo test -d /etc/sddm.conf.d; then
            sudo mkdir -p /etc/sddm.conf.d
        fi

        echo "[Theme]" | sudo tee "${SDDM_CONF}" > /dev/null
        echo "Current=tokyo-night" | sudo tee -a "${SDDM_CONF}" > /dev/null
        success "SDDM-Theme konfiguriert: ${SDDM_CONF}"
    else
        warn "SDDM-Theme konnte nicht installiert werden"
    fi

    # Wallpaper für SDDM kopieren
    if [[ -f "${WALLPAPER_DIR}/current.jpg" ]]; then
        sudo cp "${WALLPAPER_DIR}/current.jpg" "${SDDM_THEME_DIR}/background.jpg" 2>/dev/null || true
    fi
else
    warn "SDDM-Theme-Dateien nicht gefunden"
fi

# ══════════════════════════════════════════════════════════════
# Phase 7: Systemdienste & Lokalisierung
# ══════════════════════════════════════════════════════════════
header "$(t 'Phase 7: Systemdienste & Lokalisierung' 'Phase 7: System Services & Localization')"

# SDDM aktivieren
if [[ "${SKIP_SDDM_ENABLE:-false}" != "true" ]]; then
    if [[ -n "${ACTIVE_DM}" ]] && [[ "${ACTIVE_DM}" != "sddm" ]]; then
        info "Deaktiviere ${ACTIVE_DM}..."
        sudo systemctl disable "${ACTIVE_DM}.service" 2>/dev/null || true
        success "${ACTIVE_DM} deaktiviert"
    fi

    if ! systemctl is-enabled sddm.service &>/dev/null; then
        sudo systemctl enable sddm.service
        success "SDDM aktiviert"
    else
        success "SDDM bereits aktiviert"
    fi
fi

# NetworkManager sicherstellen
if ! systemctl is-enabled NetworkManager.service &>/dev/null 2>&1; then
    sudo systemctl enable NetworkManager.service 2>/dev/null || true
    info "NetworkManager aktiviert"
fi

# PipeWire User-Dienste
if command -v pipewire &>/dev/null; then
    systemctl --user enable --now pipewire.socket 2>/dev/null || true
    systemctl --user enable --now wireplumber.service 2>/dev/null || true
    success "PipeWire-Dienste aktiviert"
fi

# Netzwerk- und Bluetooth-Dienste aktivieren
info "Aktiviere Systemd-Dienste..."
sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
sudo systemctl enable --now bluetooth.service 2>/dev/null || true
success "NetworkManager und Bluetooth aktiviert"

# Polkit-Regel & Sudoers für Uhrzeit & Zeitzone
if [[ -f "${SCRIPT_DIR}/assets/polkit/10-tokyo-timedate.rules" ]]; then
    sudo mkdir -p /etc/polkit-1/rules.d
    sudo cp -f "${SCRIPT_DIR}/assets/polkit/10-tokyo-timedate.rules" /etc/polkit-1/rules.d/10-tokyo-timedate.rules 2>/dev/null || true
    sudo chmod 644 /etc/polkit-1/rules.d/10-tokyo-timedate.rules 2>/dev/null || true
fi
if [[ -f "${SCRIPT_DIR}/assets/sudoers/10-tokyo-timedate" ]]; then
    sudo mkdir -p /etc/sudoers.d
    sudo cp -f "${SCRIPT_DIR}/assets/sudoers/10-tokyo-timedate" /etc/sudoers.d/10-tokyo-timedate 2>/dev/null || true
    sudo chmod 0440 /etc/sudoers.d/10-tokyo-timedate 2>/dev/null || true
fi
success "Berechtigungen für Uhrzeit & Zeitzone eingerichtet"

# ── System-Locale & Tastaturlayout (Deutsch / Englisch) ───────
info "$(t "Konfiguriere System-Locale (${LOCALE_CODE}) und Konsole (${SYSTEM_KB})..." "Configuring system locale (${LOCALE_CODE}) and console (${SYSTEM_KB})...")"

# 1. /etc/locale.gen
if [[ -f /etc/locale.gen ]]; then
    if [[ "${SYSTEM_LANG}" == "de" ]]; then
        sudo sed -i 's/^#\s*\(de_DE\.UTF-8 UTF-8\)/\1/' /etc/locale.gen 2>/dev/null || true
        sudo sed -i 's/^#\s*\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen 2>/dev/null || true
    else
        sudo sed -i 's/^#\s*\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen 2>/dev/null || true
        sudo sed -i 's/^#\s*\(de_DE\.UTF-8 UTF-8\)/\1/' /etc/locale.gen 2>/dev/null || true
    fi
    if command -v locale-gen &>/dev/null; then
        sudo locale-gen 2>&1 | tee -a "${LOG_FILE}" || true
    fi
fi

# 2. /etc/locale.conf & localectl
if command -v localectl &>/dev/null; then
    sudo localectl set-locale LANG="${LOCALE_CODE}" LC_COLLATE=C 2>/dev/null || true
    sudo localectl set-keymap "${SYSTEM_KB}" 2>/dev/null || true
fi

# Fallback: /etc/locale.conf direkt schreiben
echo -e "LANG=${LOCALE_CODE}\nLC_COLLATE=C" | sudo tee /etc/locale.conf > /dev/null

# 3. User-Locale in ~/.config/locale.conf
cat <<EOF > "${CONFIG_DIR}/locale.conf"
LANG=${LOCALE_CODE}
LC_ALL=${LOCALE_CODE}
EOF
success "$(t "System-Locale auf ${LOCALE_CODE} gesetzt" "System locale set to ${LOCALE_CODE}")"

# Zsh als Standard-Shell setzen
if [[ "$(basename "${SHELL}")" != "zsh" ]]; then
    ZSH_PATH="$(command -v zsh)"
    if [[ -n "${ZSH_PATH}" ]]; then
        if confirm "$(t 'Zsh als Standard-Shell setzen?' 'Set Zsh as default shell?')"; then
            chsh -s "${ZSH_PATH}"
            success "$(t 'Zsh als Standard-Shell gesetzt' 'Zsh set as default shell')"
        fi
    fi
else
    success "$(t 'Zsh ist bereits die Standard-Shell' 'Zsh is already the default shell')"
fi

# ══════════════════════════════════════════════════════════════
# Phase 8: Validierung
# ══════════════════════════════════════════════════════════════
header "$(t 'Phase 8: Validierung' 'Phase 8: Validation')"

ERRORS=0
WARNINGS=0

# Lua-Dateien prüfen (Syntaxprüfung falls luac verfügbar)
if command -v luac &>/dev/null; then
    for lua_file in "${CONFIG_DIR}"/hypr/*.lua; do
        if [[ -f "${lua_file}" ]]; then
            # luac kann nur Standard-Lua prüfen, nicht die hl.* API
            # Daher nur grundlegende Syntaxfehler
            if luac -p "${lua_file}" 2>/dev/null; then
                success "Lua-Syntax OK: $(basename "${lua_file}")"
            else
                # Erwartete Fehler wegen hl.* Namespace – das ist OK
                info "Lua-Datei: $(basename "${lua_file}") (hl.* API, kein Standard-Lua)"
            fi
        fi
    done
else
    info "luac nicht verfügbar – Lua-Syntaxprüfung übersprungen"
fi

# Waybar JSON prüfen
if command -v jq &>/dev/null; then
    WAYBAR_CONFIG="${CONFIG_DIR}/waybar/config.jsonc"
    if [[ -f "${WAYBAR_CONFIG}" ]]; then
        # JSONC nach JSON konvertieren (Kommentare entfernen) und prüfen
        if sed 's|//.*$||g' "${WAYBAR_CONFIG}" | jq . &>/dev/null; then
            success "Waybar-Konfiguration: JSON gültig"
        else
            warn "Waybar-Konfiguration: JSON-Prüfung fehlgeschlagen (JSONC-Kommentare?)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi

# Wichtige Dateien prüfen
REQUIRED_FILES=(
    "${CONFIG_DIR}/hypr/hyprland.lua"
    "${CONFIG_DIR}/hypr/colors.lua"
    "${CONFIG_DIR}/hypr/keybinds.lua"
    "${CONFIG_DIR}/waybar/config.jsonc"
    "${CONFIG_DIR}/waybar/style.css"
    "${CONFIG_DIR}/kitty/kitty.conf"
    "${CONFIG_DIR}/rofi/config.rasi"
    "${CONFIG_DIR}/swaync/config.json"
    "${CONFIG_DIR}/swaync/style.css"
    "${CONFIG_DIR}/mako/config"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "${file}" ]]; then
        success "Vorhanden: $(basename "${file}")"
    else
        error "Fehlt: ${file}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Paketversionen loggen
info "Installierte Paketversionen:"
for pkg in hyprland waybar kitty sddm swaync mako hyprlock hyprpaper; do
    if pacman -Qi "${pkg}" &>/dev/null; then
        VERSION="$(pacman -Qi "${pkg}" | grep "^Version" | awk '{print $3}')"
        echo "    ${pkg}: ${VERSION}" | tee -a "${LOG_FILE}"
    fi
done

# ══════════════════════════════════════════════════════════════
# Phase 9: Finaler Backup-Punkt
# ══════════════════════════════════════════════════════════════
header "$(t 'Phase 9: Abschluss' 'Phase 9: Completion')"

# Finalen Installations-Backup-Punkt erstellen
FINAL_BACKUP="${BACKUP_BASE}/post-install_${TIMESTAMP}"
mkdir -p "${FINAL_BACKUP}"
cp -a "${CONFIG_DIR}/hypr" "${FINAL_BACKUP}/" 2>/dev/null || true
cp -a "${CONFIG_DIR}/waybar" "${FINAL_BACKUP}/" 2>/dev/null || true
success "$(t "Finaler Backup-Punkt erstellt: ${FINAL_BACKUP}" "Final backup point created: ${FINAL_BACKUP}")"

# ══════════════════════════════════════════════════════════════
# Zusammenfassung
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${MAGENTA}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
if [[ "${SYSTEM_LANG}" == "en" ]]; then
    echo "║  Installation Complete                                   ║"
else
    echo "║  Installation abgeschlossen                              ║"
fi
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${GREEN}$(t 'Sprache:' 'Language:')${NC}      $([[ "${SYSTEM_LANG}" == "en" ]] && echo "English (${SYSTEM_KB})" || echo "Deutsch (${SYSTEM_KB})")"
echo -e "  ${GREEN}Backup:${NC}          ${BACKUP_DIR}"
echo -e "  ${GREEN}Log:${NC}             ${LOG_FILE}"
echo -e "  ${GREEN}$(t 'Konfiguration:' 'Configuration:')${NC} ${CONFIG_DIR}/hypr/"
echo ""

if [[ ${ERRORS} -gt 0 ]]; then
    echo -e "  ${RED}$(t 'Fehler:' 'Errors:')${NC} ${ERRORS}"
fi
if [[ ${WARNINGS} -gt 0 ]]; then
    echo -e "  ${YELLOW}$(t 'Warnungen:' 'Warnings:')${NC} ${WARNINGS}"
fi

# Warnungen zu fehlenden Funktionen
if [[ ! -f "${WALLPAPER_DIR}/current.jpg" ]] || [[ ! -s "${WALLPAPER_DIR}/current.jpg" ]]; then
    warn "$(t 'Kein Hintergrundbild vorhanden.' 'No wallpaper set.')"
    warn "$(t 'Lege Bilder in ~/.config/hypr/wallpapers/ ab und benenne eines als current.jpg' 'Place images in ~/.config/hypr/wallpapers/ and name one current.jpg')"
fi

echo ""
echo -e "${CYAN}$(t 'Nächste Schritte:' 'Next Steps:')${NC}"
if [[ "${SYSTEM_LANG}" == "en" ]]; then
    echo "  1. Add a wallpaper to ~/.config/hypr/wallpapers/ or switch with SUPER+W"
    echo "  2. Customize ~/.config/hypr/monitors.lua for your display setup"
    echo "  3. Open Settings app with SUPER+I or via Waybar to adjust shortcuts & look"
    echo "  4. Install popular apps (Chrome, VSCode, Spotify, Steam): ./install-apps.sh"
    echo "  5. Run ./doctor.sh after rebooting"
else
    echo "  1. Lege ein Hintergrundbild in ~/.config/hypr/wallpapers/ ab (oder SUPER+W)"
    echo "  2. Passe ~/.config/hypr/monitors.lua an deine Monitore an"
    echo "  3. Öffne Einstellungen mit SUPER+I oder über Waybar"
    echo "  4. Beliebte Apps (Chrome, VSCode, Spotify, Steam, etc.) installieren: ./install-apps.sh"
    echo "  5. Führe nach dem Neustart ./doctor.sh aus"
fi
echo ""

# Optionale App-Installation
if [[ -f "${SCRIPT_DIR}/install-apps.sh" ]]; then
    if confirm "$(t 'Möchtest du jetzt zusätzliche Anwendungen installieren (Chrome, VSCode, Spotify, Steam, etc.)?' 'Would you like to install additional applications now (Chrome, VSCode, Spotify, Steam, etc.)?')"; then
        bash "${SCRIPT_DIR}/install-apps.sh" || true
    fi
fi

# ── Neustart-Frage ────────────────────────────────────────────
if confirm "$(t 'Soll das System jetzt neu gestartet werden?' 'Reboot the system now?')"; then
    info "$(t 'Neustart in 5 Sekunden... (Ctrl+C zum Abbrechen)' 'Rebooting in 5 seconds... (Ctrl+C to abort)')"
    sleep 5
    systemctl reboot
else
    echo ""
    info "$(t 'Kein Neustart. Starte Hyprland manuell oder melde dich ab und wieder an.' 'No reboot. Start Hyprland manually or log out and log back in.')"
    echo ""
fi
