#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Power-Menü via Rofi                                         ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Sprache ermitteln ─────────────────────────────────────────
LANG_SETTING="de"
SETTINGS_FILE="${HOME}/.config/hypr/settings/user_settings.json"
if [[ -f "${SETTINGS_FILE}" ]]; then
    LANG_SETTING="$(grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' "${SETTINGS_FILE}" | cut -d'"' -f4 || echo 'de')"
elif [[ "${LANG:-}" =~ ^en ]]; then
    LANG_SETTING="en"
fi

if [[ "${LANG_SETTING}" =~ ^en ]]; then
    LOCK="  Lock"
    LOGOUT="  Log Out"
    REBOOT="  Restart"
    SHUTDOWN="  Shut Down"
    SUSPEND="  Suspend"
    CONFIRM_PROMPT="Are you sure?"
    CONFIRM_OPTIONS="Yes\nNo"
    CONFIRM_YES="Yes"
else
    LOCK="  Sperren"
    LOGOUT="  Abmelden"
    REBOOT="  Neustart"
    SHUTDOWN="  Herunterfahren"
    SUSPEND="  Standby"
    CONFIRM_PROMPT="Bist du sicher?"
    CONFIRM_OPTIONS="Ja\nNein"
    CONFIRM_YES="Ja"
fi

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
    answer="$(echo -e "${CONFIRM_OPTIONS}" | rofi -dmenu \
        -i \
        -p "${CONFIRM_PROMPT}" \
        -theme-str 'window { width: 200px; }' \
        -theme-str 'listview { lines: 2; }' \
        -theme ~/.config/rofi/config.rasi \
        2>/dev/null)" || return 1
    [[ "${answer}" == "${CONFIRM_YES}" ]]
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
