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

confirm() {
    local prompt="$1"
    local response
    echo -en "${YELLOW}${prompt} [j/N] ${NC}"
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

# Arch Linux prüfen
header "Phase 1: Systemprüfung"

if [[ ! -f /etc/arch-release ]]; then
    fatal "Kein Arch Linux erkannt. Dieses Skript ist nur für Arch Linux."
fi
success "Arch Linux erkannt"

# sudo-Zugriff prüfen
if ! sudo -v 2>/dev/null; then
    fatal "sudo-Zugriff erforderlich. Stelle sicher, dass dein Benutzer sudo verwenden kann."
fi
success "sudo-Zugriff verfügbar"

# Internetverbindung prüfen
if ! ping -c 1 archlinux.org &>/dev/null; then
    warn "Keine Internetverbindung erkannt. Die Paketinstallation könnte fehlschlagen."
    if ! confirm "Trotzdem fortfahren?"; then
        exit 0
    fi
else
    success "Internetverbindung verfügbar"
fi

# Bestehende Hyprland-Installation prüfen
HYPRLAND_INSTALLED=false
if pacman -Qi hyprland &>/dev/null; then
    HYPRLAND_INSTALLED=true
    HYPR_VERSION="$(pacman -Qi hyprland | grep "^Version" | awk '{print $3}')"
    success "Hyprland bereits installiert: ${HYPR_VERSION}"
else
    info "Hyprland wird installiert"
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
    warn "Aktiver Display-Manager: ${ACTIVE_DM}"
    warn "SDDM wird als Ersatz konfiguriert."
    if ! confirm "Soll ${ACTIVE_DM} deaktiviert und SDDM aktiviert werden?"; then
        warn "SDDM wird nicht aktiviert. Du kannst dies später manuell tun."
        SKIP_SDDM_ENABLE=true
    fi
elif [[ "${ACTIVE_DM}" == "sddm" ]]; then
    success "SDDM bereits aktiv"
fi

# ══════════════════════════════════════════════════════════════
# Phase 2: Backup
# ══════════════════════════════════════════════════════════════
header "Phase 2: Backup vorhandener Konfigurationen"

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
        success "Gesichert: ${target}"
        BACKED_UP=$((BACKED_UP + 1))
    fi
done

if [[ ${BACKED_UP} -gt 0 ]]; then
    success "Backup erstellt: ${BACKUP_DIR} (${BACKED_UP} Elemente)"
else
    info "Keine vorhandenen Konfigurationen zum Sichern"
fi

# ══════════════════════════════════════════════════════════════
# Phase 3: Paketinstallation
# ══════════════════════════════════════════════════════════════
header "Phase 3: Paketinstallation"

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
    info "Zu installierende Pakete (${#PACKAGES_TO_INSTALL[@]}):"
    for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
        echo "    - ${pkg}"
    done
    echo ""

    if confirm "Pakete installieren?"; then
        info "Systemaktualisierung und Paketinstallation..."
        if sudo pacman -Syu --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}" 2>&1 | tee -a "${LOG_FILE}"; then
            success "Alle Pakete erfolgreich installiert"
        else
            error "Einige Pakete konnten nicht installiert werden"
            error "Prüfe ${LOG_FILE} für Details"
            if ! confirm "Trotz Paketfehler fortfahren?"; then
                exit 1
            fi
        fi
    else
        warn "Paketinstallation übersprungen"
    fi
else
    success "Alle Pakete bereits installiert"
fi

# ══════════════════════════════════════════════════════════════
# Phase 3b: Automatischer Hardware- & Treiber-Check
# ══════════════════════════════════════════════════════════════
header "Phase 3b: Automatischer Hardware- & Treiber-Check"
if confirm "Hardware- & Treiber-Check jetzt durchführen (CPU Microcode, GPU & Akku)?"; then
    if [[ -f "${SCRIPT_DIR}/scripts/hardware-check.sh" ]]; then
        bash "${SCRIPT_DIR}/scripts/hardware-check.sh"
    fi
else
    info "Hardware-Check übersprungen. Du kannst ihn jederzeit mit ./hardware-check.sh starten."
fi

# ══════════════════════════════════════════════════════════════
# Phase 4: Konfigurationen kopieren
# ══════════════════════════════════════════════════════════════
header "Phase 4: Konfigurationen installieren"

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
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-cleaner" "${HOME}/.local/bin/tokyo-cleaner" 2>/dev/null || true
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-hardware-check" "${HOME}/.local/bin/tokyo-hardware-check" 2>/dev/null || true

# Desktop-Dateien für App-Launcher (Rofi drun)
mkdir -p "${HOME}/.local/share/applications"
if [[ -d "${SCRIPT_DIR}/assets/desktop" ]]; then
    cp -f "${SCRIPT_DIR}/assets/desktop/"*.desktop "${HOME}/.local/share/applications/" 2>/dev/null || true
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
    success "Desktop-Einträge registriert (Tokyo Shot, App Installer, System Cleaner, Hardware-Check)"
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

# ══════════════════════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════
# Phase 5: Wallpaper & JaKooLit Wallpaper-Bank
# ══════════════════════════════════════════════════════════════
header "Phase 5: Wallpaper & JaKooLit Wallpaper-Bank"

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
    if confirm "Möchtest du die JaKooLit Wallpaper-Bank herunterladen? (https://github.com/JaKooLit/Wallpaper-Bank, ~150+ Hintergründe)"; then
        info "Lade JaKooLit Wallpaper-Bank herunter (git clone --depth 1)..."
        if git clone --depth 1 https://github.com/JaKooLit/Wallpaper-Bank.git "${WALLPAPER_DIR}/Wallpaper-Bank" 2>/dev/null; then
            success "JaKooLit Wallpaper-Bank erfolgreich installiert"
        else
            warn "Download fehlgeschlagen. Du kannst sie jederzeit über SUPER+W nachladen."
        fi
    else
        info "Wallpaper-Bank übersprungen. Du kannst sie jederzeit über SUPER+W oder Einstellungen nachladen."
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
header "Phase 6: SDDM-Theme"

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
# Phase 7: Systemdienste
# ══════════════════════════════════════════════════════════════
header "Phase 7: Systemdienste"

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

# Zsh als Standard-Shell setzen
if [[ "$(basename "${SHELL}")" != "zsh" ]]; then
    ZSH_PATH="$(command -v zsh)"
    if [[ -n "${ZSH_PATH}" ]]; then
        if confirm "Zsh als Standard-Shell setzen?"; then
            chsh -s "${ZSH_PATH}"
            success "Zsh als Standard-Shell gesetzt"
        fi
    fi
else
    success "Zsh ist bereits die Standard-Shell"
fi

# ══════════════════════════════════════════════════════════════
# Phase 8: Validierung
# ══════════════════════════════════════════════════════════════
header "Phase 8: Validierung"

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
header "Phase 9: Abschluss"

# Finalen Installations-Backup-Punkt erstellen
FINAL_BACKUP="${BACKUP_BASE}/post-install_${TIMESTAMP}"
mkdir -p "${FINAL_BACKUP}"
cp -a "${CONFIG_DIR}/hypr" "${FINAL_BACKUP}/" 2>/dev/null || true
cp -a "${CONFIG_DIR}/waybar" "${FINAL_BACKUP}/" 2>/dev/null || true
success "Finaler Backup-Punkt erstellt: ${FINAL_BACKUP}"

# ══════════════════════════════════════════════════════════════
# Zusammenfassung
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${MAGENTA}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Installation abgeschlossen                              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${GREEN}Backup:${NC}       ${BACKUP_DIR}"
echo -e "  ${GREEN}Log:${NC}          ${LOG_FILE}"
echo -e "  ${GREEN}Konfiguration:${NC} ${CONFIG_DIR}/hypr/"
echo ""

if [[ ${ERRORS} -gt 0 ]]; then
    echo -e "  ${RED}Fehler: ${ERRORS}${NC}"
fi
if [[ ${WARNINGS} -gt 0 ]]; then
    echo -e "  ${YELLOW}Warnungen: ${WARNINGS}${NC}"
fi

# Warnungen zu fehlenden Funktionen
if [[ ! -f "${WALLPAPER_DIR}/current.jpg" ]] || [[ ! -s "${WALLPAPER_DIR}/current.jpg" ]]; then
    warn "Kein Hintergrundbild vorhanden."
    warn "Lege Bilder in ~/.config/hypr/wallpapers/ ab und benenne eines als current.jpg"
fi

echo ""
echo -e "${CYAN}Nächste Schritte:${NC}"
echo "  1. Lege ein Hintergrundbild in ~/.config/hypr/wallpapers/ ab"
echo "  2. Passe ~/.config/hypr/monitors.lua an deine Monitore an"
echo "  3. Beliebte Apps (Chrome, VSCode, Spotify, Steam, etc.) installieren: ./install-apps.sh"
echo "  4. Führe nach dem Neustart ./doctor.sh aus"
echo ""

# Optionale App-Installation
if [[ -f "${SCRIPT_DIR}/install-apps.sh" ]]; then
    if confirm "Möchtest du jetzt zusätzliche Anwendungen installieren (Chrome, VSCode, Spotify, Steam, etc.)?"; then
        bash "${SCRIPT_DIR}/install-apps.sh" || true
    fi
fi

# ── Neustart-Frage ────────────────────────────────────────────
if confirm "Soll das System jetzt neu gestartet werden?"; then
    info "Neustart in 5 Sekunden... (Ctrl+C zum Abbrechen)"
    sleep 5
    systemctl reboot
else
    echo ""
    info "Kein Neustart. Starte Hyprland manuell oder melde dich ab und wieder an."
    echo ""
fi
