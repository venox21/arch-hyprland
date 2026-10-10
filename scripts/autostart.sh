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

# ── 2. Wallpaper-Datei sicherstellen ──────────────────────────
mkdir -p "${WP_DIR}"
if [[ ! -f "${CURRENT_WP}" || ! -s "${CURRENT_WP}" ]]; then
    first_wp="$(find "${WP_DIR}" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) ! -name 'current.jpg' 2>/dev/null | head -n 1 || true)"
    if [[ -n "${first_wp}" && -f "${first_wp}" ]]; then
        cp -f "${first_wp}" "${CURRENT_WP}"
    elif command -v convert &>/dev/null; then
        convert -size 1920x1080 xc:'#1a1b26' "${CURRENT_WP}" 2>/dev/null || true
    fi
fi

# ── 3. XDG Desktop Portal & Umgebungsvariablen ───────────────
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true

# Cursor-Theme
if command -v hyprctl &>/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl setcursor Adwaita 24 2>/dev/null || true
fi

# ── 4. Polkit Authentifizierungs-Agent ────────────────────────
if ! pgrep -f "polkit" &>/dev/null; then
    if command -v hyprpolkitagent &>/dev/null; then
        hyprpolkitagent &
    elif [[ -x /usr/lib/hyprpolkitagent ]]; then
        /usr/lib/hyprpolkitagent &
    elif [[ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]]; then
        /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
    fi
fi

# ── 5. Hintergrundbild (hyprpaper) ───────────────────────────
pkill -x hyprpaper 2>/dev/null || true
sleep 0.1
if [[ -f "${CURRENT_WP}" ]] && command -v hyprpaper &>/dev/null; then
    hyprpaper &
    sleep 0.3
    # Wallpaper explizit per IPC zuweisen
    if command -v hyprctl &>/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        hyprctl hyprpaper preload "${CURRENT_WP}" 2>/dev/null || true
        hyprctl hyprpaper wallpaper ",${CURRENT_WP}" 2>/dev/null || true
        hyprctl hyprpaper wallpaper "eDP-1,${CURRENT_WP}" 2>/dev/null || true
    fi
    echo "[INFO] Hyprpaper gestartet"
fi

# ── 6. Statusleiste (waybar) ──────────────────────────────────
pkill -x waybar 2>/dev/null || true
sleep 0.2
mkdir -p "${HOME}/.cache"

if command -v waybar &>/dev/null; then
    waybar > "${HOME}/.cache/waybar.log" 2>&1 &
    sleep 0.5
    if pgrep -x waybar &>/dev/null; then
        echo "[INFO] Waybar erfolgreich gestartet!"
    else
        echo "[FEHLER] Waybar konnte nicht gestartet werden. Fehler-Log:"
        tail -n 20 "${HOME}/.cache/waybar.log" 2>/dev/null || true
    fi
else
    echo "[FEHLER] Waybar ist nicht installiert! (sudo pacman -S waybar)"
fi

# ── 7. Benachrichtigungs-Daemon (mako) ────────────────────────
if command -v mako &>/dev/null; then
    pkill -x mako 2>/dev/null || true
    sleep 0.1
    mako &
fi

# ── 8. Zwischenablage-Verlauf (cliphist) ──────────────────────
if command -v cliphist &>/dev/null && command -v wl-paste &>/dev/null; then
    pkill -f "wl-paste.*cliphist" 2>/dev/null || true
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
fi
