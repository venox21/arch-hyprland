#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Power-Menü via Rofi                                         ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Optionen ──────────────────────────────────────────────────
LOCK="  Sperren"
LOGOUT="  Abmelden"
REBOOT="  Neustart"
SHUTDOWN="  Herunterfahren"
SUSPEND="  Standby"

OPTIONS="${LOCK}\n${LOGOUT}\n${SUSPEND}\n${REBOOT}\n${SHUTDOWN}"

# ── Rofi-Menü anzeigen ───────────────────────────────────────
CHOSEN="$(echo -e "${OPTIONS}" | rofi -dmenu \
    -i \
    -p "Power" \
    -theme-str 'window { width: 280px; }' \
    -theme-str 'listview { lines: 5; }' \
    -theme ~/.config/rofi/config.rasi \
    2>/dev/null)" || exit 0

# ── Bestätigung für kritische Aktionen ────────────────────────
confirm() {
    local answer
    answer="$(echo -e "Ja\nNein" | rofi -dmenu \
        -i \
        -p "Bist du sicher?" \
        -theme-str 'window { width: 200px; }' \
        -theme-str 'listview { lines: 2; }' \
        -theme ~/.config/rofi/config.rasi \
        2>/dev/null)" || return 1
    [[ "${answer}" == "Ja" ]]
}

# ── Aktion ausführen ──────────────────────────────────────────
case "${CHOSEN}" in
    "${LOCK}")
        hyprlock
        ;;
    "${LOGOUT}")
        if confirm; then
            hyprctl dispatch exit
        fi
        ;;
    "${REBOOT}")
        if confirm; then
            systemctl reboot
        fi
        ;;
    "${SHUTDOWN}")
        if confirm; then
            systemctl poweroff
        fi
        ;;
    "${SUSPEND}")
        hyprlock &
        sleep 0.5
        systemctl suspend
        ;;
    *)
        exit 0
        ;;
esac
