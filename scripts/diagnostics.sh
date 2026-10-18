#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Diagnose-Skript – Erweiterte System- & Hardware-Prüfung     ║
# ║  Prüft Pakete, Dienste, Failed-Units, Disks, SMART & Logs   ║
# ╚══════════════════════════════════════════════════════════════╝
set -Euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
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
echo -e "${MAGENTA}║  Tokyo Night Hyprland – System-Diagnose (Doctor)        ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"

# ── System ────────────────────────────────────────────────────
section "System"
if [[ -f /etc/arch-release ]]; then
    check_pass "Arch Linux erkannt"
else
    check_fail "Kein Arch Linux"
fi

if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] 2>/dev/null; then
    check_pass "Wayland-Sitzung aktiv"
elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    check_pass "Wayland-Display: ${WAYLAND_DISPLAY}"
else
    check_warn "Keine Wayland-Sitzung erkannt (normal außerhalb von Hyprland)"
fi

# Lokalisierung & Tastaturlayout
if [[ -f "${HOME}/.config/locale.conf" ]]; then
    loc="$(grep -E '^LANG=' "${HOME}/.config/locale.conf" 2>/dev/null | cut -d= -f2 || true)"
    [[ -n "${loc}" ]] && check_pass "Lokalisierung (locale.conf): ${loc}"
elif [[ -f /etc/locale.conf ]]; then
    loc="$(grep -E '^LANG=' /etc/locale.conf 2>/dev/null | cut -d= -f2 || true)"
    [[ -n "${loc}" ]] && check_pass "Lokalisierung (/etc/locale.conf): ${loc}"
fi

if [[ -f "${HOME}/.config/hypr/input.lua" ]]; then
    kb="$(grep -E 'kb_layout\s*=' "${HOME}/.config/hypr/input.lua" 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/' || true)"
    [[ -n "${kb}" ]] && check_pass "Tastaturlayout (input.lua): ${kb}"
fi

# ── Pakete ────────────────────────────────────────────────────
section "Installierte Pakete"
REQUIRED_PKGS=(
    hyprland waybar rofi-wayland kitty hyprlock hyprpaper
    thunar zsh starship grim slurp wl-clipboard cliphist
    pipewire wireplumber pamixer brightnessctl playerctl
    jq xdg-desktop-portal-hyprland polkit-gnome python-gobject
    python-cairo gtk4 libadwaita ttf-jetbrains-mono-nerd noto-fonts sddm
)

for pkg in "${REQUIRED_PKGS[@]}"; do
    if pacman -Qi "${pkg}" &>/dev/null; then
        VERSION="$(pacman -Qi "${pkg}" 2>/dev/null | grep "^Version" | awk '{print $3}')"
        check_pass "${pkg} ${VERSION}"
    else
        check_fail "${pkg} nicht installiert"
    fi
done

# Benachrichtigungsdaemon (SwayNC bevorzugt)
if pacman -Qi swaync &>/dev/null; then
    VERSION="$(pacman -Qi swaync 2>/dev/null | grep "^Version" | awk '{print $3}')"
    check_pass "swaync ${VERSION} (Kontrollzentrum)"
elif pacman -Qi mako &>/dev/null; then
    VERSION="$(pacman -Qi mako 2>/dev/null | grep "^Version" | awk '{print $3}')"
    check_pass "mako ${VERSION} (Fallback)"
else
    check_fail "Weder swaync noch mako installiert"
fi

# Empfohlene Tools
if pacman -Qi papirus-icon-theme &>/dev/null; then
    check_pass "papirus-icon-theme installiert"
else
    check_warn "papirus-icon-theme fehlt (empfohlen: sudo pacman -S papirus-icon-theme)"
fi

if pacman -Qi blueman &>/dev/null; then
    check_pass "blueman installiert (Bluetooth-GUI)"
else
    check_warn "blueman fehlt (empfohlen: sudo pacman -S blueman)"
fi

if pacman -Qi ufw &>/dev/null; then
    check_pass "ufw installiert (Firewall)"
else
    check_warn "ufw fehlt (empfohlen: tokyo-firewall oder sudo pacman -S ufw)"
fi

if pacman -Qi smartmontools &>/dev/null; then
    check_pass "smartmontools installiert (Festplattendiagnose)"
else
    check_warn "smartmontools fehlt (empfohlen für SMART-Check: sudo pacman -S smartmontools)"
fi

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

if systemctl is-active --quiet bluetooth 2>/dev/null; then
    check_pass "Bluetooth aktiv"
else
    check_warn "Bluetooth nicht aktiv (sudo systemctl enable --now bluetooth)"
fi

if systemctl --user is-active --quiet pipewire 2>/dev/null; then
    check_pass "PipeWire aktiv"
else
    check_warn "PipeWire nicht aktiv"
fi

# ── Firewall & Netzwerkschutz (UFW) ───────────────────────────
section "Firewall & Netzwerkschutz"
if command -v ufw &>/dev/null; then
    UFW_STATUS="$(sudo ufw status 2>/dev/null || true)"
    if echo "${UFW_STATUS}" | grep -qw "active"; then
        check_pass "UFW Firewall ist AKTIV (eingehende Verbindungen geschützt)"
    elif systemctl is-active --quiet ufw 2>/dev/null; then
        check_pass "UFW Dienst ist aktiv"
    else
        check_warn "UFW Firewall ist INAKTIV (Aktivieren mit 'tokyo-firewall')"
    fi
else
    check_warn "UFW Firewall ist nicht installiert (empfohlen: tokyo-firewall)"
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

# ── Fehlgeschlagene Systemd-Units ─────────────────────────────
section "Systemd Fehlgeschlagene Einheiten (Failed Units)"
FAILED_SYS="$(systemctl --failed --no-legend 2>/dev/null || true)"
FAILED_USER="$(systemctl --user --failed --no-legend 2>/dev/null || true)"

if [[ -z "${FAILED_SYS}" && -z "${FAILED_USER}" ]]; then
    check_pass "Keine fehlgeschlagenen Systemd-Dienste (System & User)"
else
    if [[ -n "${FAILED_SYS}" ]]; then
        SYS_COUNT=$(echo "${FAILED_SYS}" | grep -c '.' || true)
        check_fail "${SYS_COUNT} fehlgeschlagene System-Dienst(e) (systemctl --failed):"
        while IFS= read -r line; do
            [[ -n "${line}" ]] && echo -e "      ${RED}●${NC} $(echo "${line}" | awk '{print $1, $2, $3, $4}')"
        done <<< "${FAILED_SYS}"
    fi
    if [[ -n "${FAILED_USER}" ]]; then
        USER_COUNT=$(echo "${FAILED_USER}" | grep -c '.' || true)
        check_warn "${USER_COUNT} fehlgeschlagene User-Dienst(e) (systemctl --user --failed):"
        while IFS= read -r line; do
            [[ -n "${line}" ]] && echo -e "      ${YELLOW}●${NC} $(echo "${line}" | awk '{print $1, $2, $3, $4}')"
        done <<< "${FAILED_USER}"
    fi
fi

# ── Speicherplatz & Partitionen ───────────────────────────────
section "Speicherplatz & Partitionen (Disk Space)"
CHECK_MOUNTS=("/" "/home" "/boot")
for mount_point in "${CHECK_MOUNTS[@]}"; do
    if findmnt -M "${mount_point}" &>/dev/null; then
        USAGE_LINE="$(df -h "${mount_point}" 2>/dev/null | awk 'NR==2 {print $2, $3, $4, $5}')"
        if [[ -n "${USAGE_LINE}" ]]; then
            TOTAL="$(echo "${USAGE_LINE}" | awk '{print $1}')"
            USED="$(echo "${USAGE_LINE}" | awk '{print $2}')"
            AVAIL="$(echo "${USAGE_LINE}" | awk '{print $3}')"
            PCT_STR="$(echo "${USAGE_LINE}" | awk '{print $4}')"
            PCT="${PCT_STR%\%}"

            if [[ "${PCT}" -ge 95 ]]; then
                check_fail "${mount_point}: ${USED}/${TOTAL} belegt (${PCT_STR}) – KRITISCH: nur noch ${AVAIL} frei!"
            elif [[ "${PCT}" -ge 85 ]]; then
                check_warn "${mount_point}: ${USED}/${TOTAL} belegt (${PCT_STR}) – Bereinigung empfohlen (${AVAIL} frei)"
            else
                check_pass "${mount_point}: ${USED}/${TOTAL} belegt (${PCT_STR}, ${AVAIL} frei)"
            fi
        fi
    fi
done

# ── Festplattengesundheit (SMART-Status) ───────────────────────
section "Festplattengesundheit (SMART-Status)"
if command -v smartctl &>/dev/null; then
    DISKS=()
    if [[ -x /usr/bin/lsblk ]]; then
        while IFS= read -r disk; do
            [[ -n "${disk}" ]] && DISKS+=("/dev/${disk}")
        done < <(lsblk -d -n -o NAME,TYPE 2>/dev/null | awk '$2=="disk" && $1!~/(loop|zram|ram|sr[0-9])/ {print $1}')
    fi

    if [[ ${#DISKS[@]} -eq 0 ]]; then
        check_warn "Keine physischen Festplatten zur SMART-Prüfung erkannt"
    else
        for disk in "${DISKS[@]}"; do
            SMART_OUT="$(sudo smartctl -H "${disk}" 2>/dev/null || true)"
            if echo "${SMART_OUT}" | grep -qE "(PASSED|OK|health status: OK)"; then
                check_pass "$(basename "${disk}"): SMART-Gesundheitsstatus OK"
            elif [[ -z "${SMART_OUT}" ]]; then
                check_warn "$(basename "${disk}"): SMART-Status benötigt sudo-Rechte (sudo smartctl -H ${disk})"
            else
                check_fail "$(basename "${disk}"): Auffälliger SMART-Status! Prüfen mit: sudo smartctl -a ${disk}"
            fi
        done
    fi
else
    check_warn "smartctl nicht installiert (sudo pacman -S smartmontools für automatische Festplattenprüfung)"
fi

# ── System-Logs & Journal-Fehler ──────────────────────────────
section "System-Logs & Journal-Fehler (journalctl)"
if command -v journalctl &>/dev/null; then
    ERR_COUNT="$(journalctl -b -p 3 --no-pager -q 2>/dev/null | grep -c '.' || echo 0)"
    if [[ "${ERR_COUNT}" -eq 0 ]]; then
        check_pass "Keine kritischen Fehler im aktuellen Boot-Journal (Priorität 0-3)"
    elif [[ "${ERR_COUNT}" -le 5 ]]; then
        check_pass "Nur ${ERR_COUNT} unkritische Fehler/Meldungen im aktuellen Boot"
    else
        check_warn "${ERR_COUNT} Fehlereinträge im Boot-Journal gefunden (journalctl -p 3 -xb)"
        echo -e "      ${YELLOW}Letzte Meldungen:${NC}"
        journalctl -b -p 3 --no-pager -n 3 -q 2>/dev/null | sed 's/^/        /' || true
    fi
else
    check_warn "journalctl nicht verfügbar"
fi

# ── Hardware-Sensoren ─────────────────────────────────────────
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
