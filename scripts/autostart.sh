#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Autostart – Initialisiert alle Hintergrunddienste            ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

WP_DIR="${HOME}/.config/hypr/wallpapers"
CURRENT_WP="${WP_DIR}/current.jpg"

# ── 1. Wallpaper sicherstellen ────────────────────────────────
mkdir -p "${WP_DIR}"
if [[ ! -f "${CURRENT_WP}" || ! -s "${CURRENT_WP}" ]]; then
    # Suche erstes verfügbares Hintergrundbild
    first_wp="$(find "${WP_DIR}" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) ! -name 'current.jpg' 2>/dev/null | head -n 1 || true)"
    if [[ -n "${first_wp}" && -f "${first_wp}" ]]; then
        cp -f "${first_wp}" "${CURRENT_WP}"
    elif command -v convert &>/dev/null; then
        convert -size 1920x1080 xc:'#1a1b26' "${CURRENT_WP}" 2>/dev/null || true
    fi
fi

# ── 2. XDG Desktop Portal & Umgebungsvariablen ───────────────
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true

# Cursor-Theme
hyprctl setcursor Adwaita 24 2>/dev/null || true

# ── 3. Polkit Authentifizierungs-Agent ────────────────────────
if ! pgrep -f hyprpolkitagent &>/dev/null; then
    hyprpolkitagent &
fi

# ── 4. Hintergrundbild (hyprpaper) ───────────────────────────
pkill -x hyprpaper 2>/dev/null || true
sleep 0.1
if [[ -f "${CURRENT_WP}" ]]; then
    hyprpaper &
fi

# ── 5. Statusleiste (waybar) ──────────────────────────────────
pkill -x waybar 2>/dev/null || true
mkdir -p "${HOME}/.cache"
waybar > "${HOME}/.cache/waybar.log" 2>&1 &

# ── 6. Benachrichtigungs-Daemon (mako) ────────────────────────
pkill -x mako 2>/dev/null || true
sleep 0.1
mako &

# ── 7. Zwischenablage-Verlauf (cliphist) ──────────────────────
pkill -f "wl-paste.*cliphist" 2>/dev/null || true
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
