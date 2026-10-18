#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Autostart – Initialisiert alle Hintergrunddienste            ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── 1. Wayland & Hyprland Umgebung ermitteln (SSH / TTY Support) ──
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    wp_sock="$(find "${XDG_RUNTIME_DIR}" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' 2>/dev/null | head -n 1 || true)"
    if [[ -n "${wp_sock}" ]]; then
        export WAYLAND_DISPLAY="$(basename "${wp_sock}")"
        echo "[INFO] WAYLAND_DISPLAY gesetzt auf: ${WAYLAND_DISPLAY}"
    else
        echo "[WARNUNG] Kein aktiver Wayland-Socket gefunden! Läuft Hyprland?"
    fi
fi

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    sig="$(ls -1 "${XDG_RUNTIME_DIR}/hypr" 2>/dev/null | grep -v '\.lock' | head -n 1 || true)"
    if [[ -n "${sig}" ]]; then
        export HYPRLAND_INSTANCE_SIGNATURE="${sig}"
        echo "[INFO] HYPRLAND_INSTANCE_SIGNATURE gesetzt auf: ${HYPRLAND_INSTANCE_SIGNATURE}"
    fi
fi

WP_DIR="${HOME}/.config/hypr/wallpapers"
CURRENT_WP="${WP_DIR}/current.jpg"
# Repo-Verzeichnis dynamisch ermitteln
REPO_DIR=""
for candidate in "${HOME}/tokyo-hypr-dots" "${HOME}/arch-hyprland" "${HOME}/arch-hyrland" "${HOME}/hyprland" "$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"; do
    if [[ -d "${candidate}/config/swaync" ]]; then
        REPO_DIR="${candidate}"
        break
    fi
done

# ── 2. Konfigurationen automatisch synchronisieren ────────────
if [[ -n "${REPO_DIR}" && -d "${REPO_DIR}" ]]; then
    mkdir -p "${HOME}/.config/waybar" "${HOME}/.config/hypr" "${HOME}/.config/rofi" "${WP_DIR}" "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0" "${HOME}/.config/hypr/settings" "${HOME}/.config/swaync" "${HOME}/.config/hypr/scripts"
    [[ -d "${REPO_DIR}/config/waybar" ]] && cp -f "${REPO_DIR}/config/waybar/"* "${HOME}/.config/waybar/" 2>/dev/null || true
    [[ -d "${REPO_DIR}/config/swaync" ]] && cp -f "${REPO_DIR}/config/swaync/"* "${HOME}/.config/swaync/" 2>/dev/null || true
    [[ -d "${REPO_DIR}/config/hypr" ]] && cp -f "${REPO_DIR}/config/hypr/"*.lua "${HOME}/.config/hypr/" 2>/dev/null || true
    [[ -f "${REPO_DIR}/config/hyprpaper/hyprpaper.conf" ]] && cp -f "${REPO_DIR}/config/hyprpaper/hyprpaper.conf" "${HOME}/.config/hypr/hyprpaper.conf" 2>/dev/null || true
    [[ -d "${REPO_DIR}/config/rofi" ]] && cp -f "${REPO_DIR}/config/rofi/"* "${HOME}/.config/rofi/" 2>/dev/null || true
    [[ -d "${REPO_DIR}/config/gtk-3.0" ]] && cp -f "${REPO_DIR}/config/gtk-3.0/"* "${HOME}/.config/gtk-3.0/" 2>/dev/null || true
    [[ -d "${REPO_DIR}/config/gtk-4.0" ]] && cp -f "${REPO_DIR}/config/gtk-4.0/"* "${HOME}/.config/gtk-4.0/" 2>/dev/null || true
    [[ -d "${REPO_DIR}/settings" ]] && cp -f "${REPO_DIR}/settings/"*.py "${HOME}/.config/hypr/settings/" 2>/dev/null || true
    [[ -d "${REPO_DIR}/scripts" ]] && cp -f "${REPO_DIR}/scripts/"* "${HOME}/.config/hypr/scripts/" 2>/dev/null || true
    chmod +x "${HOME}/.config/hypr/scripts/"* 2>/dev/null || true
    if [[ -d "${REPO_DIR}/screenshot" ]]; then
        mkdir -p "${HOME}/.config/hypr/screenshot"
        cp -f "${REPO_DIR}/screenshot/"*.py "${HOME}/.config/hypr/screenshot/" 2>/dev/null || true
        chmod +x "${HOME}/.config/hypr/screenshot/"*.py 2>/dev/null || true
    fi
    mkdir -p "${HOME}/.local/bin"
    ln -sf "${HOME}/.config/hypr/scripts/tokyo-shot" "${HOME}/.local/bin/tokyo-shot" 2>/dev/null || true
    if [[ -d "${REPO_DIR}/assets/desktop" ]]; then
        mkdir -p "${HOME}/.local/share/applications"
        cp -f "${REPO_DIR}/assets/desktop/"*.desktop "${HOME}/.local/share/applications/" 2>/dev/null || true
        if command -v update-desktop-database &>/dev/null; then
            update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
        fi
    fi
    [[ -d "${REPO_DIR}/assets/wallpapers" ]] && cp -n "${REPO_DIR}/assets/wallpapers/"* "${WP_DIR}/" 2>/dev/null || true

    # Desktop-PC Schutz: Falls kein Backlight vorhanden ist, Widget entfernen um SwayNC-Absturz zu verhindern
    if [[ ! -d /sys/class/backlight || -z "$(ls -A /sys/class/backlight 2>/dev/null)" ]]; then
        if command -v jq &>/dev/null && [[ -f "${HOME}/.config/swaync/config.json" ]]; then
            jq '.widgets |= map(select(. != "backlight"))' "${HOME}/.config/swaync/config.json" > "${HOME}/.config/swaync/config.json.tmp" 2>/dev/null && mv "${HOME}/.config/swaync/config.json.tmp" "${HOME}/.config/swaync/config.json" 2>/dev/null || true
        fi
    fi
fi

# ── 3. Wallpaper-Datei sicherstellen ──────────────────────────
mkdir -p "${WP_DIR}"
if [[ ! -f "${CURRENT_WP}" || ! -s "${CURRENT_WP}" ]]; then
    first_wp="$(find "${WP_DIR}" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) ! -name 'current.jpg' 2>/dev/null | head -n 1 || true)"
    if [[ -n "${first_wp}" && -f "${first_wp}" ]]; then
        cp -f "${first_wp}" "${CURRENT_WP}"
    elif command -v convert &>/dev/null; then
        convert -size 1920x1080 xc:'#1a1b26' "${CURRENT_WP}" 2>/dev/null || true
    fi
fi

# ── 4. XDG Desktop Portal & Umgebungsvariablen ───────────────
export PATH="${HOME}/.local/bin:${HOME}/.config/hypr/scripts:${PATH}"
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP PATH 2>/dev/null || true
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP PATH 2>/dev/null || true

# GTK Dunkles Tokyo Night Design systemweit setzen
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
fi

# Cursor-Theme
if command -v hyprctl &>/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl setcursor Adwaita 24 >/dev/null 2>&1 || true
fi

# ── 5. Polkit Authentifizierungs-Agent ────────────────────────
if ! pgrep -f "polkit" &>/dev/null; then
    if command -v hyprpolkitagent &>/dev/null; then
        hyprpolkitagent &
    elif [[ -x /usr/lib/hyprpolkitagent/hyprpolkitagent ]]; then
        /usr/lib/hyprpolkitagent/hyprpolkitagent &
    elif [[ -x /usr/lib/hyprpolkitagent && ! -d /usr/lib/hyprpolkitagent ]]; then
        /usr/lib/hyprpolkitagent &
    elif [[ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]]; then
        /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
    fi
fi

# ── 6. Hintergrundbild (hyprpaper) ───────────────────────────
pkill -x hyprpaper 2>/dev/null || true
sleep 0.1
if [[ -f "${CURRENT_WP}" ]] && command -v hyprpaper &>/dev/null; then
    hyprpaper &
    sleep 0.5
    # Wallpaper explizit per IPC zuweisen
    if command -v hyprctl &>/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        hyprctl hyprpaper preload "${CURRENT_WP}" >/dev/null 2>&1 || true
        hyprctl hyprpaper wallpaper ",${CURRENT_WP}" >/dev/null 2>&1 || true
        hyprctl hyprpaper wallpaper "eDP-1,${CURRENT_WP}" >/dev/null 2>&1 || true
    fi
    echo "[INFO] Hyprpaper gestartet"
fi

# ── 7. Benachrichtigungs-Daemon & Kontrollzentrum (swaync / mako) ──
if command -v swaync &>/dev/null; then
    # Alle konkurrierenden Notification-Daemons hart beenden
    pkill -9 -x mako 2>/dev/null || true
    pkill -9 -x dunst 2>/dev/null || true
    pkill -x swaync 2>/dev/null || true
    sleep 0.3  # Warten bis DBus-Name freigegeben wird

    # WAYLAND_DISPLAY sicherstellen (kritisch für GTK-Apps)
    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        wp_sock="$(find "${XDG_RUNTIME_DIR:-/run/user/$UID}" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' 2>/dev/null | head -n 1 || true)"
        if [[ -n "${wp_sock}" ]]; then
            export WAYLAND_DISPLAY="$(basename "${wp_sock}")"
        fi
    fi

    # SwayNC starten
    swaync > "${HOME}/.cache/swaync.log" 2>&1 &
    
    # Bis zu 3 Sekunden warten bis SwayNC bereit ist
    retry_count=0
    while ! pgrep -x swaync &>/dev/null && [[ ${retry_count} -lt 15 ]]; do
        sleep 0.2
        retry_count=$((retry_count + 1))
    done

    if pgrep -x swaync &>/dev/null; then
        echo "[INFO] SwayNC Kontrollzentrum erfolgreich gestartet!"
    else
        echo "[WARNUNG] SwayNC erster Versuch fehlgeschlagen, Retry..."
        sleep 0.5
        swaync > "${HOME}/.cache/swaync.log" 2>&1 &
        sleep 0.8
        if pgrep -x swaync &>/dev/null; then
            echo "[INFO] SwayNC Kontrollzentrum gestartet (Retry erfolgreich)!"
        else
            echo "[FEHLER] SwayNC konnte nicht gestartet werden. Fehler-Log:"
            tail -n 20 "${HOME}/.cache/swaync.log" 2>/dev/null || true
        fi
    fi
elif command -v mako &>/dev/null; then
    pkill -x mako 2>/dev/null || true
    sleep 0.1
    mako &
    echo "[INFO] Mako Benachrichtigungen gestartet"
fi

# ── 8. Statusleiste (waybar) ──────────────────────────────────
pkill -x waybar 2>/dev/null || true
sleep 0.2
mkdir -p "${HOME}/.cache"

if command -v waybar &>/dev/null; then
    waybar > "${HOME}/.cache/waybar.log" 2>&1 &
    sleep 0.6
    if pgrep -x waybar &>/dev/null; then
        echo "[INFO] Waybar erfolgreich gestartet!"
    else
        echo "[FEHLER] Waybar konnte nicht gestartet werden. Fehler-Log:"
        tail -n 20 "${HOME}/.cache/waybar.log" 2>/dev/null || true
    fi
else
    echo "[FEHLER] Waybar ist nicht installiert! (sudo pacman -S waybar)"
fi

# ── 9. Zwischenablage-Verlauf (cliphist) ──────────────────────
if command -v cliphist &>/dev/null && command -v wl-paste &>/dev/null; then
    pkill -f "wl-paste.*cliphist" 2>/dev/null || true
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
fi
