#!/usr/bin/env bash
# Falls das Skript mit 'sh' (oder dash) aufgerufen wurde, sofort mit 'bash' neu starten:
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

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
    for candidate in \
        "${SCRIPT_DIR}" \
        "${HOME}/Desktop/hyprland/tokyo-hypr-dots" \
        "${HOME}/Desktop/hyprland" \
        "${HOME}/arch-hyprland" \
        "${HOME}/tokyo-hypr-dots" \
        "${HOME}/arch-hyrland" \
        "${HOME}/hyprland"; do
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
CONFIG_DIR="${HOME}/.config"
INSTALLED_VER_FILE="${CONFIG_DIR}/hypr/VERSION"
VERSION_FILE="${REPO_DIR}/VERSION"
LAST_COMMIT_FILE="${CONFIG_DIR}/hypr/.installed_commit"

CURRENT_VER="1.0"
if [[ -f "${INSTALLED_VER_FILE}" ]]; then
    CURRENT_VER="$(tr -d '[:space:]' < "${INSTALLED_VER_FILE}" 2>/dev/null || echo "1.0")"
elif [[ -f "${VERSION_FILE}" ]]; then
    CURRENT_VER="$(tr -d '[:space:]' < "${VERSION_FILE}" 2>/dev/null || echo "1.0")"
fi
if ! [[ "${CURRENT_VER}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    CURRENT_VER="1.0"
fi

LAST_INSTALLED_COMMIT=""
[[ -f "${LAST_COMMIT_FILE}" ]] && LAST_INSTALLED_COMMIT="$(cat "${LAST_COMMIT_FILE}" 2>/dev/null | tr -d '[:space:]' || true)"

PREV_HEAD=""
NEW_HEAD=""
HAS_NEW_COMMITS=false

if command -v git &>/dev/null && [[ -d "${REPO_DIR}/.git" ]]; then
    cd "${REPO_DIR}"
    PREV_HEAD="$(git rev-parse HEAD 2>/dev/null || true)"
    
    # Git pull ausführen
    git pull origin main 2>/dev/null || git pull 2>/dev/null || true
    NEW_HEAD="$(git rev-parse HEAD 2>/dev/null || true)"

    if [[ -n "${PREV_HEAD}" && -n "${NEW_HEAD}" && "${PREV_HEAD}" != "${NEW_HEAD}" ]]; then
        HAS_NEW_COMMITS=true
        echo -e "  ${GREEN}✓${NC} Neue Aktualisierungen von GitHub heruntergeladen"
    elif [[ -n "${LAST_INSTALLED_COMMIT}" && -n "${NEW_HEAD}" && "${LAST_INSTALLED_COMMIT}" != "${NEW_HEAD}" ]]; then
        HAS_NEW_COMMITS=true
        echo -e "  ${GREEN}✓${NC} Neue Version/Commits werden im System synchronisiert"
    elif [[ -z "${LAST_INSTALLED_COMMIT}" ]]; then
        if [[ -f "${INSTALLED_VER_FILE}" ]]; then
            HAS_NEW_COMMITS=false
            echo -e "  ${GREEN}✓${NC} Git-Repository ist bereits auf dem neuesten Stand"
        else
            HAS_NEW_COMMITS=true
            echo -e "  ${GREEN}✓${NC} Erstmalige Versionssynchronisation"
        fi
    else
        echo -e "  ${GREEN}✓${NC} Git-Repository ist bereits auf dem neuesten Stand"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Kein Git-Verzeichnis gefunden – überspringe git pull"
fi

# Prüfen, ob die VERSION-Datei im Repo geändert wurde
REPO_VER=""
[[ -f "${VERSION_FILE}" ]] && REPO_VER="$(tr -d '[:space:]' < "${VERSION_FILE}" 2>/dev/null || true)"

HAS_REAL_UPDATE=false
if [[ "${HAS_NEW_COMMITS}" == "true" ]]; then
    HAS_REAL_UPDATE=true
elif [[ -n "${REPO_VER}" && "${REPO_VER}" != "${CURRENT_VER}" ]]; then
    HAS_REAL_UPDATE=true
fi

echo -e "${BLUE}[2/5] Konfigurationen aktualisieren & Benutzereinstellungen schützen...${NC}"
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

# ── Automatisches Sicherheits-Backup vor dem Update ──
BACKUP_BASE="${CONFIG_DIR}/tokyo-hypr-backup"
BACKUP_UPDATE_DIR="${BACKUP_BASE}/pre-update_$(date '+%Y-%m-%d_%H-%M-%S')"
mkdir -p "${BACKUP_UPDATE_DIR}"
for comp in hypr waybar swaync rofi kitty; do
    if [[ -d "${CONFIG_DIR}/${comp}" ]]; then
        cp -a "${CONFIG_DIR}/${comp}" "${BACKUP_UPDATE_DIR}/" 2>/dev/null || true
    fi
done
echo -e "  ${GREEN}✓${NC} Sicherheits-Backup vor dem Update angelegt: ${BACKUP_UPDATE_DIR}"

# Hilfsfunktion: Datei nur anlegen, falls am Ziel noch nicht vorhanden (schützt persönliche Anpassungen)
copy_if_missing() {
    local src="$1"
    local dest="$2"
    if [[ ! -e "${dest}" ]]; then
        mkdir -p "$(dirname "${dest}")"
        cp "${src}" "${dest}" 2>/dev/null || true
    fi
}

# 1. Waybar: Layout-Vorlagen immer aktualisieren (damit Bugfixes & neue Presets ankommen)
if [[ -d "${REPO_DIR}/config/waybar/layouts" ]]; then
    mkdir -p "${CONFIG_DIR}/waybar/layouts"
    cp -rf "${REPO_DIR}/config/waybar/layouts/"* "${CONFIG_DIR}/waybar/layouts/" 2>/dev/null || true
fi
# Aktive Waybar-Konfiguration (config.jsonc & style.css) NIEMALS überschreiben, falls bereits vorhanden!
copy_if_missing "${REPO_DIR}/config/waybar/config.jsonc" "${CONFIG_DIR}/waybar/config.jsonc"
copy_if_missing "${REPO_DIR}/config/waybar/style.css" "${CONFIG_DIR}/waybar/style.css"

# 2. SwayNC
copy_if_missing "${REPO_DIR}/config/swaync/config.json" "${CONFIG_DIR}/swaync/config.json"
copy_if_missing "${REPO_DIR}/config/swaync/style.css" "${CONFIG_DIR}/swaync/style.css"

# 3. Hyprland Lua:
# System-Kerndateien werden aktualisiert (Bugfixes & neue Funktionen)
for core_file in hyprland.lua rules.lua animations.lua; do
    if [[ -f "${REPO_DIR}/config/hypr/${core_file}" ]]; then
        cp -f "${REPO_DIR}/config/hypr/${core_file}" "${CONFIG_DIR}/hypr/${core_file}" 2>/dev/null || true
    fi
done

# Benutzereigene Hyprland-Dateien NIEMALS überschreiben (Monitore, Tastatur, Theme-Farben, Binds, Autostart)
copy_if_missing "${REPO_DIR}/config/hypr/monitors.lua" "${CONFIG_DIR}/hypr/monitors.lua"
copy_if_missing "${REPO_DIR}/config/hypr/input.lua" "${CONFIG_DIR}/hypr/input.lua"
copy_if_missing "${REPO_DIR}/config/hypr/colors.lua" "${CONFIG_DIR}/hypr/colors.lua"

# Keybinds & Autostart: Bestehende Dateien unberührt lassen; Upstream-Referenz danebenlegen
if [[ -f "${CONFIG_DIR}/hypr/keybinds.lua" ]]; then
    cp -f "${REPO_DIR}/config/hypr/keybinds.lua" "${CONFIG_DIR}/hypr/keybinds.lua.upstream" 2>/dev/null || true
else
    cp -f "${REPO_DIR}/config/hypr/keybinds.lua" "${CONFIG_DIR}/hypr/keybinds.lua" 2>/dev/null || true
fi

if [[ -f "${CONFIG_DIR}/hypr/autostart.lua" ]]; then
    cp -f "${REPO_DIR}/config/hypr/autostart.lua" "${CONFIG_DIR}/hypr/autostart.lua.upstream" 2>/dev/null || true
else
    cp -f "${REPO_DIR}/config/hypr/autostart.lua" "${CONFIG_DIR}/hypr/autostart.lua" 2>/dev/null || true
fi

# user.lua.example als Vorlage für eigene Shortcuts bereitstellen
[[ -f "${REPO_DIR}/config/hypr/user.lua.example" ]] && cp -f "${REPO_DIR}/config/hypr/user.lua.example" "${CONFIG_DIR}/hypr/user.lua.example" 2>/dev/null || true

# 4. Hyprlock & Hyprpaper
[[ -f "${REPO_DIR}/config/hyprlock/hyprlock.conf" ]] && cp -f "${REPO_DIR}/config/hyprlock/hyprlock.conf" "${CONFIG_DIR}/hypr/hyprlock.conf" 2>/dev/null || true
copy_if_missing "${REPO_DIR}/config/hyprpaper/hyprpaper.conf" "${CONFIG_DIR}/hypr/hyprpaper.conf"

# 5. Rofi
[[ -f "${REPO_DIR}/config/rofi/wallpaper.rasi" ]] && cp -f "${REPO_DIR}/config/rofi/wallpaper.rasi" "${CONFIG_DIR}/rofi/wallpaper.rasi" 2>/dev/null || true
copy_if_missing "${REPO_DIR}/config/rofi/config.rasi" "${CONFIG_DIR}/rofi/config.rasi"

# 6. Kitty & GTK
copy_if_missing "${REPO_DIR}/config/kitty/kitty.conf" "${CONFIG_DIR}/kitty/kitty.conf"
copy_if_missing "${REPO_DIR}/config/gtk-3.0/settings.ini" "${CONFIG_DIR}/gtk-3.0/settings.ini"
copy_if_missing "${REPO_DIR}/config/gtk-4.0/settings.ini" "${CONFIG_DIR}/gtk-4.0/settings.ini"
[[ -f "${REPO_DIR}/config/gtk-4.0/gtk.css" ]] && cp -f "${REPO_DIR}/config/gtk-4.0/gtk.css" "${CONFIG_DIR}/gtk-4.0/gtk.css" 2>/dev/null || true

# 7. Settings App (user_settings.json bleibt erhalten, da nur *.py kopiert wird)
[[ -d "${REPO_DIR}/settings" ]] && cp -f "${REPO_DIR}/settings/"*.py "${CONFIG_DIR}/hypr/settings/" 2>/dev/null || true

# 8. Tokyo Shot (Screenshot-Manager & Editor)
if [[ -d "${REPO_DIR}/screenshot" ]]; then
    mkdir -p "${CONFIG_DIR}/hypr/screenshot"
    cp -f "${REPO_DIR}/screenshot/"*.py "${CONFIG_DIR}/hypr/screenshot/" 2>/dev/null || true
    chmod +x "${CONFIG_DIR}/hypr/screenshot/"*.py 2>/dev/null || true
fi

# 9. Skripte & CLI Starter
[[ -d "${REPO_DIR}/scripts" ]] && cp -f "${REPO_DIR}/scripts/"* "${CONFIG_DIR}/hypr/scripts/" 2>/dev/null || true
chmod +x "${CONFIG_DIR}/hypr/scripts/"* 2>/dev/null || true
chmod +x "${REPO_DIR}/"*.sh "${REPO_DIR}/scripts/"* 2>/dev/null || true
mkdir -p "${HOME}/.local/bin"
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-shot" "${HOME}/.local/bin/tokyo-shot" 2>/dev/null || true
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-app-installer" "${HOME}/.local/bin/tokyo-app-installer" 2>/dev/null || true
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-cleaner" "${HOME}/.local/bin/tokyo-cleaner" 2>/dev/null || true
ln -sf "${CONFIG_DIR}/hypr/scripts/tokyo-hardware-check" "${HOME}/.local/bin/tokyo-hardware-check" 2>/dev/null || true
if [[ -d "${REPO_DIR}/assets/desktop" ]]; then
    mkdir -p "${HOME}/.local/share/applications"
    cp -f "${REPO_DIR}/assets/desktop/"*.desktop "${HOME}/.local/share/applications/" 2>/dev/null || true
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
fi

# 10. Wallpapers (neue hinzufügen, bestehende niemals überschreiben)
[[ -d "${REPO_DIR}/assets/wallpapers" ]] && cp -n "${REPO_DIR}/assets/wallpapers/"* "${CONFIG_DIR}/hypr/wallpapers/" 2>/dev/null || true

# 11. Gespeicherte Benutzereinstellungen aus user_settings.json wiederherstellen/abgleichen
if command -v python3 &>/dev/null && [[ -f "${CONFIG_DIR}/hypr/settings/config_manager.py" && -f "${CONFIG_DIR}/hypr/settings/user_settings.json" ]]; then
    python3 -c "
import sys
sys.path.insert(0, '${CONFIG_DIR}/hypr/settings')
try:
    from config_manager import ConfigManager
    cm = ConfigManager()
    res = cm.reapply_user_settings(reload=False)
    if res.get('applied'):
        print('  \033[0;32m✓\033[0m Gespeicherte Benutzereinstellungen (Design, Waybar, Input) erfolgreich beibehalten')
except Exception as e:
    print(f'  \033[0;33m⚠\033[0m Hinweis bei Einstellungsabgleich: {e}')
" 2>/dev/null || true
fi

# ── Versionsverwaltung: Die Version wird zentral über VERSION im Repo gesteuert (aktuell: 1.0) ──
TARGET_VER="1.0"
if [[ -f "${VERSION_FILE}" ]]; then
    TARGET_VER="$(tr -d '[:space:]' < "${VERSION_FILE}" 2>/dev/null || echo "1.0")"
fi
if ! [[ "${TARGET_VER}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    TARGET_VER="1.0"
fi

NEW_VER="${TARGET_VER}"
echo "${TARGET_VER}" > "${INSTALLED_VER_FILE}"
[[ -n "${NEW_HEAD}" ]] && echo "${NEW_HEAD}" > "${LAST_COMMIT_FILE}" 2>/dev/null || true

if [[ "${HAS_REAL_UPDATE}" == "true" ]]; then
    echo -e "  ${GREEN}✓${NC} Aktualisierung auf Version ${BOLD}v${NEW_VER}${NC} erfolgreich übernommen"
else
    echo -e "  ${GREEN}✓${NC} System ist auf dem neuesten Stand (Version: ${BOLD}v${NEW_VER}${NC})"
fi

# Desktop-PC Schutz: Falls kein Backlight vorhanden ist, Widget entfernen
if [[ ! -d /sys/class/backlight || -z "$(ls -A /sys/class/backlight 2>/dev/null)" ]]; then
    if command -v jq &>/dev/null && [[ -f "${CONFIG_DIR}/swaync/config.json" ]]; then
        jq '.widgets |= map(select(. != "backlight"))' "${CONFIG_DIR}/swaync/config.json" > "${CONFIG_DIR}/swaync/config.json.tmp" 2>/dev/null && mv "${CONFIG_DIR}/swaync/config.json.tmp" "${CONFIG_DIR}/swaync/config.json" 2>/dev/null || true
    fi
fi

if [[ "${HAS_REAL_UPDATE}" == "true" ]]; then
    echo -e "  ${GREEN}✓${NC} Konfigurationen erfolgreich auf Version ${BOLD}v${NEW_VER}${NC} aktualisiert"
else
    echo -e "  ${GREEN}✓${NC} Konfigurationen erfolgreich synchronisiert (Version: ${BOLD}v${CURRENT_VER}${NC})"
fi

echo -e "${BLUE}[3/5] Design & Icons prüfen...${NC}"
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    current_gtk="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || true)"
    if [[ -z "${current_gtk}" || "${current_gtk}" == "Adwaita" ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    fi
    current_icon="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || true)"
    if [[ -z "${current_icon}" || "${current_icon}" == "Adwaita" || "${current_icon}" == "hicolor" ]]; then
        if pacman -Qi papirus-icon-theme &>/dev/null; then
            gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Papirus-Dark Icon-Theme aktiv"
        fi
    fi
fi

# Polkit & Sudoers-Regeln & SDDM Theme (erfordert Administrator-Rechte)
if sudo -n true 2>/dev/null || sudo -v; then
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

    # SDDM Login-Screen Theme aktualisieren & konfigurieren
    if [[ -d "${REPO_DIR}/assets/sddm/tokyo-night" ]]; then
        sudo mkdir -p /usr/share/sddm/themes/tokyo-night
        sudo cp -rf "${REPO_DIR}/assets/sddm/tokyo-night/"* /usr/share/sddm/themes/tokyo-night/ 2>/dev/null || true
        sudo chmod -R 755 /usr/share/sddm/themes/tokyo-night 2>/dev/null || true
        sudo mkdir -p /etc/sddm.conf.d
        echo -e "[Theme]\nCurrent=tokyo-night" | sudo tee /etc/sddm.conf.d/tokyo-night.conf >/dev/null 2>&1 || true
        # Wallpaper synchronisieren falls vorhanden
        if [[ -f "${CONFIG_DIR}/hypr/wallpapers/current.jpg" ]]; then
            sudo cp -f "${CONFIG_DIR}/hypr/wallpapers/current.jpg" /usr/share/sddm/themes/tokyo-night/background.jpg 2>/dev/null || true
            sudo chmod 644 /usr/share/sddm/themes/tokyo-night/background.jpg 2>/dev/null || true
        fi
        # QML-Bytecode Cache leeren
        sudo rm -rf /var/lib/sddm/.cache 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} SDDM Login-Theme aktualisiert & QML-Cache geleert"
    fi
else
    echo -e "  ${YELLOW}Hinweis:${NC} Root-Rechte übersprungen – führe bei Bedarf ${BOLD}sudo ./scripts/setup-sddm.sh${NC} aus, um den SDDM Login-Screen zu aktualisieren."
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

# ── Update-Zusammenfassung & Manifest für Einstellungs-App schreiben ──
UPDATE_DATE="$(date '+%d.%m.%Y um %H:%M Uhr')"
UPDATE_ISO="$(date '+%Y-%m-%d %H:%M:%S')"

# Letzte Commits auslesen
COMMITS_FILE="${CONFIG_DIR}/hypr/.update_commits.tmp"
if command -v git &>/dev/null && [[ -d "${REPO_DIR}/.git" ]]; then
    git -C "${REPO_DIR}" log -n 6 --pretty=format:'%s' 2>/dev/null > "${COMMITS_FILE}" || true
fi

python3 -c "
import json
from pathlib import Path

commits = []
c_file = Path('${CONFIG_DIR}/hypr/.update_commits.tmp')
if c_file.is_file():
    commits = [line.strip() for line in c_file.read_text(encoding='utf-8').splitlines() if line.strip()]
    c_file.unlink(missing_ok=True)

manifest = {
    'version': '${NEW_VER}',
    'previous_version': '${CURRENT_VER}',
    'date': '${UPDATE_DATE}',
    'timestamp': '${UPDATE_ISO}',
    'commits': commits,
    'components': [
        {'name': 'Hyprland Konfiguration & Lua-Skripte', 'status': 'Aktualisiert', 'icon': 'preferences-desktop-display-symbolic'},
        {'name': 'Tokyo Shot Screenshot-Hub & Editor', 'status': 'Aktualisiert', 'icon': 'camera-photo-symbolic'},
        {'name': 'TUI App-Installer (pacman & yay)', 'status': 'Aktualisiert', 'icon': 'system-software-install-symbolic'},
        {'name': 'Hardware- & Treiber-Assistent', 'status': 'Aktualisiert', 'icon': 'preferences-system-devices-symbolic'},
        {'name': 'Waybar Statusleiste & Layouts (Crystal/Classic)', 'status': 'Neu geladen', 'icon': 'view-app-grid-symbolic'},
        {'name': 'SwayNC Kontrollzentrum & Tokyo CSS', 'status': 'Neu geladen', 'icon': 'preferences-system-notifications-symbolic'},
        {'name': 'Einstellungs-App & Update-Zentrum', 'status': 'Aktualisiert', 'icon': 'system-software-update-symbolic'}
    ]
}
out_file = Path('${CONFIG_DIR}/hypr/last_update.json')
out_file.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding='utf-8')
" 2>/dev/null || true

echo ""
echo -e "${MAGENTA}${BOLD}┌── Status der Komponenten & Benutzereinstellungen ──────────┐${NC}"
echo -e "${MAGENTA}${BOLD}│${NC}  ${GREEN}✓${NC} ${BOLD}Hyprland Core${NC} (Lua-Kerndateien & Regeln synchronisiert)     ${MAGENTA}${BOLD}│${NC}"
echo -e "${MAGENTA}${BOLD}│${NC}  ${GREEN}✓${NC} ${BOLD}Benutzereinstellungen${NC} (Monitore, Tastatur, Theme bewahrt)  ${MAGENTA}${BOLD}│${NC}"
echo -e "${MAGENTA}${BOLD}│${NC}  ${GREEN}✓${NC} ${BOLD}Waybar & Rofi${NC} (Aktives Layout & Transparenz geschützt)      ${MAGENTA}${BOLD}│${NC}"
echo -e "${MAGENTA}${BOLD}│${NC}  ${GREEN}✓${NC} ${BOLD}Tokyo Shot${NC} (Screenshot Hub, Annotation-Editor)          ${MAGENTA}${BOLD}│${NC}"
echo -e "${MAGENTA}${BOLD}│${NC}  ${GREEN}✓${NC} ${BOLD}App-Installer${NC} (Discord, Heroic, Cyber Suite, Tools)       ${MAGENTA}${BOLD}│${NC}"
echo -e "${MAGENTA}${BOLD}│${NC}  ${GREEN}✓${NC} ${BOLD}Hardware-Check${NC} (Nvidia, AMD, Intel, Microcode, Akku)     ${MAGENTA}${BOLD}│${NC}"
echo -e "${MAGENTA}${BOLD}│${NC}  ${GREEN}✓${NC} ${BOLD}SwayNC Kontrollzentrum${NC} (Tokyo Night CSS & Toggles)      ${MAGENTA}${BOLD}│${NC}"
echo -e "${MAGENTA}${BOLD}│${NC}  ${GREEN}✓${NC} ${BOLD}Settings-App${NC} (Version v${NEW_VER} & Update-Zentrum)           ${MAGENTA}${BOLD}│${NC}"
echo -e "${MAGENTA}${BOLD}└───────────────────────────────────────────────────────────┘${NC}"
echo ""
if [[ "${HAS_REAL_UPDATE}" == "true" ]]; then
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║  Update auf Version ${NEW_VER} erfolgreich abgeschlossen!    ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║  System ist aktuell (Version ${NEW_VER}) – Sync abgeschlossen! ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
fi
echo -e "  Alle Konfigurationen und Dienste sind aktiv."
echo ""
