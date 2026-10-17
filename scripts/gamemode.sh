#!/usr/bin/env bash
# Falls das Skript mit 'sh' (oder dash) aufgerufen wurde, sofort mit 'bash' neu starten:
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night – GameMode / Performance-Toggle                 ║
# ║  Schaltet Animationen & Effekte für maximale FPS ab          ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

CACHE_DIR="${HOME}/.cache"
mkdir -p "${CACHE_DIR}"
STATE_FILE="${CACHE_DIR}/gamemode_active"

notify() {
    local title="$1"
    local body="${2:-}"
    local icon="${3:-applications-games}"
    if command -v notify-send &>/dev/null; then
        notify-send -a "GameMode" -i "${icon}" "${title}" "${body}" -t 3500
    fi
}

is_active() {
    [[ -f "${STATE_FILE}" ]]
}

enable_gamemode() {
    touch "${STATE_FILE}"

    # 1. Hyprland Effekte für minimale Latenz und maximale FPS optimieren
    if command -v hyprctl &>/dev/null; then
        hyprctl --batch "\
            keyword animations:enabled false;\
            keyword decoration:blur:enabled false;\
            keyword decoration:drop_shadow false;\
            keyword decoration:rounding 0;\
            keyword general:gaps_in 0;\
            keyword general:gaps_out 0;\
            keyword general:border_size 1;\
            keyword general:allow_tearing true;\
            keyword decoration:dim_inactive false" >/dev/null 2>&1 || true
    fi

    # 2. CPU Performance-Governor setzen (falls unterstützt)
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set performance >/dev/null 2>&1 || true
    elif command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g performance >/dev/null 2>&1 || true
    fi

    notify "🎮 GameMode aktiviert" "Animationen, Blur, Schatten & Gaps pausiert.\nTearing & Performance-Governor aktiv." "applications-games"
}

disable_gamemode() {
    rm -f "${STATE_FILE}"

    # 1. Tokyo Night Standard-Optik wiederherstellen
    if command -v hyprctl &>/dev/null; then
        hyprctl --batch "\
            keyword animations:enabled true;\
            keyword decoration:blur:enabled true;\
            keyword decoration:drop_shadow true;\
            keyword decoration:rounding 8;\
            keyword general:gaps_in 4;\
            keyword general:gaps_out 8;\
            keyword general:border_size 2;\
            keyword general:allow_tearing false;\
            keyword decoration:dim_inactive true" >/dev/null 2>&1 || true
    fi

    # 2. CPU Governor auf balanced zurücksetzen
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set balanced >/dev/null 2>&1 || true
    elif command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g powersave >/dev/null 2>&1 || true
    fi

    notify "🎮 GameMode deaktiviert" "Tokyo Night Look & Feel (Blur, Schatten & Animationen) wiederhergestellt." "preferences-desktop-display"
}

toggle_gamemode() {
    if is_active; then
        disable_gamemode
    else
        enable_gamemode
    fi
}

status_gamemode() {
    if is_active; then
        echo "true"
    else
        echo "false"
    fi
}

case "${1:-toggle}" in
    --enable|enable|on)    enable_gamemode ;;
    --disable|disable|off) disable_gamemode ;;
    --toggle|toggle)       toggle_gamemode ;;
    --status|status)       status_gamemode ;;
    *)
        echo "Verwendung: $0 {--toggle|--enable|--disable|--status}"
        exit 1
        ;;
esac
