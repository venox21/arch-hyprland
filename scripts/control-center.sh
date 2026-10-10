#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Kontrollzentrum – Toggles und Status für SwayNC & Waybar    ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

CACHE_DIR="${HOME}/.cache"
mkdir -p "${CACHE_DIR}"

NIGHTMODE_STATE="${CACHE_DIR}/nightmode_active"
POWERSAVE_STATE="${CACHE_DIR}/powersave_active"

# ── Benachrichtigung senden ────────────────────────────────────
notify() {
    local title="$1"
    local body="${2:-}"
    local icon="${3:-preferences-system}"
    if command -v notify-send &>/dev/null; then
        notify-send -a "Kontrollzentrum" -i "${icon}" "${title}" "${body}"
    fi
}

# ── 1. WLAN ────────────────────────────────────────────────────
wifi_toggle() {
    if ! command -v nmcli &>/dev/null; then
        notify "WLAN-Fehler" "NetworkManager (nmcli) ist nicht installiert" "dialog-error"
        return 1
    fi

    local current_state
    current_state="$(nmcli radio wifi 2>/dev/null || echo 'disabled')"
    if [[ "${current_state}" =~ enabled ]]; then
        nmcli radio wifi off
        notify "WLAN deaktiviert" "Drahtlosverbindung ausgeschaltet" "network-wireless-disconnected"
    else
        nmcli radio wifi on
        notify "WLAN aktiviert" "Suche nach Drahtlosnetzwerken..." "network-wireless"
    fi
}

wifi_status() {
    if command -v nmcli &>/dev/null && nmcli radio wifi 2>/dev/null | grep -q "enabled"; then
        echo "true"
    else
        echo "false"
    fi
}

# ── 2. Bluetooth ───────────────────────────────────────────────
bluetooth_toggle() {
    if ! command -v bluetoothctl &>/dev/null; then
        notify "Bluetooth-Fehler" "bluetoothctl ist nicht installiert" "dialog-error"
        return 1
    fi

    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        bluetoothctl power off >/dev/null 2>&1 || true
        notify "Bluetooth deaktiviert" "Bluetooth-Adapter ausgeschaltet" "bluetooth-disabled"
    else
        bluetoothctl power on >/dev/null 2>&1 || true
        notify "Bluetooth aktiviert" "Bereit für Verbindungen" "bluetooth-active"
    fi
}

bluetooth_status() {
    if command -v bluetoothctl &>/dev/null && bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        echo "true"
    else
        echo "false"
    fi
}

# ── 3. Audioausgabe ────────────────────────────────────────────
audio_toggle() {
    if command -v pavucontrol &>/dev/null; then
        if pgrep -x pavucontrol &>/dev/null; then
            pkill -x pavucontrol 2>/dev/null || true
        else
            pavucontrol &
            notify "Audio-Mixer" "Pavucontrol geöffnet" "audio-volume-high"
        fi
    elif command -v pamixer &>/dev/null; then
        pamixer -t
        local mute_state
        mute_state="$(pamixer --get-mute 2>/dev/null || echo 'false')"
        if [[ "${mute_state}" == "true" ]]; then
            notify "Audio stummgeschaltet" "" "audio-volume-muted"
        else
            local vol
            vol="$(pamixer --get-volume 2>/dev/null || echo '100')"
            notify "Audio aktiviert" "Lautstärke: ${vol}%" "audio-volume-high"
        fi
    fi
}

audio_status() {
    if command -v pamixer &>/dev/null && [[ "$(pamixer --get-mute 2>/dev/null || echo 'false')" == "true" ]]; then
        echo "false"
    else
        echo "true"
    fi
}

# ── 4. Nachtmodus (Blaulichtfilter) ───────────────────────────
nightmode_toggle() {
    if [[ -f "${NIGHTMODE_STATE}" ]] || pgrep -x wlsunset &>/dev/null || pgrep -x gammastep &>/dev/null; then
        # Ausschalten
        rm -f "${NIGHTMODE_STATE}"
        pkill -x wlsunset 2>/dev/null || true
        pkill -x gammastep 2>/dev/null || true
        if command -v hyprshade &>/dev/null; then
            hyprshade off >/dev/null 2>&1 || true
        fi
        notify "Nachtmodus deaktiviert" "Farbtemperatur normal (6500K)" "weather-clear-night"
    else
        # Einschalten
        touch "${NIGHTMODE_STATE}"
        if command -v wlsunset &>/dev/null; then
            wlsunset -t 4000 -T 6500 &
        elif command -v gammastep &>/dev/null; then
            gammastep -O 4000 &
        elif command -v hyprshade &>/dev/null; then
            hyprshade on blue-light-filter >/dev/null 2>&1 || true
        fi
        notify "Nachtmodus aktiviert" "Warme Farbtemperatur (4000K)" "weather-clear-night"
    fi
}

nightmode_status() {
    if [[ -f "${NIGHTMODE_STATE}" ]] || pgrep -x wlsunset &>/dev/null || pgrep -x gammastep &>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# ── 5. Theme / Tokyo Night Einstellungen ──────────────────────
theme_toggle() {
    local settings_script="${HOME}/.config/hypr/scripts/settings.sh"
    if [[ -x "${settings_script}" ]]; then
        "${settings_script}" &
    elif command -v rofi &>/dev/null; then
        "${HOME}/.config/hypr/scripts/wallpaper.sh" &
    fi
}

# ── 6. Energiesparmodus ───────────────────────────────────────
powersave_toggle() {
    if [[ -f "${POWERSAVE_STATE}" ]]; then
        # Ausschalten – Effekte & Performance wiederherstellen
        rm -f "${POWERSAVE_STATE}"
        if command -v hyprctl &>/dev/null; then
            hyprctl keyword decoration:blur:enabled true >/dev/null 2>&1 || true
            hyprctl keyword decoration:drop_shadow true >/dev/null 2>&1 || true
            hyprctl keyword animations:enabled true >/dev/null 2>&1 || true
        fi
        if command -v powerprofilesctl &>/dev/null; then
            powerprofilesctl set balanced >/dev/null 2>&1 || true
        fi
        notify "Energiesparmodus aus" "Animationen, Blur und Schatten wieder aktiv" "battery-full"
    else
        # Einschalten – Blur, Schatten & Animationen pausieren
        touch "${POWERSAVE_STATE}"
        if command -v hyprctl &>/dev/null; then
            hyprctl keyword decoration:blur:enabled false >/dev/null 2>&1 || true
            hyprctl keyword decoration:drop_shadow false >/dev/null 2>&1 || true
            hyprctl keyword animations:enabled false >/dev/null 2>&1 || true
        fi
        if command -v powerprofilesctl &>/dev/null; then
            powerprofilesctl set power-saver >/dev/null 2>&1 || true
        fi
        notify "Energiesparmodus an" "Blur & Animationen für maximale Akkulaufzeit pausiert" "battery-caution"
    fi
}

powersave_status() {
    if [[ -f "${POWERSAVE_STATE}" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# ── 7. SwayNC Panel umschalten ────────────────────────────────
toggle_panel() {
    if ! pgrep -x swaync &>/dev/null; then
        pkill -x mako 2>/dev/null || true
        swaync &
        sleep 0.3
    fi
    if command -v swaync-client &>/dev/null; then
        swaync-client -t -sw
    fi
}

# ── Argument-Parser ───────────────────────────────────────────
case "${1:-}" in
    --wifi-toggle)        wifi_toggle ;;
    --wifi-status)        wifi_status ;;
    --bluetooth-toggle)   bluetooth_toggle ;;
    --bluetooth-status)   bluetooth_status ;;
    --audio-toggle)       audio_toggle ;;
    --audio-status)       audio_status ;;
    --nightmode-toggle)   nightmode_toggle ;;
    --nightmode-status)   nightmode_status ;;
    --theme-toggle)       theme_toggle ;;
    --powersave-toggle)   powersave_toggle ;;
    --powersave-status)   powersave_status ;;
    --toggle|toggle)      toggle_panel ;;
    *)
        echo "Verwendung: $0 {--wifi-toggle|--wifi-status|--bluetooth-toggle|--bluetooth-status|--audio-toggle|--nightmode-toggle|--nightmode-status|--theme-toggle|--powersave-toggle|--powersave-status|--toggle}"
        exit 1
        ;;
esac
