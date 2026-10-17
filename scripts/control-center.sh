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

wifi_menu() {
    if ! command -v nmcli &>/dev/null; then
        notify "WLAN-Fehler" "NetworkManager (nmcli) ist nicht installiert" "dialog-error"
        return 1
    fi

    # WLAN einschalten falls ausgeschaltet
    local current_state
    current_state="$(nmcli radio wifi 2>/dev/null || echo 'disabled')"
    if [[ ! "${current_state}" =~ enabled ]]; then
        nmcli radio wifi on
        notify "WLAN aktiviert" "Suche nach Drahtlosnetzwerken..." "network-wireless"
        sleep 1.2
    fi

    # SwayNC schließen, damit der Verbindungs-Dialog fokussiert ist
    if command -v swaync-client &>/dev/null; then
        swaync-client -cp 2>/dev/null || true
    fi

    if command -v rofi &>/dev/null; then
        local current_ssid
        current_ssid="$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || true)"

        # Netzwerke ermitteln
        local raw_list
        raw_list="$(nmcli -t -f "IN-USE,SSID,SIGNAL,SECURITY" device wifi list --rescan auto 2>/dev/null || true)"

        local menu_entries=""
        local seen_ssids=";"

        # Falls aktuell verbunden, an oberster Stelle anzeigen
        if [[ -n "${current_ssid}" ]]; then
            menu_entries="󰤨  ${current_ssid} (Verbunden)\n"
            seen_ssids="${seen_ssids}${current_ssid};"
        fi

        while IFS=':' read -r in_use ssid signal security; do
            [[ -z "${ssid}" ]] && continue
            if [[ "${seen_ssids}" =~ ";${ssid};" ]]; then
                continue
            fi
            seen_ssids="${seen_ssids}${ssid};"

            local sec_label="${security:-Offen}"
            [[ "${sec_label}" == "--" ]] && sec_label="Offen"
            menu_entries+="${ssid} (${signal}%, ${sec_label})\n"
        done <<< "${raw_list}"

        menu_entries+="󰖪  WLAN ausschalten\n"
        menu_entries+="󰑐  Netzwerke neu scannen\n"
        menu_entries+="⚙  Netzwerk-Einstellungen (nm-connection-editor)"

        local rofi_theme="${HOME}/.config/rofi/config.rasi"
        local rofi_cmd=(rofi -dmenu -i -p "WLAN" -theme-str 'window { width: 420px; }' -theme-str 'listview { lines: 10; }')
        if [[ -f "${rofi_theme}" ]]; then
            rofi_cmd+=(-theme "${rofi_theme}")
        fi

        local chosen
        chosen="$(echo -e "${menu_entries}" | "${rofi_cmd[@]}" 2>/dev/null || true)"
        [[ -z "${chosen}" ]] && return 0

        case "${chosen}" in
            "󰖪  WLAN ausschalten")
                nmcli radio wifi off
                notify "WLAN deaktiviert" "Drahtlosverbindung ausgeschaltet" "network-wireless-disconnected"
                return 0
                ;;
            "󰑐  Netzwerke neu scannen")
                nmcli device wifi rescan 2>/dev/null || true
                sleep 0.8
                wifi_menu
                return 0
                ;;
            "⚙  Netzwerk-Einstellungen (nm-connection-editor)")
                if command -v nm-connection-editor &>/dev/null; then
                    nm-connection-editor &
                elif command -v kitty &>/dev/null && command -v nmtui &>/dev/null; then
                    kitty --class floating_kitty -e nmtui &
                fi
                return 0
                ;;
        esac

        local selected_ssid
        if [[ "${chosen}" =~ ^󰤨[[:space:]]+(.*)[[:space:]]+\(Verbunden\)$ ]]; then
            selected_ssid="${BASH_REMATCH[1]}"
            local disconnect_opt
            disconnect_opt="$(echo -e "Verbindung trennen\nAbbrechen" | rofi -dmenu -i -p "${selected_ssid}" -theme-str 'window { width: 260px; }' -theme-str 'listview { lines: 2; }' -theme "${rofi_theme}" 2>/dev/null || true)"
            if [[ "${disconnect_opt}" == "Verbindung trennen" ]]; then
                nmcli connection down id "${selected_ssid}" 2>/dev/null || nmcli device disconnect "$(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | grep ':wifi$' | head -n1 | cut -d: -f1)" 2>/dev/null || true
                notify "WLAN getrennt" "Verbindung zu ${selected_ssid} getrennt" "network-wireless-disconnected"
            fi
            return 0
        else
            selected_ssid="$(echo "${chosen}" | sed -E 's/[[:space:]]*\([0-9]+%,?[^)]*\)[[:space:]]*$//')"
        fi

        [[ -z "${selected_ssid}" ]] && return 0

        notify "Verbinde..." "Verbindungsaufbau zu ${selected_ssid}..." "network-wireless"

        # Prüfen ob ein Verbindungsprofil existiert
        if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq "${selected_ssid}"; then
            if nmcli connection up id "${selected_ssid}" 2>/dev/null; then
                notify "WLAN verbunden" "Erfolgreich mit ${selected_ssid} verbunden" "network-wireless"
            else
                notify "WLAN-Fehler" "Verbindung mit ${selected_ssid} fehlgeschlagen" "dialog-error"
            fi
        else
            local is_secured
            is_secured="$(nmcli -t -f SSID,SECURITY dev wifi list 2>/dev/null | grep "^${selected_ssid}:" | head -n 1 | cut -d: -f2 || true)"
            if [[ -n "${is_secured}" && "${is_secured}" != "--" ]]; then
                local pass
                pass="$(rofi -dmenu -password -p "Passwort für ${selected_ssid}" -theme-str 'window { width: 340px; }' -theme-str 'listview { lines: 0; }' -theme "${rofi_theme}" 2>/dev/null || true)"
                if [[ -z "${pass}" ]]; then
                    notify "Abgebrochen" "Keine Verbindung hergestellt" "dialog-information"
                    return 0
                fi
                if nmcli device wifi connect "${selected_ssid}" password "${pass}" 2>/dev/null; then
                    notify "WLAN verbunden" "Erfolgreich mit ${selected_ssid} verbunden" "network-wireless"
                else
                    notify "WLAN-Fehler" "Passwort falsch oder Verbindung fehlgeschlagen" "dialog-error"
                fi
            else
                if nmcli device wifi connect "${selected_ssid}" 2>/dev/null; then
                    notify "WLAN verbunden" "Erfolgreich mit ${selected_ssid} verbunden" "network-wireless"
                else
                    notify "WLAN-Fehler" "Verbindung mit ${selected_ssid} fehlgeschlagen" "dialog-error"
                fi
            fi
        fi
    elif command -v nm-connection-editor &>/dev/null; then
        nm-connection-editor &
    elif command -v kitty &>/dev/null && command -v nmtui &>/dev/null; then
        kitty --class floating_kitty -e nmtui &
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

    # Bluetooth-Dienst sicherstellen
    if command -v systemctl &>/dev/null && ! systemctl is-active --quiet bluetooth 2>/dev/null; then
        systemctl start bluetooth 2>/dev/null || sudo -n systemctl start bluetooth 2>/dev/null || true
        if ! systemctl is-active --quiet bluetooth 2>/dev/null; then
            notify "Bluetooth-Dienst inaktiv" "Bitte 'sudo systemctl enable --now bluetooth' ausführen" "dialog-warning"
            return 1
        fi
    fi

    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        bluetoothctl power off >/dev/null 2>&1 || true
        notify "Bluetooth deaktiviert" "Bluetooth-Adapter ausgeschaltet" "bluetooth-disabled"
    else
        bluetoothctl power on >/dev/null 2>&1 || true
        notify "Bluetooth aktiviert" "Bereit für Verbindungen" "bluetooth-active"
    fi
}

bluetooth_menu() {
    if ! command -v bluetoothctl &>/dev/null; then
        notify "Bluetooth-Fehler" "bluetoothctl ist nicht installiert" "dialog-error"
        return 1
    fi

    # Bluetooth-Dienst sicherstellen
    if command -v systemctl &>/dev/null && ! systemctl is-active --quiet bluetooth 2>/dev/null; then
        systemctl start bluetooth 2>/dev/null || sudo -n systemctl start bluetooth 2>/dev/null || true
        if ! systemctl is-active --quiet bluetooth 2>/dev/null; then
            notify "Bluetooth-Dienst inaktiv" "Bitte 'sudo systemctl enable --now bluetooth' ausführen" "dialog-warning"
            return 1
        fi
    fi

    # Bluetooth aktivieren falls Adapter aus
    if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        bluetoothctl power on >/dev/null 2>&1 || true
        notify "Bluetooth aktiviert" "Bereit für Verbindungen" "bluetooth-active"
        sleep 0.8
    fi

    # SwayNC schließen
    if command -v swaync-client &>/dev/null; then
        swaync-client -cp 2>/dev/null || true
    fi

    # Wenn Blueman Manager installiert ist: Standard GTK-Manager öffnen
    if command -v blueman-manager &>/dev/null; then
        blueman-manager &
        return 0
    fi

    # Rofi Bluetooth Menü als leichtgewichtiger Fallback
    if command -v rofi &>/dev/null; then
        local rofi_theme="${HOME}/.config/rofi/config.rasi"
        local rofi_cmd=(rofi -dmenu -i -p "Bluetooth" -theme-str 'window { width: 420px; }' -theme-str 'listview { lines: 8; }')
        if [[ -f "${rofi_theme}" ]]; then
            rofi_cmd+=(-theme "${rofi_theme}")
        fi

        local paired_devices
        paired_devices="$(bluetoothctl devices Paired 2>/dev/null || true)"

        local menu_entries=""
        while read -r _ mac name; do
            [[ -z "${mac:-}" ]] && continue
            local dev_info
            dev_info="$(bluetoothctl info "${mac}" 2>/dev/null || true)"
            if echo "${dev_info}" | grep -q "Connected: yes"; then
                menu_entries+="󰂱  ${name} [${mac}] (Verbunden)\n"
            else
                menu_entries+="󰂯  ${name} [${mac}] (Getrennt)\n"
            fi
        done <<< "${paired_devices}"

        menu_entries+="󰂲  Bluetooth ausschalten\n"
        menu_entries+="󰑐  Nach neuen Geräten scannen (bluetoothctl)"

        local chosen
        chosen="$(echo -e "${menu_entries}" | "${rofi_cmd[@]}" 2>/dev/null || true)"
        [[ -z "${chosen}" ]] && return 0

        case "${chosen}" in
            "󰂲  Bluetooth ausschalten")
                bluetoothctl power off >/dev/null 2>&1 || true
                notify "Bluetooth deaktiviert" "Bluetooth-Adapter ausgeschaltet" "bluetooth-disabled"
                return 0
                ;;
            "󰑐  Nach neuen Geräten scannen (bluetoothctl)")
                if command -v kitty &>/dev/null; then
                    kitty --class floating_kitty -e bash -c "echo -e '\033[1;34mStarte Bluetooth-Scan...\033[0m Drücke Strg+C zum Beenden.'; bluetoothctl scan on" &
                else
                    notify "Bluetooth-Scan" "Tipp: Installiere 'blueman' für eine komfortable grafische Bluetooth-Verwaltung" "dialog-information"
                fi
                return 0
                ;;
        esac

        local target_mac
        target_mac="$(echo "${chosen}" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' || true)"
        [[ -z "${target_mac}" ]] && return 0

        local dev_name
        dev_name="$(echo "${chosen}" | sed -E 's/^[^ ]+[[:space:]]+//; s/[[:space:]]*\[.*//')"

        if [[ "${chosen}" =~ \(Verbunden\) ]]; then
            bluetoothctl disconnect "${target_mac}" >/dev/null 2>&1 || true
            notify "Bluetooth getrennt" "${dev_name} wurde getrennt" "bluetooth-disabled"
        else
            notify "Bluetooth" "Verbinde mit ${dev_name}..." "bluetooth-active"
            if bluetoothctl connect "${target_mac}" >/dev/null 2>&1; then
                notify "Bluetooth verbunden" "Erfolgreich mit ${dev_name} verbunden" "bluetooth-active"
            else
                notify "Bluetooth-Fehler" "Verbindung mit ${dev_name} fehlgeschlagen" "dialog-error"
            fi
        fi
    elif command -v kitty &>/dev/null; then
        kitty --class floating_kitty -e bluetoothctl &
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

# ── 7. GameMode / Performance-Toggle ─────────────────────────
gamemode_toggle() {
    local gm_script="${HOME}/.config/hypr/scripts/gamemode.sh"
    if [[ ! -f "${gm_script}" ]]; then
        gm_script="$(dirname "${BASH_SOURCE[0]}")/gamemode.sh"
    fi
    if [[ -f "${gm_script}" ]]; then
        bash "${gm_script}" --toggle
    fi
}

gamemode_status() {
    local gm_script="${HOME}/.config/hypr/scripts/gamemode.sh"
    if [[ ! -f "${gm_script}" ]]; then
        gm_script="$(dirname "${BASH_SOURCE[0]}")/gamemode.sh"
    fi
    if [[ -f "${gm_script}" ]]; then
        bash "${gm_script}" --status
    else
        echo "false"
    fi
}

# ── 8. System-Cleaner ─────────────────────────────────────────
cleaner_launch() {
    # SwayNC schließen, damit das Terminal sichtbar ist
    if command -v swaync-client &>/dev/null; then
        swaync-client -cp 2>/dev/null || true
    fi

    local clean_script="${HOME}/.config/hypr/scripts/clean-system.sh"
    if [[ ! -f "${clean_script}" ]]; then
        clean_script="$(dirname "${BASH_SOURCE[0]}")/clean-system.sh"
    fi

    if command -v kitty &>/dev/null; then
        kitty --class tokyo-system-cleaner --title "System-Cleaner" -e bash -c "bash '${clean_script}'; echo ''; read -r -p 'Drücke Enter zum Schließen...' _dummy" &
    else
        bash "${clean_script}" &
    fi
}

# ── 9. SwayNC Panel umschalten ────────────────────────────────
toggle_panel() {
    # Falls SwayNC noch nicht läuft, zuverlässig initialisieren & starten
    if ! pgrep -x swaync &>/dev/null; then
        pkill -9 -x mako 2>/dev/null || true
        pkill -9 -x dunst 2>/dev/null || true

        if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
            local wp_sock
            wp_sock="$(find "${XDG_RUNTIME_DIR:-/run/user/$UID}" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' 2>/dev/null | head -n 1 || true)"
            if [[ -n "${wp_sock}" ]]; then
                export WAYLAND_DISPLAY="$(basename "${wp_sock}")"
            fi
        fi

        swaync > "${HOME}/.cache/swaync.log" 2>&1 &

        # Warten bis der SwayNC-Dienst und Socket bereit sind (bis zu 2 Sekunden)
        local count=0
        while ! swaync-client -t -sw &>/dev/null && [[ ${count} -lt 20 ]]; do
            sleep 0.1
            count=$((count + 1))
        done
        return 0
    fi

    if command -v swaync-client &>/dev/null; then
        swaync-client -t -sw
    fi
}

# ── Argument-Parser ───────────────────────────────────────────
case "${1:-}" in
    --wifi-menu|--wifi-connect)     wifi_menu ;;
    --wifi-toggle)                  wifi_toggle ;;
    --wifi-status)                  wifi_status ;;
    --bluetooth-menu|--bluetooth-connect) bluetooth_menu ;;
    --bluetooth-toggle)             bluetooth_toggle ;;
    --bluetooth-status)             bluetooth_status ;;
    --audio-toggle)                 audio_toggle ;;
    --audio-status)                 audio_status ;;
    --nightmode-toggle)             nightmode_toggle ;;
    --nightmode-status)             nightmode_status ;;
    --theme-toggle)                 theme_toggle ;;
    --powersave-toggle)             powersave_toggle ;;
    --powersave-status)             powersave_status ;;
    --gamemode-toggle)              gamemode_toggle ;;
    --gamemode-status)              gamemode_status ;;
    --cleaner|--clean-system)       cleaner_launch ;;
    --toggle|toggle)                toggle_panel ;;
    *)
        echo "Verwendung: $0 {--wifi-menu|--wifi-toggle|--wifi-status|--bluetooth-menu|--bluetooth-toggle|--bluetooth-status|--audio-toggle|--nightmode-toggle|--nightmode-status|--theme-toggle|--powersave-toggle|--powersave-status|--gamemode-toggle|--gamemode-status|--cleaner|--toggle}"
        exit 1
        ;;
esac
