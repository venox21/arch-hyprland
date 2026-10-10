-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Autostart – Dienste und Programme beim Start               ║
-- ╚══════════════════════════════════════════════════════════════╝

local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"

-- ── Einmalig beim Hyprland-Start ─────────────────────────────
hl.on("hyprland.start", function()
    -- Polkit-Agent für grafische Authentifizierung
    hl.exec_cmd("hyprpolkitagent &")

    -- Hintergrundbild
    hl.exec_cmd("hyprpaper &")

    -- Statusleiste (mit Kill-Guard gegen Duplikate)
    hl.exec_cmd("pkill waybar; sleep 0.3 && waybar &")

    -- Benachrichtigungsdienst (mit Kill-Guard)
    hl.exec_cmd("pkill mako; sleep 0.1 && mako &")

    -- Zwischenablage-Daemon
    hl.exec_cmd("wl-paste --type text --watch cliphist store &")
    hl.exec_cmd("wl-paste --type image --watch cliphist store &")

    -- XDG Desktop Portal
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &")

    -- Cursor-Theme setzen
    hl.exec_cmd("hyprctl setcursor Adwaita 24")

    -- NetworkManager Applet (optional)
    -- hl.exec_cmd("nm-applet --indicator &")

    -- Fastfetch beim ersten Terminal (deaktiviert – wird in .zshrc gesteuert)
end)

-- ── Umgebungsvariablen ───────────────────────────────────────
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- GTK-Theme (falls installiert)
hl.env("GTK_THEME", "Adwaita:dark")

-- Qt-Wayland-Unterstützung
hl.env("QT_QPA_PLATFORM",       "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME",  "qt5ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- Electron/Chromium Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Mozilla Wayland
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- SDL Wayland
hl.env("SDL_VIDEODRIVER", "wayland")

-- Clutter Wayland
hl.env("CLUTTER_BACKEND", "wayland")

-- Java AWT Wayland Fix
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
