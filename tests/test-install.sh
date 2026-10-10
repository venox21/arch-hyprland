#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Installationstest – Prüft Installation ohne Änderungen      ║
# ║  Sicher: Verändert keine Dateien oder Pakete                 ║
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

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARN=$((WARN + 1)); }

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Tokyo Night – Installationstest                        ║${NC}"
echo -e "${BLUE}║  (Nur Prüfungen, keine Änderungen)                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"

# ── Systemprüfungen ───────────────────────────────────────────
echo ""
echo -e "${BLUE}── System ──${NC}"

if [[ -f /etc/arch-release ]]; then
    pass "Arch Linux"
else
    fail "Kein Arch Linux"
fi

if [[ "${EUID}" -ne 0 ]]; then
    pass "Nicht als Root (korrekt)"
else
    fail "Läuft als Root"
fi

if command -v pacman &>/dev/null; then
    pass "pacman verfügbar"
else
    fail "pacman nicht gefunden"
fi

# ── Paketprüfung ─────────────────────────────────────────────
echo ""
echo -e "${BLUE}── Benötigte Pakete ──${NC}"

REQUIRED=(
    hyprland waybar rofi-wayland kitty mako hyprlock hyprpaper
    thunar zsh starship grim slurp wl-clipboard cliphist
    pipewire wireplumber pamixer sddm jq
    python python-gobject gtk4 libadwaita
    ttf-jetbrains-mono-nerd noto-fonts
)

MISSING=()
for pkg in "${REQUIRED[@]}"; do
    if pacman -Qi "${pkg}" &>/dev/null; then
        pass "${pkg}"
    else
        MISSING+=("${pkg}")
        fail "${pkg} nicht installiert"
    fi
done

# ── Hyprland-Version ──────────────────────────────────────────
echo ""
echo -e "${BLUE}── Hyprland ──${NC}"

if command -v hyprctl &>/dev/null; then
    VERSION="$(hyprctl version 2>/dev/null | head -1 || echo 'nicht verfügbar')"
    pass "Hyprland: ${VERSION}"
else
    if pacman -Qi hyprland &>/dev/null; then
        VERSION="$(pacman -Qi hyprland | grep "^Version" | awk '{print $3}')"
        pass "Hyprland installiert: ${VERSION} (nicht gestartet)"
    else
        fail "Hyprland nicht installiert"
    fi
fi

# ── Display-Manager ───────────────────────────────────────────
echo ""
echo -e "${BLUE}── Display-Manager ──${NC}"

ACTIVE_DM=""
for dm in sddm gdm lightdm ly greetd; do
    if systemctl is-enabled "${dm}.service" &>/dev/null 2>&1; then
        ACTIVE_DM="${dm}"
        break
    fi
done

if [[ -n "${ACTIVE_DM}" ]]; then
    if [[ "${ACTIVE_DM}" == "sddm" ]]; then
        pass "SDDM ist der aktive Display-Manager"
    else
        warn "Aktiver DM: ${ACTIVE_DM} (nicht SDDM)"
    fi
else
    warn "Kein Display-Manager aktiviert"
fi

# ── Fehlende Sensoren ─────────────────────────────────────────
echo ""
echo -e "${BLUE}── Sensoren ──${NC}"

if [[ -d /sys/class/thermal/thermal_zone0 ]]; then
    pass "CPU-Temperatursensor verfügbar"
else
    warn "Kein CPU-Temperatursensor (Waybar-Modul wird fallback verwenden)"
fi

if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
    pass "Akku verfügbar"
else
    warn "Kein Akku (Akku-Modul in Waybar nicht sichtbar)"
fi

# ── Vorhandene Konfigurationen ────────────────────────────────
echo ""
echo -e "${BLUE}── Vorhandene Konfigurationen ──${NC}"

for dir in hypr waybar kitty rofi mako; do
    if [[ -d "${HOME}/.config/${dir}" ]]; then
        warn "${dir}/ existiert bereits (wird bei Installation gesichert)"
    else
        pass "${dir}/ nicht vorhanden (saubere Installation)"
    fi
done

if [[ -f "${HOME}/.zshrc" ]]; then
    warn ".zshrc existiert (wird bei Installation gesichert)"
else
    pass ".zshrc nicht vorhanden"
fi

# ── Shell ─────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}── Shell ──${NC}"

if command -v zsh &>/dev/null; then
    pass "Zsh installiert"
    if [[ "$(basename "${SHELL}")" == "zsh" ]]; then
        pass "Zsh ist Standard-Shell"
    else
        warn "Standard-Shell: $(basename "${SHELL}") (wird bei Installation gefragt)"
    fi
else
    fail "Zsh nicht installiert"
fi

# ── Zusammenfassung ───────────────────────────────────────────
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}Bestanden:${NC} ${PASS}"
echo -e "  ${YELLOW}Warnungen:${NC} ${WARN}"
echo -e "  ${RED}Fehler:${NC}    ${FAIL}"

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Fehlende Pakete installieren mit:${NC}"
    echo "  sudo pacman -S ${MISSING[*]}"
fi

echo ""
if [[ ${FAIL} -gt 0 ]]; then
    echo -e "${RED}System nicht bereit für die Installation.${NC}"
    exit 1
else
    echo -e "${GREEN}System bereit für die Installation!${NC}"
    exit 0
fi
