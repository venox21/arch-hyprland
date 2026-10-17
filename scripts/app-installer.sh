#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night Hyprland – Interaktiver TUI App-Installer       ║
# ║  Installiert beliebte Anwendungen via Pacman & yay (AUR)     ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Farben & Formatierung (Tokyo Night) ───────────────────────
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}${BOLD}║  $*${NC}"
    echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

info() {
    echo -e "  ${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "  ${GREEN}[✓]${NC} $*"
}

warn() {
    echo -e "  ${YELLOW}[!]${NC} $*"
}

error() {
    echo -e "  ${RED}[✗]${NC} $*"
}

# ── Root-Prüfung ──────────────────────────────────────────────
if [[ "${EUID}" -eq 0 ]]; then
    echo -e "${RED}Fehler: Bitte starte dieses Skript NICHT als root!${NC}"
    echo -e "yay und makepkg verweigern die Ausführung mit Root-Rechten."
    echo -e "Starte das Skript als normaler Benutzer: ${BOLD}./install-apps.sh${NC}"
    exit 1
fi

# Prüfe sudo-Zugriff vorab
if ! sudo -v 2>/dev/null; then
    info "Bitte gib dein sudo-Passwort ein, um fortzufahren:"
    sudo -v || { error "sudo-Authentifizierung fehlgeschlagen."; exit 1; }
fi

# Keep sudo alive während des Skripts
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill "${SUDO_PID}" 2>/dev/null || true' EXIT

header "Tokyo Night App-Installer"

# ══════════════════════════════════════════════════════════════
# Schritt 1: Abhängigkeiten, yay & TUI-Tools prüfen
# ══════════════════════════════════════════════════════════════
info "Prüfe System-Abhängigkeiten..."

# 1. yay (AUR-Helper) prüfen / installieren
if ! command -v yay &>/dev/null; then
    warn "AUR-Helper 'yay' wurde nicht gefunden. Automatische Installation startet..."
    
    info "Installiere Build-Werkzeuge (git, base-devel)..."
    sudo pacman -S --needed --noconfirm git base-devel
    
    YAY_TMP="$(mktemp -d /tmp/yay-bin.XXXXXX)"
    info "Klone yay-bin nach ${YAY_TMP}..."
    if git clone https://aur.archlinux.org/yay-bin.git "${YAY_TMP}"; then
        (
            cd "${YAY_TMP}"
            info "Baue und installiere yay-bin..."
            makepkg -si --noconfirm
        )
        rm -rf "${YAY_TMP}"
        success "yay erfolgreich installiert!"
    else
        rm -rf "${YAY_TMP}"
        error "Fehler beim Klonen von yay-bin. Bitte prüfe deine Internetverbindung."
        exit 1
    fi
else
    success "AUR-Helper 'yay' ist vorhanden."
fi

# 2. TUI-Menü-Tool (gum bevorzugt, mit whiptail/dialog als Alternative)
if ! command -v gum &>/dev/null; then
    info "Installiere 'gum' für das interaktive TUI-Menü..."
    sudo pacman -S --needed --noconfirm gum 2>/dev/null || true
    if command -v gum &>/dev/null; then
        success "'gum' erfolgreich installiert."
    else
        warn "'gum' konnte nicht installiert werden. Prüfe Alternativen (whiptail/dialog)..."
        if ! command -v whiptail &>/dev/null && ! command -v dialog &>/dev/null; then
            sudo pacman -S --needed --noconfirm libnewt 2>/dev/null || true
        fi
    fi
else
    success "TUI-Tool 'gum' ist vorhanden."
fi

# ══════════════════════════════════════════════════════════════
# Schritt 2: Interaktives Multi-Select Menü
# ══════════════════════════════════════════════════════════════
echo ""
info "Starte interaktives Auswahlmenü..."

OPT_CHROME="Google Chrome"
OPT_VSCODE="Visual Studio Code"
OPT_SPOTIFY_ONLY="Spotify (Nur Client)"
OPT_SPOTIFY_SPICE="Spotify + Spicetify"
OPT_STEAM="Steam"
OPT_OBSIDIAN="Obsidian"

SELECTED=()

if command -v gum &>/dev/null; then
    # Modernes Menü mit gum (Pfeiltasten, Leertaste zum Markieren, Enter zum Bestätigen)
    CHOICES=$(gum choose --no-limit \
        --header="Wähle Programme mit [Leertaste] aus und bestätige mit [Enter]:" \
        --cursor-prefix="[ ] " \
        --selected-prefix="[✓] " \
        --unselected-prefix="[ ] " \
        --cursor.foreground="75" \
        --selected.foreground="117" \
        --header.foreground="141" \
        "${OPT_CHROME}" \
        "${OPT_VSCODE}" \
        "${OPT_SPOTIFY_ONLY}" \
        "${OPT_SPOTIFY_SPICE}" \
        "${OPT_STEAM}" \
        "${OPT_OBSIDIAN}") || true

    while IFS= read -r line; do
        [[ -n "${line}" ]] && SELECTED+=("${line}")
    done <<< "${CHOICES}"

elif command -v whiptail &>/dev/null || command -v dialog &>/dev/null; then
    TUI_BIN="$(command -v whiptail || command -v dialog)"
    CHOICES=$("${TUI_BIN}" --title "Tokyo Night – App-Installer" \
        --checklist "Navigiere mit [Pfeiltasten], wähle mit [Leertaste], bestätige mit [Enter]:" 18 68 6 \
        "chrome"    "Google Chrome (AUR: google-chrome)" OFF \
        "vscode"    "Visual Studio Code (AUR: visual-studio-code-bin)" OFF \
        "spotify"   "Spotify - Nur Client (AUR: spotify)" OFF \
        "spicetify" "Spotify + Spicetify (Marketplace & CLI)" OFF \
        "steam"     "Steam (Gaming-Plattform, multilib)" OFF \
        "obsidian"  "Obsidian (Markdown Notizen & Wiki)" OFF \
        3>&1 1>&2 2>&3) || true

    for item in ${CHOICES}; do
        clean_item=$(echo "${item}" | tr -d '"')
        case "${clean_item}" in
            chrome)    SELECTED+=("${OPT_CHROME}") ;;
            vscode)    SELECTED+=("${OPT_VSCODE}") ;;
            spotify)   SELECTED+=("${OPT_SPOTIFY_ONLY}") ;;
            spicetify) SELECTED+=("${OPT_SPOTIFY_SPICE}") ;;
            steam)     SELECTED+=("${OPT_STEAM}") ;;
            obsidian)  SELECTED+=("${OPT_OBSIDIAN}") ;;
        esac
    done
else
    # Reine Bash-Fallback-Abfrage
    echo -e "${YELLOW}Kein TUI-Frontend gefunden. Bitte wähle manuell:${NC}"
    ALL_OPTS=("${OPT_CHROME}" "${OPT_VSCODE}" "${OPT_SPOTIFY_ONLY}" "${OPT_SPOTIFY_SPICE}" "${OPT_STEAM}" "${OPT_OBSIDIAN}")
    for opt in "${ALL_OPTS[@]}"; do
        read -r -p "Möchtest du '${opt}' installieren? [j/N]: " resp
        if [[ "${resp,,}" =~ ^(j|ja|y|yes)$ ]]; then
            SELECTED+=("${opt}")
        fi
    done
fi

if [[ ${#SELECTED[@]} -eq 0 ]]; then
    warn "Keine Programme ausgewählt. Vorgang beendet."
    exit 0
fi

echo ""
info "Ausgewählte Programme (${#SELECTED[@]}):"
for s in "${SELECTED[@]}"; do
    echo -e "    ${CYAN}•${NC} ${BOLD}${s}${NC}"
done
echo ""

# ══════════════════════════════════════════════════════════════
# Schritt 3: Logik, Multilib-Prüfung & Paketauflösung
# ══════════════════════════════════════════════════════════════

INSTALL_PACKAGES=()
WANT_SPICETIFY_SETUP=false
WANT_STEAM=false

for item in "${SELECTED[@]}"; do
    case "${item}" in
        "${OPT_CHROME}")
            INSTALL_PACKAGES+=("google-chrome")
            ;;
        "${OPT_VSCODE}")
            INSTALL_PACKAGES+=("visual-studio-code-bin")
            ;;
        "${OPT_SPOTIFY_ONLY}")
            INSTALL_PACKAGES+=("spotify")
            ;;
        "${OPT_SPOTIFY_SPICE}")
            INSTALL_PACKAGES+=("spotify" "spicetify-cli" "spicetify-marketplace-bin")
            WANT_SPICETIFY_SETUP=true
            ;;
        "${OPT_STEAM}")
            INSTALL_PACKAGES+=("steam")
            WANT_STEAM=true
            ;;
        "${OPT_OBSIDIAN}")
            INSTALL_PACKAGES+=("obsidian")
            ;;
    esac
done

# Steam: Prüfe und aktiviere multilib-Repository
if [[ "${WANT_STEAM}" == "true" ]]; then
    info "Prüfe [multilib] Repository für Steam..."
    if ! pacman -Sl multilib &>/dev/null; then
        warn "[multilib] ist noch nicht in /etc/pacman.conf aktiviert. Aktiviere multilib..."
        
        # Aktiviere [multilib] und das zugehörige Include
        if grep -q "^#\[multilib\]" /etc/pacman.conf; then
            sudo sed -i -e '/^#\[multilib\]/,/^#Include[[:space:]]*=/ s/^#//' /etc/pacman.conf
        else
            echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
        fi
        
        info "Aktualisiere Paketdatenbanken (pacman -Sy)..."
        sudo pacman -Sy
        
        if pacman -Sl multilib &>/dev/null; then
            success "[multilib] erfolgreich aktiviert!"
        else
            error "[multilib] konnte nicht aktiviert werden. Steam-Installation könnte fehlschlagen."
        fi
    else
        success "[multilib] ist bereits aktiv."
    fi
fi

# Duplikate sauber entfernen (z. B. wenn "Spotify" und "Spotify + Spicetify" gewählt wurden)
UNIQUE_PACKAGES=()
for pkg in "${INSTALL_PACKAGES[@]}"; do
    already=false
    for u in "${UNIQUE_PACKAGES[@]}"; do
        if [[ "${u}" == "${pkg}" ]]; then
            already=true
            break
        fi
    done
    if [[ "${already}" == "false" ]]; then
        UNIQUE_PACKAGES+=("${pkg}")
    fi
done

info "Zu installierende Pakete via yay (${#UNIQUE_PACKAGES[@]}): ${CYAN}${UNIQUE_PACKAGES[*]}${NC}"
echo ""

# ══════════════════════════════════════════════════════════════
# Schritt 4: Installation via yay
# ══════════════════════════════════════════════════════════════
info "Starte Installation..."
if yay -S --needed "${UNIQUE_PACKAGES[@]}"; then
    success "Paketinstallation abgeschlossen!"
else
    error "Bei der Installation ist ein Fehler aufgetreten."
    exit 1
fi

# ══════════════════════════════════════════════════════════════
# Schritt 5: Post-Install (Spicetify-Berechtigungen)
# ══════════════════════════════════════════════════════════════
if [[ "${WANT_SPICETIFY_SETUP}" == "true" ]]; then
    echo ""
    info "Konfiguriere Schreibrechte für Spicetify..."
    
    SPOTIFY_DIR="/opt/spotify"
    if [[ -d "${SPOTIFY_DIR}" ]]; then
        sudo chmod a+wr "${SPOTIFY_DIR}" 2>/dev/null || true
        if [[ -d "${SPOTIFY_DIR}/Apps" ]]; then
            sudo chmod a+wr "${SPOTIFY_DIR}/Apps" -R 2>/dev/null || true
        fi
        success "Schreibrechte für Spicetify auf ${SPOTIFY_DIR} erfolgreich gesetzt!"
    else
        warn "Verzeichnis ${SPOTIFY_DIR} wurde noch nicht gefunden. Rechte können bei Bedarf manuell gesetzt werden."
    fi
fi

# ══════════════════════════════════════════════════════════════
# Schritt 6: Zusammenfassung
# ══════════════════════════════════════════════════════════════
echo ""
header "Installation erfolgreich!"

echo -e "${GREEN}${BOLD}Folgende Anwendungen wurden eingerichtet:${NC}"
for item in "${SELECTED[@]}"; do
    echo -e "  ${GREEN}✓${NC} ${BOLD}${item}${NC}"
done

echo ""
if [[ "${WANT_SPICETIFY_SETUP}" == "true" ]]; then
    echo -e "${MAGENTA}${BOLD}Spicetify-Tipp:${NC}"
    echo -e "  Starte Spotify einmal, schließe es wieder und führe dann aus:"
    echo -e "  ${CYAN}spicetify backup apply${NC}"
    echo -e "  Der Spicetify Marketplace ist dann direkt in Spotify verfügbar!"
    echo ""
fi

info "Alle Programme können sofort über das Rofi-Menü (${BOLD}SUPER + D${NC}) gestartet werden."
echo ""
