-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Eingabegeräte – Tastatur, Maus, Touchpad                  ║
-- ╚══════════════════════════════════════════════════════════════╝

hl.config({
    input = {
        -- Tastaturlayout: Deutsch
        kb_layout  = "de",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        -- Fokus folgt der Maus
        follow_mouse = 1,

        -- Mausempfindlichkeit (0 = keine Beschleunigung)
        sensitivity = 0,

        -- Wiederholungsrate
        repeat_rate  = 25,
        repeat_delay = 600,

        -- Touchpad-Einstellungen
        touchpad = {
            natural_scroll    = true,
            disable_while_typing = true,
            tap_to_click      = true,
            drag_lock         = false,
            scroll_factor     = 1.0,
        },
    },

    -- Cursor-Einstellungen
    cursor = {
        no_hardware_cursors = false,
        inactive_timeout    = 5,
    },
})

-- ── Gesten (neues API ab Hyprland 0.55+) ──────────────────
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- ── Umgebungsvariablen für Cursor ────────────────────────────
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
