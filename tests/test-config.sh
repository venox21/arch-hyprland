#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Konfigurationstest – Prüft alle Konfigurationsdateien       ║
# ╚══════════════════════════════════════════════════════════════╝
set -Euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARN=$((WARN + 1)); }

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Tokyo Night – Konfigurationstest                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"

# ── 1. Lua-Dateien existieren ─────────────────────────────────
echo ""
echo -e "${BLUE}── Lua-Konfigurationsdateien ──${NC}"

LUA_FILES=(
    hyprland.lua colors.lua keybinds.lua monitors.lua
    rules.lua animations.lua autostart.lua input.lua
)

for f in "${LUA_FILES[@]}"; do
    if [[ -f "${PROJECT_DIR}/config/hypr/${f}" ]]; then
        pass "${f} existiert"
    else
        fail "${f} fehlt"
    fi
done

# ── 2. Lua-Syntax prüfen ─────────────────────────────────────
echo ""
echo -e "${BLUE}── Lua-Syntaxprüfung ──${NC}"

if command -v luac &>/dev/null; then
    for f in "${LUA_FILES[@]}"; do
        FILE="${PROJECT_DIR}/config/hypr/${f}"
        if [[ -f "${FILE}" ]]; then
            # luac prüft nur Standard-Lua, hl.* wird als Global-Fehler gemeldet
            # Wir suchen nach echten Syntaxfehlern
            OUTPUT="$(luac -p "${FILE}" 2>&1)" || true
            if [[ -z "${OUTPUT}" ]]; then
                pass "${f}: Syntax OK"
            else
                # Prüfe ob nur hl/require-Fehler (erwartbar)
                if echo "${OUTPUT}" | grep -qv "global 'hl'" 2>/dev/null; then
                    warn "${f}: ${OUTPUT}"
                else
                    pass "${f}: Syntax OK (hl.* API-Aufrufe)"
                fi
            fi
        fi
    done
else
    warn "luac nicht installiert – Lua-Syntaxprüfung übersprungen"
fi

# ── 3. Waybar-Konfiguration ──────────────────────────────────
echo ""
echo -e "${BLUE}── Waybar-Konfiguration ──${NC}"

WAYBAR_CONFIG="${PROJECT_DIR}/config/waybar/config.jsonc"
WAYBAR_CSS="${PROJECT_DIR}/config/waybar/style.css"

if [[ -f "${WAYBAR_CONFIG}" ]]; then
    pass "config.jsonc existiert"

    # JSON validieren (JSONC-Kommentare entfernen)
    if command -v jq &>/dev/null; then
        if sed 's|//.*$||g' "${WAYBAR_CONFIG}" | jq . &>/dev/null; then
            pass "config.jsonc: JSON gültig"
        else
            fail "config.jsonc: JSON ungültig"
        fi

        # Module prüfen
        MODULES=$(sed 's|//.*$||g' "${WAYBAR_CONFIG}" | jq -r '.["modules-left"][], .["modules-center"][], .["modules-right"][]' 2>/dev/null)
        if [[ -n "${MODULES}" ]]; then
            pass "Waybar-Module definiert"
        else
            fail "Keine Waybar-Module gefunden"
        fi
    else
        warn "jq nicht installiert – JSON-Validierung übersprungen"
    fi
else
    fail "config.jsonc fehlt"
fi

if [[ -f "${WAYBAR_CSS}" ]]; then
    pass "style.css existiert"
    # CSS-Grundprüfung: geschweifte Klammern ausgeglichen
    OPEN=$(grep -c '{' "${WAYBAR_CSS}" || true)
    CLOSE=$(grep -c '}' "${WAYBAR_CSS}" || true)
    if [[ "${OPEN}" -eq "${CLOSE}" ]]; then
        pass "style.css: Klammern ausgeglichen (${OPEN} Blöcke)"
    else
        fail "style.css: Klammern nicht ausgeglichen (öffnend: ${OPEN}, schließend: ${CLOSE})"
    fi
else
    fail "style.css fehlt"
fi

# ── 4. Rofi-Konfiguration ────────────────────────────────────
echo ""
echo -e "${BLUE}── Rofi-Konfiguration ──${NC}"

ROFI_CONFIG="${PROJECT_DIR}/config/rofi/config.rasi"
if [[ -f "${ROFI_CONFIG}" ]]; then
    pass "config.rasi existiert"
    # Grundprüfung: Klammern
    OPEN=$(grep -c '{' "${ROFI_CONFIG}" || true)
    CLOSE=$(grep -c '}' "${ROFI_CONFIG}" || true)
    if [[ "${OPEN}" -eq "${CLOSE}" ]]; then
        pass "config.rasi: Klammern ausgeglichen"
    else
        fail "config.rasi: Klammern nicht ausgeglichen"
    fi
else
    fail "config.rasi fehlt"
fi

# ── 5. Weitere Konfigurationen ────────────────────────────────
echo ""
echo -e "${BLUE}── Weitere Konfigurationen ──${NC}"

OTHER_FILES=(
    "config/kitty/kitty.conf"
    "config/swaync/config.json"
    "config/swaync/style.css"
    "config/mako/config"
    "config/hyprlock/hyprlock.conf"
    "config/hyprpaper/hyprpaper.conf"
    "config/rofi/wallpaper.rasi"
    "config/zsh/.zshrc"
    "config/starship/starship.toml"
    "assets/desktop/tokyo-shot.desktop"
    "assets/desktop/tokyo-app-installer.desktop"
    "assets/desktop/tokyo-cleaner.desktop"
)

for f in "${OTHER_FILES[@]}"; do
    if [[ -f "${PROJECT_DIR}/${f}" ]]; then
        pass "$(basename "${f}") existiert"
    else
        fail "${f} fehlt"
    fi
done

# ── 6. Skripte ────────────────────────────────────────────────
echo ""
echo -e "${BLUE}── Hilfsskripte ──${NC}"

SCRIPTS=(
    screenshot.sh tokyo-shot power-menu.sh clipboard.sh wallpaper.sh
    waybar-restart.sh backup.sh diagnostics.sh settings.sh hotkeys.sh
    control-center.sh autostart.sh app-installer.sh gamemode.sh clean-system.sh
)

for s in "${SCRIPTS[@]}"; do
    FILE="${PROJECT_DIR}/scripts/${s}"
    if [[ -f "${FILE}" ]]; then
        pass "${s} existiert"
        # Bash-Syntax prüfen
        if bash -n "${FILE}" 2>/dev/null; then
            pass "${s}: Syntax OK"
        else
            fail "${s}: Syntaxfehler"
        fi
    else
        fail "${s} fehlt"
    fi
done

# ── 7. Hotkey-Konflikte ──────────────────────────────────────
echo ""
echo -e "${BLUE}── Hotkey-Konflikte ──${NC}"

KEYBINDS_FILE="${PROJECT_DIR}/config/hypr/keybinds.lua"
if [[ -f "${KEYBINDS_FILE}" ]]; then
    # Alle hl.bind()-Aufrufe extrahieren und auf Duplikate prüfen
    BINDS=$(grep -oP 'hl\.bind\(\s*"\K[^"]+' "${KEYBINDS_FILE}" | sort)
    DUPES=$(echo "${BINDS}" | uniq -d)

    if [[ -z "${DUPES}" ]]; then
        BIND_COUNT=$(echo "${BINDS}" | wc -l)
        pass "Keine Hotkey-Konflikte (${BIND_COUNT} Bindings)"
    else
        fail "Hotkey-Konflikte gefunden:"
        echo "${DUPES}" | while read -r dup; do
            echo -e "    ${RED}Doppelt: ${dup}${NC}"
        done
    fi
else
    warn "keybinds.lua nicht gefunden – Konfliktprüfung übersprungen"
fi

# ── 8. SDDM-Theme ────────────────────────────────────────────
echo ""
echo -e "${BLUE}── SDDM-Theme ──${NC}"

SDDM_FILES=(
    "assets/sddm/tokyo-night/Main.qml"
    "assets/sddm/tokyo-night/metadata.desktop"
    "assets/sddm/tokyo-night/theme.conf"
)

for f in "${SDDM_FILES[@]}"; do
    if [[ -f "${PROJECT_DIR}/${f}" ]]; then
        pass "$(basename "${f}") existiert"
    else
        fail "${f} fehlt"
    fi
done

# ── 9. Installations-Skripte ─────────────────────────────────
echo ""
echo -e "${BLUE}── Installations-Skripte ──${NC}"

for script in install.sh uninstall.sh restore-backup.sh doctor.sh update.sh install-apps.sh; do
    FILE="${PROJECT_DIR}/${script}"
    if [[ -f "${FILE}" ]]; then
        pass "${script} existiert"
        if bash -n "${FILE}" 2>/dev/null; then
            pass "${script}: Syntax OK"
        else
            fail "${script}: Syntaxfehler"
        fi
    else
        fail "${script} fehlt"
    fi
done

# ── 10. Settings-App ─────────────────────────────────────────
echo ""
echo -e "${BLUE}── Einstellungs-App ──${NC}"

PYTHON_FILES=(
    "settings/app.py"
    "settings/hotkey_manager.py"
    "settings/config_manager.py"
    "screenshot/shot_core.py"
    "screenshot/app.py"
)

for f in "${PYTHON_FILES[@]}"; do
    FILE="${PROJECT_DIR}/${f}"
    if [[ -f "${FILE}" ]]; then
        pass "$(basename "${f}") existiert"
        if python3 -c "import ast; ast.parse(open('${FILE}').read())" 2>/dev/null; then
            pass "$(basename "${f}"): Python-Syntax OK"
        else
            fail "$(basename "${f}"): Syntaxfehler"
        fi
    else
        fail "${f} fehlt"
    fi
done

# ── Zusammenfassung ───────────────────────────────────────────
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}Bestanden:${NC} ${PASS}"
echo -e "  ${YELLOW}Warnungen:${NC} ${WARN}"
echo -e "  ${RED}Fehler:${NC}    ${FAIL}"
echo ""

if [[ ${FAIL} -gt 0 ]]; then
    echo -e "${RED}${FAIL} Tests fehlgeschlagen.${NC}"
    exit 1
else
    echo -e "${GREEN}Alle Tests bestanden!${NC}"
    exit 0
fi
