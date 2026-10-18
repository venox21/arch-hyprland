#!/usr/bin/env bash
# Falls das Skript fälschlicherweise mit 'sh' (oder dash) aufgerufen wurde, sofort mit 'bash' neu starten:
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night Hyprland – Interaktiver TUI App-Uninstaller     ║
# ║  Deinstalliert Anwendungen & Caches restlos via Pacman/yay   ║
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
    echo -e "${RED}Fehler: Bitte starte dieses Skript NICHT direkt als root!${NC}"
    echo -e "Starte das Skript als normaler Benutzer mit sudo-Rechten."
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

header "Tokyo Night App-Uninstaller (Restlos entfernen)"

# ── Schutz kritischer Systempakete ────────────────────────────
PROTECTED_PACKAGES=(
    "base" "base-devel" "linux" "linux-firmware" "linux-headers"
    "systemd" "glibc" "sudo" "pacman" "yay" "yay-bin" "polkit"
    "hyprland" "hyprland-git" "waybar" "rofi" "rofi-wayland"
    "kitty" "thunar" "bash" "zsh" "coreutils" "dbus" "pipewire"
    "wireplumber" "seatd" "xorg-xwayland" "swaync" "grim" "slurp"
)

is_protected() {
    local pkg="$1"
    for prot in "${PROTECTED_PACKAGES[@]}"; do
        if [[ "${pkg}" == "${prot}" ]]; then
            return 0
        fi
    done
    return 1
}

# ── Bekannte App-Datenpfade für restlose Bereinigung ──────────
declare -A KNOWN_CONFIG_DIRS=(
    ["google-chrome"]="${HOME}/.config/google-chrome ${HOME}/.cache/google-chrome"
    ["chromium"]="${HOME}/.config/chromium ${HOME}/.cache/chromium"
    ["zen-browser-bin"]="${HOME}/.zen ${HOME}/.cache/zen"
    ["zen-browser"]="${HOME}/.zen ${HOME}/.cache/zen"
    ["firefox"]="${HOME}/.mozilla ${HOME}/.cache/mozilla"
    ["visual-studio-code-bin"]="${HOME}/.config/Code ${HOME}/.vscode"
    ["code"]="${HOME}/.config/Code ${HOME}/.vscode"
    ["discord"]="${HOME}/.config/discord ${HOME}/.cache/discord"
    ["vesktop"]="${HOME}/.config/vesktop ${HOME}/.cache/vesktop"
    ["vesktop-bin"]="${HOME}/.config/vesktop ${HOME}/.cache/vesktop"
    ["spotify"]="${HOME}/.config/spotify ${HOME}/.cache/spotify ${HOME}/.spicetify"
    ["spicetify-cli"]="${HOME}/.spicetify ${HOME}/.config/spicetify"
    ["steam"]="${HOME}/.steam ${HOME}/.local/share/Steam ${HOME}/.local/share/steam"
    ["heroic-games-launcher-bin"]="${HOME}/.config/heroic ${HOME}/.cache/heroic"
    ["heroic"]="${HOME}/.config/heroic ${HOME}/.cache/heroic"
    ["obsidian"]="${HOME}/.config/obsidian ${HOME}/.cache/obsidian"
    ["vlc"]="${HOME}/.config/vlc ${HOME}/.cache/vlc"
    ["btop"]="${HOME}/.config/btop"
    ["wireshark-qt"]="${HOME}/.config/wireshark"
    ["burpsuite"]="${HOME}/.BurpSuite"
    ["ghidra"]="${HOME}/.ghidra"
    ["ghidra-bin"]="${HOME}/.ghidra"
    ["sqlmap"]="${HOME}/.local/share/sqlmap ${HOME}/.sqlmap"
)

# ── TUI Tool prüfen (gum bevorzugt, mit whiptail/dialog als Alternative) ──
TUI_MODE="plain"
if command -v gum &>/dev/null; then
    TUI_MODE="gum"
elif command -v whiptail &>/dev/null; then
    TUI_MODE="whiptail"
elif command -v dialog &>/dev/null; then
    TUI_MODE="dialog"
fi

# ══════════════════════════════════════════════════════════════
# Schritt 1: Modus-Auswahl
# ══════════════════════════════════════════════════════════════
MODE_CURATED="1"
MODE_ALL="2"
MODE_ORPHANS="3"
SELECTED_MODE=""

echo -e "${CYAN}${BOLD}Wähle den gewünschten Deinstallations-Modus:${NC}"
echo ""

if [[ "${TUI_MODE}" == "gum" ]]; then
    CHOICE=$(gum choose \
        --header="Deinstallations-Modus wählen:" \
        --cursor.foreground="75" \
        --header.foreground="141" \
        "1) Beliebte Anwendungen & Tools deinstallieren" \
        "2) Alle installierten Benutzerprogramme durchsuchen (pacman -Qe)" \
        "3) Verwaiste Pakete & Abhängigkeiten restlos bereinigen (Orphans)" \
        "0) Abbrechen") || true

    case "${CHOICE}" in
        1*) SELECTED_MODE="${MODE_CURATED}" ;;
        2*) SELECTED_MODE="${MODE_ALL}" ;;
        3*) SELECTED_MODE="${MODE_ORPHANS}" ;;
        *)  info "Vorgang abgebrochen."; exit 0 ;;
    esac

elif [[ "${TUI_MODE}" == "whiptail" || "${TUI_MODE}" == "dialog" ]]; then
    TUI_BIN="$(command -v whiptail || command -v dialog)"
    CHOICE=$("${TUI_BIN}" --title "Tokyo Night – App-Uninstaller" \
        --menu "Wähle eine Aktion aus:" 16 70 4 \
        "1" "Beliebte Anwendungen & Tools deinstallieren" \
        "2" "Alle installierten Benutzerprogramme durchsuchen" \
        "3" "Verwaiste Pakete restlos bereinigen" \
        "4" "Abbrechen" \
        3>&1 1>&2 2>&3) || true

    case "${CHOICE}" in
        1) SELECTED_MODE="${MODE_CURATED}" ;;
        2) SELECTED_MODE="${MODE_ALL}" ;;
        3) SELECTED_MODE="${MODE_ORPHANS}" ;;
        *) info "Vorgang abgebrochen."; exit 0 ;;
    esac
else
    echo "  1) Beliebte Anwendungen & Tools deinstallieren"
    echo "  2) Alle installierten Benutzerprogramme durchsuchen"
    echo "  3) Verwaiste Pakete restlos bereinigen"
    echo "  0) Abbrechen"
    echo ""
    read -rp "Auswahl [1-3, 0 zum Beenden]: " raw_mode
    case "${raw_mode}" in
        1) SELECTED_MODE="${MODE_CURATED}" ;;
        2) SELECTED_MODE="${MODE_ALL}" ;;
        3) SELECTED_MODE="${MODE_ORPHANS}" ;;
        *) info "Vorgang abgebrochen."; exit 0 ;;
    esac
fi

# ══════════════════════════════════════════════════════════════
# Modus 3: Verwaiste Pakete direkt bereinigen
# ══════════════════════════════════════════════════════════════
if [[ "${SELECTED_MODE}" == "${MODE_ORPHANS}" ]]; then
    header "Verwaiste Pakete bereinigen"
    ORPHANS=$(pacman -Qdtq 2>/dev/null || true)
    if [[ -z "${ORPHANS}" ]]; then
        success "Keine verwaisten Pakete gefunden. Dein System ist sauber!"
        exit 0
    fi

    echo -e "${YELLOW}Folgende ungenutzte Abhängigkeiten wurden gefunden:${NC}"
    echo "${ORPHANS}" | tr '\n' ' '
    echo -e "\n"

    read -rp "Möchtest du diese verwaisten Pakete restlos entfernen? [J/n]: " confirm
    confirm="${confirm:-j}"
    if [[ "${confirm}" =~ ^[jJyY]$ ]]; then
        info "Entferne verwaiste Pakete via 'sudo pacman -Rns'..."
        sudo pacman -Rns --noconfirm ${ORPHANS}
        success "Verwaiste Pakete erfolgreich entfernt!"
    else
        info "Vorgang abgebrochen."
    fi
    exit 0
fi

# ══════════════════════════════════════════════════════════════
# Schritt 2: Paketauswahl zusammenstellen
# ══════════════════════════════════════════════════════════════
PACKAGES_TO_REMOVE=()

if [[ "${SELECTED_MODE}" == "${MODE_CURATED}" ]]; then
    header "Installierte Anwendungen ermitteln..."

    # Liste bekannter Anwendungen und deren Paketnamen
    CANDIDATES=(
        "google-chrome:Google Chrome Browser"
        "zen-browser-bin:Zen Browser (Firefox Tokyo Modern)"
        "zen-browser:Zen Browser (Firefox Tokyo Modern)"
        "visual-studio-code-bin:Visual Studio Code (IDE)"
        "code:Visual Studio Code (OSS)"
        "discord:Discord Client"
        "vesktop:Vesktop (Discord Wayland)"
        "vesktop-bin:Vesktop (Discord Wayland)"
        "spotify:Spotify Music Client"
        "spicetify-cli:Spicetify Theme Engine"
        "steam:Steam Gaming Platform"
        "heroic-games-launcher-bin:Heroic Games Launcher (Epic & GOG)"
        "heroic:Heroic Games Launcher (Epic & GOG)"
        "obsidian:Obsidian Notizen & Wiki"
        "btop:Btop System Monitor"
        "vlc:VLC Media Player"
        "wireshark-qt:Wireshark Netzwerk-Analyzer"
        "wireshark-cli:Wireshark CLI Tools"
        "burpsuite:Burp Suite Community Edition"
        "metasploit:Metasploit Framework"
        "aircrack-ng:Aircrack-ng WLAN Suite"
        "hashcat:Hashcat GPU Cracker"
        "john:John the Ripper"
        "sqlmap:SQLmap Injection Tool"
        "gobuster:Gobuster Fuzzer"
        "ffuf:FFUF Web Fuzzer"
        "ghidra:Ghidra Reverse Engineering"
        "ghidra-bin:Ghidra Reverse Engineering"
        "nmap:Nmap Port Scanner"
    )

    INSTALLED_ITEMS=()
    for entry in "${CANDIDATES[@]}"; do
        pkg="${entry%%:*}"
        desc="${entry#*:}"
        if pacman -Qq "${pkg}" &>/dev/null; then
            INSTALLED_ITEMS+=("${pkg} - ${desc}")
        fi
    done

    if [[ ${#INSTALLED_ITEMS[@]} -eq 0 ]]; then
        warn "Keine der vorkonfigurierten Anwendungen ist aktuell installiert."
        info "Wechsle zur Gesamtauswahl aller Benutzerprogramme..."
        SELECTED_MODE="${MODE_ALL}"
    else
        info "Gefundene Anwendungen (${#INSTALLED_ITEMS[@]}):"
        if [[ "${TUI_MODE}" == "gum" ]]; then
            CHOICES=$(gum choose --no-limit \
                --header="Wähle zu löschende Programme mit [Leertaste], bestätige mit [Enter]:" \
                --cursor-prefix="[ ] " \
                --selected-prefix="[✗] " \
                --unselected-prefix="[ ] " \
                --cursor.foreground="75" \
                --selected.foreground="196" \
                --header.foreground="141" \
                "${INSTALLED_ITEMS[@]}") || true

            while IFS= read -r line; do
                if [[ -n "${line}" ]]; then
                    pkg_name=$(echo "${line}" | awk '{print $1}')
                    PACKAGES_TO_REMOVE+=("${pkg_name}")
                fi
            done <<< "${CHOICES}"
        else
            echo ""
            for i in "${!INSTALLED_ITEMS[@]}"; do
                echo "  $((i+1))) ${INSTALLED_ITEMS[$i]}"
            done
            echo ""
            read -rp "Nummern der zu löschenden Programme (z.B. 1 3 4) oder 'alle': " user_input
            if [[ "${user_input}" == "alle" ]]; then
                for item in "${INSTALLED_ITEMS[@]}"; do
                    PACKAGES_TO_REMOVE+=($(echo "${item}" | awk '{print $1}'))
                done
            else
                for num in ${user_input}; do
                    if [[ "${num}" =~ ^[0-9]+$ ]] && [ "${num}" -ge 1 ] && [ "${num}" -le "${#INSTALLED_ITEMS[@]}" ]; then
                        item="${INSTALLED_ITEMS[$((num-1))]}"
                        PACKAGES_TO_REMOVE+=($(echo "${item}" | awk '{print $1}'))
                    fi
                done
            fi
        fi
    fi
fi

if [[ "${SELECTED_MODE}" == "${MODE_ALL}" ]]; then
    header "Alle installierten Benutzerprogramme (pacman -Qe)"
    info "Lade Paketliste..."

    # Alle explizit installierten Pakete mit Beschreibung abrufen
    ALL_QE=()
    while IFS= read -r pkg; do
        if [[ -n "${pkg}" ]] && ! is_protected "${pkg}"; then
            desc=$(pacman -Qi "${pkg}" 2>/dev/null | grep -m1 '^Beschreibung' | cut -d: -f2- | xargs || true)
            [[ -z "${desc}" ]] && desc=$(pacman -Qi "${pkg}" 2>/dev/null | grep -m1 '^Description' | cut -d: -f2- | xargs || true)
            ALL_QE+=("${pkg} - ${desc}")
        fi
    done < <(pacman -Qeq | sort)

    if [[ ${#ALL_QE[@]} -eq 0 ]]; then
        warn "Keine deinstallierbaren Benutzerpakete gefunden."
        exit 0
    fi

    if [[ "${TUI_MODE}" == "gum" ]]; then
        CHOICES=$(gum choose --no-limit \
            --header="Wähle zu deinstallierende Pakete mit [Leertaste], bestätige mit [Enter]:" \
            --cursor-prefix="[ ] " \
            --selected-prefix="[✗] " \
            --unselected-prefix="[ ] " \
            --cursor.foreground="75" \
            --selected.foreground="196" \
            --header.foreground="141" \
            "${ALL_QE[@]}") || true

        while IFS= read -r line; do
            if [[ -n "${line}" ]]; then
                pkg_name=$(echo "${line}" | awk '{print $1}')
                PACKAGES_TO_REMOVE+=("${pkg_name}")
            fi
        done <<< "${CHOICES}"
    else
        echo ""
        info "Suchfilter eingeben (oder Enter für die ersten 40 Einträge):"
        read -rp "Suchbegriff: " search_term
        FILTERED=()
        for item in "${ALL_QE[@]}"; do
            if [[ -z "${search_term}" ]] || echo "${item}" | grep -qi "${search_term}"; then
                FILTERED+=("${item}")
            fi
        done

        limit=40
        for i in "${!FILTERED[@]}"; do
            if [ "${i}" -ge "${limit}" ]; then
                echo "  ... und $(( ${#FILTERED[@]} - limit )) weitere Pakete. Bitte Suche verfeinern."
                break
            fi
            echo "  $((i+1))) ${FILTERED[$i]}"
        done
        echo ""
        read -rp "Nummern der zu löschenden Pakete (z.B. 1 2): " user_nums
        for num in ${user_nums}; do
            if [[ "${num}" =~ ^[0-9]+$ ]] && [ "${num}" -ge 1 ] && [ "${num}" -le "${#FILTERED[@]}" ]; then
                item="${FILTERED[$((num-1))]}"
                PACKAGES_TO_REMOVE+=($(echo "${item}" | awk '{print $1}'))
            fi
        done
    fi
fi

# ══════════════════════════════════════════════════════════════
# Schritt 3: Validierung & Sicherheitsprüfung
# ══════════════════════════════════════════════════════════════
if [[ ${#PACKAGES_TO_REMOVE[@]} -eq 0 ]]; then
    warn "Keine Pakete ausgewählt. Vorgang beendet."
    exit 0
fi

# Duplikate filtern & geschützte Pakete entfernen
CLEAN_TARGETS=()
for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    if is_protected "${pkg}"; then
        warn "Überspringe geschütztes Systempaket: ${pkg}"
        continue
    fi
    already=false
    for c in "${CLEAN_TARGETS[@]}"; do
        if [[ "${c}" == "${pkg}" ]]; then
            already=true
            break
        fi
    done
    if [[ "${already}" == "false" ]]; then
        CLEAN_TARGETS+=("${pkg}")
    fi
done

if [[ ${#CLEAN_TARGETS[@]} -eq 0 ]]; then
    error "Keine gültigen Pakete zur Deinstallation verblieben."
    exit 1
fi

echo ""
header "Zusammenfassung der Deinstallation"
echo -e "${RED}${BOLD}Folgende Pakete werden vollständig deinstalliert (pacman -Rns):${NC}"
for p in "${CLEAN_TARGETS[@]}"; do
    echo -e "  ${RED}✗${NC} ${BOLD}${p}${NC}"
done
echo ""

# ══════════════════════════════════════════════════════════════
# Schritt 4: Erkennung verbliebener Konfigurationen & Caches
# ══════════════════════════════════════════════════════════════
FOUND_USER_DIRS=()

for pkg in "${CLEAN_TARGETS[@]}"; do
    # 1. Bekannte Verzeichnisse
    if [[ -n "${KNOWN_CONFIG_DIRS[${pkg}]:-}" ]]; then
        for path in ${KNOWN_CONFIG_DIRS[${pkg}]}; do
            if [[ -e "${path}" ]]; then
                FOUND_USER_DIRS+=("${path}")
            fi
        done
    fi

    # 2. Heuristische Erkennung (~/.config/<pkg>, ~/.cache/<pkg>, ~/.local/share/<pkg>)
    for base in "${HOME}/.config" "${HOME}/.cache" "${HOME}/.local/share" "${HOME}/.local/state"; do
        test_dir="${base}/${pkg}"
        if [[ -d "${test_dir}" ]]; then
            already=false
            for existing in "${FOUND_USER_DIRS[@]}"; do
                if [[ "${existing}" == "${test_dir}" ]]; then already=true; break; fi
            done
            if [[ "${already}" == "false" ]]; then
                FOUND_USER_DIRS+=("${test_dir}")
            fi
        fi
    done
done

if [[ ${#FOUND_USER_DIRS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}${BOLD}Gefundene Benutzer-Konfigurationen & Caches (Restlose Bereinigung):${NC}"
    for dir in "${FOUND_USER_DIRS[@]}"; do
        echo -e "  ${YELLOW}🗑${NC}  ${dir}"
    done
    echo ""
fi

# ══════════════════════════════════════════════════════════════
# Schritt 5: Bestätigung abfragen
# ══════════════════════════════════════════════════════════════
echo -e "${BOLD}Möchtest du die Deinstallation jetzt durchführen?${NC}"
read -rp "Bestätigen mit [J/n]: " do_uninstall
do_uninstall="${do_uninstall:-j}"

if ! [[ "${do_uninstall}" =~ ^[jJyY]$ ]]; then
    info "Deinstallation abgebrochen."
    exit 0
fi

# ══════════════════════════════════════════════════════════════
# Schritt 6: Deinstallation durchführen (pacman/yay -Rns)
# ══════════════════════════════════════════════════════════════
echo ""
info "Entferne Pakete und ungenutzte Abhängigkeiten (pacman -Rns)..."

REMOVE_CMD="sudo pacman -Rns --noconfirm"
if command -v yay &>/dev/null; then
    REMOVE_CMD="yay -Rns --noconfirm"
fi

if ${REMOVE_CMD} "${CLEAN_TARGETS[@]}"; then
    success "Pakete erfolgreich über die Paketverwaltung deinstalliert!"
else
    warn "Standard-Entfernung meldete einen Hinweis. Versuche individuelles Entfernen..."
    for pkg in "${CLEAN_TARGETS[@]}"; do
        sudo pacman -Rns --noconfirm "${pkg}" 2>/dev/null || sudo pacman -R --noconfirm "${pkg}" 2>/dev/null || true
    done
fi

# ══════════════════════════════════════════════════════════════
# Schritt 7: Restlose Bereinigung der Benutzerdaten
# ══════════════════════════════════════════════════════════════
if [[ ${#FOUND_USER_DIRS[@]} -gt 0 ]]; then
    echo ""
    read -rp "Sollen die oben gelisteten Benutzerdaten & Caches jetzt restlos gelöscht werden? [J/n]: " purge_user_dirs
    purge_user_dirs="${purge_user_dirs:-j}"

    if [[ "${purge_user_dirs}" =~ ^[jJyY]$ ]]; then
        info "Lösche Konfigurations- und Cache-Verzeichnisse..."
        for dir in "${FOUND_USER_DIRS[@]}"; do
            if [[ -e "${dir}" && "${dir}" != "${HOME}" && "${dir}" != "/" ]]; then
                rm -rf "${dir}"
                success "Gelöscht: ${dir}"
            fi
        done
        success "Alle Benutzerdaten & Caches restlos bereinigt!"
    else
        info "Benutzerdaten in ~/.config und ~/.cache wurden beibehalten."
    fi
fi

# ══════════════════════════════════════════════════════════════
# Schritt 8: Verwaiste Abhängigkeiten & Desktop-Cache prüfen
# ══════════════════════════════════════════════════════════════
REMAINING_ORPHANS=$(pacman -Qdtq 2>/dev/null || true)
if [[ -n "${REMAINING_ORPHANS}" ]]; then
    echo ""
    info "Prüfe auf verwaiste Rest-Abhängigkeiten..."
    echo -e "${YELLOW}Verwaiste Pakete:${NC} ${REMAINING_ORPHANS}"
    read -rp "Sollen diese verwaisten Abhängigkeiten ebenfalls bereinigt werden? [J/n]: " clean_orph
    clean_orph="${clean_orph:-j}"
    if [[ "${clean_orph}" =~ ^[jJyY]$ ]]; then
        sudo pacman -Rns --noconfirm ${REMAINING_ORPHANS} 2>/dev/null || true
        success "Verwaiste Abhängigkeiten bereinigt."
    fi
fi

# Desktop-Datenbank aktualisieren
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
fi

echo ""
header "Deinstallation erfolgreich abgeschlossen!"
echo -e "${GREEN}${BOLD}Alle ausgewählten Programme und deren Restdateien wurden restlos entfernt.${NC}"
echo ""
read -rp "Drücke [Enter], um das Fenster zu schließen..."
