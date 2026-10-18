#!/usr/bin/env bash
# Falls das Skript fälschlicherweise mit 'sh' (oder dash) aufgerufen wurde, sofort mit 'bash' neu starten:
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night Hyprland – Firewall-Manager (UFW)              ║
# ║  Grundschutz mit sinnvollen Standardregeln für Arch Linux   ║
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

# ── Root- & Sudo-Prüfung ──────────────────────────────────────
if [[ "${EUID}" -eq 0 ]]; then
    echo -e "${RED}Fehler: Bitte starte dieses Skript NICHT direkt als root!${NC}"
    echo -e "Starte das Skript als normaler Benutzer mit sudo-Rechten."
    exit 1
fi

ensure_sudo() {
    if ! sudo -v 2>/dev/null; then
        info "Bitte gib dein sudo-Passwort ein, um Firewall-Einstellungen zu ändern:"
        sudo -v || { error "sudo-Authentifizierung fehlgeschlagen."; exit 1; }
    fi
}

# ── UFW Verfügbarkeit prüfen & ggf. installieren ──────────────
ensure_ufw_installed() {
    if ! command -v ufw &>/dev/null; then
        warn "UFW (Uncomplicated Firewall) ist nicht installiert."
        read -rp "Möchtest du ufw jetzt installieren? [J/n]: " inst_ufw
        inst_ufw="${inst_ufw:-j}"
        if [[ "${inst_ufw}" =~ ^[jJyY]$ ]]; then
            ensure_sudo
            info "Installiere ufw via pacman..."
            sudo pacman -S --needed --noconfirm ufw
            success "ufw erfolgreich installiert!"
        else
            error "Ohne ufw kann der Firewall-Schutz nicht konfiguriert werden."
            exit 1
        fi
    fi
}

# ── Standardregeln anwenden ───────────────────────────────────
apply_standard_rules() {
    ensure_ufw_installed
    ensure_sudo
    header "UFW Firewall-Grundschutz einrichten"
    info "Wende empfohlene Sicherheitsregeln an:"
    echo -e "  ${CYAN}• Eingehender Datenverkehr:${NC}   ${RED}${BOLD}BLOCKIERT (deny)${NC} – Unsichtbar für Port-Scans im Netzwerk"
    echo -e "  ${CYAN}• Ausgehender Datenverkehr:${NC}   ${GREEN}${BOLD}ERLAUBT (allow)${NC} – Internet, Updates, Pentest-Tools ungestört"
    echo -e "  ${CYAN}• Weiterleitung (Routed):${NC}     ${RED}${BOLD}BLOCKIERT (deny)${NC}"
    echo ""

    info "Setze Standard-Richtlinien..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw default deny routed

    # Systemd-Dienst aktivieren und starten
    info "Aktiviere ufw.service im System..."
    sudo systemctl enable --now ufw.service 2>/dev/null || true

    # UFW aktivieren
    info "Aktiviere UFW Firewall-Regeln..."
    sudo ufw --force enable

    success "Firewall ist jetzt AKTIV und schützt dein System zuverlässig vor fremden Zugriffen!"
    echo ""
    sudo ufw status verbose
}

# ── Status anzeigen ───────────────────────────────────────────
show_status() {
    header "Aktueller UFW Firewall-Status"
    if ! command -v ufw &>/dev/null; then
        warn "UFW ist noch nicht installiert."
        return
    fi
    ensure_sudo
    sudo ufw status verbose
    echo ""
    if sudo ufw status 2>/dev/null | grep -qw "active"; then
        success "Firewall ist aktiv."
    else
        warn "Firewall ist aktuell INAKTIV."
    fi
}

# ── Dienst oder Port freigeben ────────────────────────────────
allow_preset() {
    ensure_ufw_installed
    ensure_sudo
    header "Dienst / Port in Firewall freigeben"

    echo "Wähle einen vordefinierten Dienst oder manuellen Port:"
    echo "  1) SSH (Port 22/tcp) – Fernzugriff"
    echo "  2) Syncthing (Port 22000/tcp + 21027/udp) – Dateisynchronisation"
    echo "  3) KDE Connect (Port 1714-1764/tcp & udp) – Smartphone-Kopplung"
    echo "  4) Lokales Web-Testing (Port 80, 443, 8080/tcp)"
    echo "  5) Pentest-Listener / Reverse Shell Port (z.B. 4444/tcp für Metasploit/Netcat)"
    echo "  6) Manuellen Port eingeben (z. B. 1337/tcp)"
    echo "  0) Abbrechen"
    echo ""

    read -rp "Auswahl [1-6, 0]: " preset_choice
    case "${preset_choice}" in
        1)
            sudo ufw allow 22/tcp comment 'SSH Remote Access'
            success "Port 22/tcp (SSH) freigegeben!"
            ;;
        2)
            sudo ufw allow 22000/tcp comment 'Syncthing Sync'
            sudo ufw allow 21027/udp comment 'Syncthing Discovery'
            success "Syncthing Ports (22000/tcp, 21027/udp) freigegeben!"
            ;;
        3)
            sudo ufw allow 1714:1764/tcp comment 'KDE Connect TCP'
            sudo ufw allow 1714:1764/udp comment 'KDE Connect UDP'
            success "KDE Connect Ports (1714-1764 tcp/udp) freigegeben!"
            ;;
        4)
            sudo ufw allow 80/tcp comment 'HTTP Web'
            sudo ufw allow 443/tcp comment 'HTTPS Web'
            sudo ufw allow 8080/tcp comment 'HTTP Dev Alt'
            success "Web-Ports (80, 443, 8080/tcp) freigegeben!"
            ;;
        5)
            read -rp "Welcher Listener-Port soll freigegeben werden? [Standard: 4444]: " pen_port
            pen_port="${pen_port:-4444}"
            sudo ufw allow "${pen_port}/tcp" comment "Pentest Listener ${pen_port}"
            success "Pentest-Listener Port ${pen_port}/tcp freigegeben!"
            ;;
        6)
            read -rp "Port oder Port/Protokoll angeben (z. B. 9000 oder 9000/tcp): " cust_port
            if [[ -n "${cust_port}" ]]; then
                sudo ufw allow "${cust_port}"
                success "Regel für '${cust_port}' hinzugefügt!"
            else
                warn "Keine Eingabe gemacht."
            fi
            ;;
        *)
            info "Abgebrochen."
            return
            ;;
    esac
}

# ── Regel löschen ─────────────────────────────────────────────
delete_rule() {
    ensure_ufw_installed
    ensure_sudo
    header "Firewall-Regel entfernen"
    sudo ufw status numbered
    echo ""
    read -rp "Nummer der zu löschenden Regel eingeben (oder Enter zum Abbrechen): " rule_num
    if [[ "${rule_num}" =~ ^[0-9]+$ ]]; then
        sudo ufw --force delete "${rule_num}"
        success "Regel #${rule_num} erfolgreich gelöscht."
    else
        info "Abgebrochen."
    fi
}

# ── Firewall deaktivieren ─────────────────────────────────────
disable_firewall() {
    ensure_ufw_installed
    ensure_sudo
    warn "Möchtest du die Firewall wirklich deaktivieren?"
    read -rp "Bestätigen mit [J/n]: " conf_dis
    conf_dis="${conf_dis:-j}"
    if [[ "${conf_dis}" =~ ^[jJyY]$ ]]; then
        sudo ufw disable
        success "UFW wurde deaktiviert."
    else
        info "Aktion abgebrochen."
    fi
}

# ── CLI-Argumente abfangen ───────────────────────────────────
if [[ "${1:-}" == "--status" ]]; then
    show_status
    exit 0
elif [[ "${1:-}" == "--enable" || "${1:-}" == "--defaults" ]]; then
    apply_standard_rules
    exit 0
elif [[ "${1:-}" == "--disable" ]]; then
    disable_firewall
    exit 0
fi

# ── Hauptmenü (Interaktiv) ───────────────────────────────────
while true; do
    header "Tokyo Night Firewall-Manager (UFW)"
    if command -v ufw &>/dev/null && sudo ufw status 2>/dev/null | grep -qw "active"; then
        echo -e "  Aktueller Status: ${GREEN}${BOLD}AKTIV (Eingehend geschützt)${NC}"
    else
        echo -e "  Aktueller Status: ${RED}${BOLD}INAKTIV oder nicht eingerichtet${NC}"
    fi
    echo ""

    if command -v gum &>/dev/null; then
        ACTION=$(gum choose \
            --header="Wähle eine Firewall-Aktion:" \
            --cursor.foreground="75" \
            --header.foreground="141" \
            "1) Standard-Grundschutz aktivieren (Eingehend sperren, Ausgehend erlauben)" \
            "2) Detaillierten Status & aktive Regeln anzeigen" \
            "3) Port oder Dienst freigeben (SSH, Syncthing, Pentest-Listener...)" \
            "4) Eine freigegebene Regel entfernen" \
            "5) Firewall vorübergehend deaktivieren" \
            "0) Beenden") || true

        case "${ACTION}" in
            1*) apply_standard_rules ;;
            2*) show_status; read -rp "Drücke [Enter] zum Fortfahren..." ;;
            3*) allow_preset; read -rp "Drücke [Enter] zum Fortfahren..." ;;
            4*) delete_rule; read -rp "Drücke [Enter] zum Fortfahren..." ;;
            5*) disable_firewall; read -rp "Drücke [Enter] zum Fortfahren..." ;;
            *)  info "Auf Wiedersehen!"; exit 0 ;;
        esac
    else
        echo "  1) Standard-Grundschutz aktivieren (Eingehend sperren, Ausgehend erlauben)"
        echo "  2) Detaillierten Status & aktive Regeln anzeigen"
        echo "  3) Port oder Dienst freigeben (SSH, Syncthing, Pentest-Listener...)"
        echo "  4) Eine freigegebene Regel entfernen"
        echo "  5) Firewall vorübergehend deaktivieren"
        echo "  0) Beenden"
        echo ""
        read -rp "Auswahl [1-5, 0]: " menu_choice
        case "${menu_choice}" in
            1) apply_standard_rules ;;
            2) show_status; read -rp "Drücke [Enter] zum Fortfahren..." ;;
            3) allow_preset; read -rp "Drücke [Enter] zum Fortfahren..." ;;
            4) delete_rule; read -rp "Drücke [Enter] zum Fortfahren..." ;;
            5) disable_firewall; read -rp "Drücke [Enter] zum Fortfahren..." ;;
            0) info "Auf Wiedersehen!"; exit 0 ;;
            *) warn "Ungültige Auswahl." ;;
        esac
    fi
done
