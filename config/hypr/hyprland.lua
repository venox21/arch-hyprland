-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Hyprland – Hauptkonfiguration                              ║
-- ║  Tokyo Night Desktop                                        ║
-- ║  Verwendet native Lua-API (≥ 0.55)                          ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Zentrale Farbpalette laden
local colors = require("colors")

-- ══════════════════════════════════════════════════════════════
-- ██ Look and Feel
-- ══════════════════════════════════════════════════════════════

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,

        col = {
            active_border   = colors.border_gradient,
            inactive_border = colors.border_inactive,
        },

        resize_on_border  = true,
        allow_tearing     = false,
        layout            = "dwindle",
    },

    decoration = {
        rounding       = 8,
        rounding_power = 2.0,

        active_opacity   = colors.opacity_active,
        inactive_opacity = colors.opacity_inactive,

        dim_inactive       = true,
        dim_strength       = colors.dim_inactive,

        shadow = {
            enabled      = true,
            range        = 8,
            render_power = 2,
            color        = colors.shadow,
            offset       = { 0, 2 },
        },

        blur = {
            enabled        = true,
            size           = 4,
            passes         = 2,
            noise          = 0.02,
            contrast       = 0.9,
            brightness     = 0.8,
            vibrancy       = 0.15,
            vibrancy_darkness = 0.0,
            new_optimizations = true,
            xray           = false,
            ignore_opacity = false,
        },
    },

    -- ── Dwindle-Layout ───────────────────────────────────────
    dwindle = {
        preserve_split = true,
        force_split    = 2,       -- Immer rechts/unten splitten
        smart_split    = false,
        smart_resizing = true,
    },

    -- ── Master-Layout (Fallback) ─────────────────────────────
    master = {
        new_status = "master",
    },

    -- ── Verschiedenes ────────────────────────────────────────
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
        vrr                      = 0,
        focus_on_activate        = true,
        on_focus_under_fullscreen = 2,
    },

    -- ── XWayland ─────────────────────────────────────────────
    xwayland = {
        force_zero_scaling = true,
    },
})

-- ══════════════════════════════════════════════════════════════
-- ██ Module laden
-- ══════════════════════════════════════════════════════════════

require("input")        -- Eingabegeräte, Tastaturlayout
require("monitors")     -- Monitorkonfiguration
require("animations")   -- Animationen und Kurven
require("rules")        -- Fensterregeln
require("keybinds")     -- Tastenkürzel
require("autostart")    -- Autostart-Programme

-- Optionale benutzereigene Konfiguration (~/.config/hypr/user.lua – wird bei Updates nie überschrieben)
pcall(require, "user")
