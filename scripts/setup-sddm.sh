#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night – SDDM Login-Screen Einrichten & Aktualisieren ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
THEME_SRC="${REPO_DIR}/assets/sddm/tokyo-night"
THEME_DEST="/usr/share/sddm/themes/tokyo-night"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF_FILE="${SDDM_CONF_DIR}/tokyo-night.conf"

echo ""
echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}${BOLD}║  Tokyo Night – SDDM Login-Screen Einrichtung            ║${NC}"
echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Quelle prüfen
if [[ ! -d "${THEME_SRC}" || ! -f "${THEME_SRC}/Main.qml" ]]; then
    echo -e "${RED}[FEHLER]${NC} Quell-Theme nicht gefunden unter: ${THEME_SRC}"
    exit 1
fi

# 2. Sudo-Berechtigung anfordern
echo -e "${BLUE}[1/4] Administrator-Rechte anfordern...${NC}"
if ! sudo -v; then
    echo -e "${RED}[FEHLER]${NC} Administrator-Rechte erforderlich, um /usr/share/sddm zu bearbeiten."
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Berechtigung bestätigt"

# 3. Theme-Dateien installieren / aktualisieren
echo -e "${BLUE}[2/4] Theme-Dateien nach ${THEME_DEST} installieren...${NC}"
sudo mkdir -p "${THEME_DEST}"
sudo cp -rf "${THEME_SRC}/"* "${THEME_DEST}/"
sudo chmod -R 755 "${THEME_DEST}"

# Wallpaper synchronisieren
USER_HOME="${HOME}"
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    USER_HOME="$(getent passwd "${SUDO_USER}" 2>/dev/null | cut -d: -f6 || echo "${HOME}")"
fi
CURRENT_WP="${USER_HOME}/.config/hypr/wallpapers/current.jpg"
if [[ -f "${CURRENT_WP}" ]]; then
    sudo cp -f "${CURRENT_WP}" "${THEME_DEST}/background.jpg" 2>/dev/null || true
    sudo chmod 644 "${THEME_DEST}/background.jpg" 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Aktuelles Desktop-Wallpaper als Login-Hintergrund synchronisiert"
fi
echo -e "  ${GREEN}✓${NC} Modernes Tokyo Night Theme kopiert (Main.qml, theme.conf, metadata)"

# 4. SDDM-Konfiguration sicherstellen
echo -e "${BLUE}[3/4] SDDM-Konfiguration anpassen...${NC}"
sudo mkdir -p "${SDDM_CONF_DIR}"
echo -e "[Theme]\nCurrent=tokyo-night" | sudo tee "${SDDM_CONF_FILE}" >/dev/null
sudo chmod 644 "${SDDM_CONF_FILE}"

# Falls eine alte /etc/sddm.conf ein anderes Theme erzwingt, korrigieren
if [[ -f /etc/sddm.conf ]]; then
    if grep -q "^\[Theme\]" /etc/sddm.conf 2>/dev/null; then
        sudo sed -i '/^\[Theme\]/,/^\[/ s/^Current=.*/Current=tokyo-night/' /etc/sddm.conf 2>/dev/null || true
    fi
fi

# QML-Cache leeren (verhindert das Laden veralteter kompilierter QML-Stände)
sudo rm -rf /var/lib/sddm/.cache 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} SDDM ist auf Theme 'tokyo-night' konfiguriert"
echo -e "  ${GREEN}✓${NC} Veralteter SDDM QML-Cache geleert"

# 5. SDDM-Dienst prüfen
echo -e "${BLUE}[4/4] SDDM-Dienst prüfen...${NC}"
if ! systemctl is-enabled sddm.service &>/dev/null; then
    sudo systemctl enable sddm.service 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} SDDM-Dienst als Standard-Login aktiviert"
else
    echo -e "  ${GREEN}✓${NC} SDDM-Dienst ist bereits aktiv"
fi

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  SDDM Login-Screen wurde erfolgreich aktualisiert!       ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Vorschau-Test anbieten
if [[ "${1:-}" == "--test" || "${1:-}" == "-t" ]]; then
    echo -e "${BLUE}Starte Login-Screen Vorschau im Fenster...${NC}"
    if command -v sddm-greeter &>/dev/null; then
        sddm-greeter --test-mode --theme "${THEME_DEST}" 2>/dev/null &
    else
        echo -e "${YELLOW}Hinweis:${NC} sddm-greeter nicht direkt aufrufbar."
    fi
else
    echo -e "Tipp: Du kannst den neuen Login-Screen direkt in einem Testfenster ansehen mit:"
    echo -e "  ${BOLD}sddm-greeter --test-mode --theme ${THEME_DEST}${NC}"
fi
echo ""
