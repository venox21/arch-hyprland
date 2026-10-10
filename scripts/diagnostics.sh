#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Diagnose-Skript                                             ║
# ╚══════════════════════════════════════════════════════════════╝
set -Euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

check_pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
check_warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARN=$((WARN + 1)); }
check_fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }
section()    { echo -e "\n${BLUE}── $1 ──${NC}"; }

echo ""
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  Tokyo Night Hyprland – Diagnose                        ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"

# ── System ────────────────────────────────────────────────────
section "System"
if [[ -f /etc/arch-release ]]; then
    check_pass "Arch Linux erkannt"
else
    check_fail "Kein Arch Linux"
fi

if [[ "$XDG_SESSION_TYPE" == "wayland" ]] 2>/dev/null; then
    check_pass "Wayland-Sitzung aktiv"
elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    check_pass "Wayland-Display: ${WAYLAND_DISPLAY}"
else
    check_warn "Keine Wayland-Sitzung erkannt (normal außerhalb von Hyprland)"
fi

# ── Pakete ────────────────────────────────────────────────────
section "Installierte Pakete"
REQUIRED_PKGS=(
    hyprland waybar rofi-wayland kitty mako hyprlock hyprpaper
    thunar zsh starship grim slurp wl-clipboard cliphist
    pipewire wireplumber pamixer brightnessctl playerctl
    jq xdg-desktop-portal-hyprland polkit-gnome python-gobject
    gtk4 libadwaita ttf-jetbrains-mono-nerd noto-fonts sddm
)

for pkg in "${REQUIRED_PKGS[@]}"; do
    if pacman -Qi "${pkg}" &>/dev/null; then
        VERSION="$(pacman -Qi "${pkg}" 2>/dev/null | grep "^Version" | awk '{print $3}')"
        check_pass "${pkg} ${VERSION}"
    else
        check_fail "${pkg} nicht installiert"
    fi
done

# ── Hyprland ──────────────────────────────────────────────────
section "Hyprland"
if command -v hyprctl &>/dev/null; then
    HYPR_VERSION="$(hyprctl version 2>/dev/null | head -1 || echo 'unbekannt')"
    check_pass "hyprctl verfügbar: ${HYPR_VERSION}"
else
    check_warn "hyprctl nicht verfügbar (Hyprland läuft nicht?)"
fi

# ── Konfigurationsdateien ────────────────────────────────────
section "Konfigurationsdateien"
CONFIG_FILES=(
    "${HOME}/.config/hypr/hyprland.lua"
    "${HOME}/.config/hypr/colors.lua"
    "${HOME}/.config/hypr/keybinds.lua"
    "${HOME}/.config/hypr/monitors.lua"
    "${HOME}/.config/hypr/rules.lua"
    "${HOME}/.config/hypr/animations.lua"
    "${HOME}/.config/hypr/autostart.lua"
    "${HOME}/.config/hypr/input.lua"
    "${HOME}/.config/waybar/config.jsonc"
    "${HOME}/.config/waybar/style.css"
    "${HOME}/.config/kitty/kitty.conf"
    "${HOME}/.config/rofi/config.rasi"
    "${HOME}/.config/swaync/config.json"
    "${HOME}/.config/swaync/style.css"
    "${HOME}/.config/hypr/hyprlock.conf"
    "${HOME}/.config/hypr/hyprpaper.conf"
    "${HOME}/.zshrc"
    "${HOME}/.config/starship.toml"
)

for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "${file}" ]]; then
        check_pass "$(basename "${file}")"
    else
        check_fail "${file} fehlt"
    fi
done

# ── Dienste ───────────────────────────────────────────────────
section "Systemdienste"
if systemctl is-enabled sddm &>/dev/null; then
    check_pass "SDDM aktiviert"
else
    check_warn "SDDM nicht aktiviert"
fi

if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    check_pass "NetworkManager aktiv"
else
    check_warn "NetworkManager nicht aktiv"
fi

if systemctl --user is-active --quiet pipewire 2>/dev/null; then
    check_pass "PipeWire aktiv"
else
    check_warn "PipeWire nicht aktiv"
fi

# ── Laufende Prozesse ─────────────────────────────────────────
section "Laufende Prozesse"
if pgrep -x "swaync" &>/dev/null; then
    check_pass "swaync läuft (Kontrollzentrum)"
elif pgrep -x "mako" &>/dev/null; then
    check_pass "mako läuft"
else
    check_warn "Weder swaync noch mako läuft"
fi

for proc in waybar hyprpaper; do
    if pgrep -x "${proc}" &>/dev/null; then
        check_pass "${proc} läuft"
    else
        check_warn "${proc} läuft nicht"
    fi
done

# ── Sensoren ──────────────────────────────────────────────────
section "Hardware-Sensoren"
if [[ -d /sys/class/thermal/thermal_zone0 ]]; then
    TEMP="$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)"
    TEMP_C="$((TEMP / 1000))"
    check_pass "CPU-Temperatur verfügbar: ${TEMP_C}°C"
else
    check_warn "Kein CPU-Temperatursensor gefunden"
fi

if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
    check_pass "Akku erkannt"
else
    check_warn "Kein Akku erkannt (normal bei Desktop-PCs)"
fi

if command -v nvidia-smi &>/dev/null; then
    check_pass "NVIDIA GPU erkannt"
elif [[ -d /sys/class/drm/card0/device ]]; then
    GPU="$(cat /sys/class/drm/card0/device/vendor 2>/dev/null || echo 'unbekannt')"
    check_pass "GPU erkannt: Vendor ${GPU}"
else
    check_warn "GPU-Informationen nicht verfügbar"
fi

# ── Zusammenfassung ───────────────────────────────────────────
echo ""
echo -e "${MAGENTA}── Zusammenfassung ──${NC}"
echo -e "  ${GREEN}Bestanden:${NC} ${PASS}"
echo -e "  ${YELLOW}Warnungen:${NC} ${WARN}"
echo -e "  ${RED}Fehler:${NC}    ${FAIL}"
echo ""

if [[ ${FAIL} -gt 0 ]]; then
    echo -e "${RED}Es gibt ${FAIL} Fehler. Bitte prüfe die obigen Meldungen.${NC}"
    exit 1
elif [[ ${WARN} -gt 0 ]]; then
    echo -e "${YELLOW}Es gibt ${WARN} Warnungen. Das System sollte trotzdem funktionieren.${NC}"
    exit 0
else
    echo -e "${GREEN}Alles in Ordnung! Dein Tokyo Night Desktop ist bereit.${NC}"
    exit 0
fi
