#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night – Arch System-Cleaner                           ║
# ║  Bereinigt Paket-Caches, Logs, Orphans & Caches              ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Farben (Tokyo Night) ──────────────────────────────────────
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

notify() {
    local title="$1"
    local body="${2:-}"
    if command -v notify-send &>/dev/null; then
        notify-send -a "System-Cleaner" -i "edit-clear" "${title}" "${body}" -t 4000
    fi
}

# Vorherigen freien Speicherplatz auf der Root-Partition ermitteln (in KB)
SPACE_BEFORE=$(df -k / | awk 'NR==2 {print $4}')

header "Tokyo Night – System-Cleaner"

# Prüfe sudo-Berechtigung vorab
if ! sudo -v 2>/dev/null; then
    info "Bitte gib dein sudo-Passwort ein, um die Systembereinigung durchzuführen:"
    sudo -v || { echo -e "${RED}Authentifizierung fehlgeschlagen.${NC}"; exit 1; }
fi

# ── 1. Pacman & AUR Cache bereinigen ──────────────────────────
echo -e "${CYAN}${BOLD}[1/5] Paket-Cache bereinigen...${NC}"

if command -v paccache &>/dev/null; then
    info "Behalte nur die 2 neuesten Versionen installierter Pakete (paccache -rk2)..."
    sudo paccache -rk2 || true
    info "Entferne Caches deinstallierter Pakete (paccache -ruk0)..."
    sudo paccache -ruk0 || true
    success "Pacman-Cache via paccache optimiert."
else
    # Fallback wenn pacman-contrib nicht installiert ist
    info "pacman-contrib nicht gefunden. Installiere pacman-contrib für paccache..."
    sudo pacman -S --needed --noconfirm pacman-contrib 2>/dev/null && {
        sudo paccache -rk2 || true
        sudo paccache -ruk0 || true
        success "Pacman-Cache via paccache optimiert."
    } || {
        info "Bereinige nicht mehr benötigte Pakete mit pacman -Sc..."
        echo "y" | sudo pacman -Sc 2>/dev/null || true
    }
fi

if command -v yay &>/dev/null; then
    info "Bereinige AUR-Build-Cache (yay)..."
    # Entferne alte Build-Verzeichnisse in ~/.cache/yay
    if [[ -d "${HOME}/.cache/yay" ]]; then
        find "${HOME}/.cache/yay" -mindepth 1 -maxdepth 2 -type d -name "src" -exec rm -rf {} + 2>/dev/null || true
        find "${HOME}/.cache/yay" -mindepth 1 -maxdepth 2 -type d -name "pkg" -exec rm -rf {} + 2>/dev/null || true
    fi
    echo "y" | yay -Sc --noconfirm 2>/dev/null || true
    success "AUR-Cache bereinigt."
fi

# ── 2. Verwaiste Pakete (Orphans) entfernen ───────────────────
echo ""
echo -e "${CYAN}${BOLD}[2/5] Verwaiste Pakete suchen & entfernen...${NC}"

ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
if [[ -n "${ORPHANS}" ]]; then
    ORPHAN_COUNT=$(echo "${ORPHANS}" | wc -w)
    warn "${ORPHAN_COUNT} verwaiste Pakete gefunden: ${ORPHANS}"
    info "Entferne verwaiste Abhängigkeiten..."
    sudo pacman -Rns --noconfirm ${ORPHANS} 2>/dev/null || true
    success "Verwaiste Pakete entfernt."
else
    success "Keine verwaisten Pakete vorhanden (System ist sauber)."
fi

# ── 3. Systemd Journal Logs stutzen ───────────────────────────
echo ""
echo -e "${CYAN}${BOLD}[3/5] Systemd-Logs (Journal) bereinigen...${NC}"

if command -v journalctl &>/dev/null; then
    JOURNAL_SIZE=$(journalctl --disk-usage 2>/dev/null || echo "unbekannt")
    info "Aktuelle Log-Größe: ${JOURNAL_SIZE}"
    info "Stutze Logs auf max. 3 Tage und max. 100 MB..."
    sudo journalctl --vacuum-time=3d --vacuum-size=100M 2>/dev/null || true
    success "Systemd-Logs erfolgreich bereinigt."
fi

# ── 4. Benutzer-Caches (Thumbnails, Crashlogs) ────────────────
echo ""
echo -e "${CYAN}${BOLD}[4/5] Temporäre Caches & Vorschaubilder bereinigen...${NC}"

# Thumbnails älter als 14 Tage bereinigen
THUMB_DIR="${HOME}/.cache/thumbnails"
if [[ -d "${THUMB_DIR}" ]]; then
    BEFORE_THUMBS=$(du -sh "${THUMB_DIR}" 2>/dev/null | awk '{print $1}')
    find "${THUMB_DIR}" -type f -atime +14 -delete 2>/dev/null || true
    success "Vorschau-Thumbnails bereinigt (vorher: ${BEFORE_THUMBS})."
fi

# Core Dumps stutzen
if [[ -d /var/lib/systemd/coredump ]]; then
    sudo rm -rf /var/lib/systemd/coredump/* 2>/dev/null || true
    success "Alte Core Dumps entfernt."
fi

# ── 5. System-Gesundheitscheck ────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}[5/5] Systemd-Dienste prüfen...${NC}"

FAILED_SERVICES=$(systemctl --failed --no-legend 2>/dev/null || true)
if [[ -n "${FAILED_SERVICES}" ]]; then
    warn "Folgende Dienste sind fehlgeschlagen:"
    echo "${FAILED_SERVICES}" | while read -r line; do
        echo -e "    ${RED}•${NC} ${line}"
    done
else
    success "Alle Systemd-Dienste laufen fehlerfrei!"
fi

# ── Speicherplatz-Auswertung & Zusammenfassung ────────────────
SPACE_AFTER=$(df -k / | awk 'NR==2 {print $4}')
FREED_KB=$((SPACE_AFTER - SPACE_BEFORE))

if [[ ${FREED_KB} -gt 1024000 ]]; then
    FREED_HUMAN="$(awk "BEGIN {printf \"%.2f GB\", ${FREED_KB}/1048576}")"
elif [[ ${FREED_KB} -gt 1024 ]]; then
    FREED_HUMAN="$(awk "BEGIN {printf \"%.1f MB\", ${FREED_KB}/1024}")"
else
    FREED_HUMAN="Caches waren bereits optimiert"
fi

echo ""
header "Systembereinigung abgeschlossen!"

if [[ "${FREED_HUMAN}" =~ (GB|MB) ]]; then
    echo -e "${GREEN}${BOLD}✓ Freigegebener Speicherplatz:${NC} ${BOLD}${FREED_HUMAN}${NC}"
    notify "Systembereinigung abgeschlossen" "Erfolgreich ${FREED_HUMAN} Speicherplatz freigegeben."
else
    echo -e "${GREEN}${BOLD}✓ System war bereits optimal aufgeräumt.${NC}"
    notify "Systembereinigung abgeschlossen" "System ist in einwandfreiem Zustand."
fi

echo ""
