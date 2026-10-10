-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Autostart – Dienste und Programme beim Start               ║
-- ╚══════════════════════════════════════════════════════════════╝

local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"

-- ── Einmalig beim Hyprland-Start ─────────────────────────────
hl.on("hyprland.start", function()
    hl.exec_cmd(scripts .. "/autostart.sh")
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
