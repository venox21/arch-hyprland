-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Animationen – Dezent und zurückhaltend                     ║
-- ╚══════════════════════════════════════════════════════════════╝

hl.config({
    animations = {
        enabled   = true,
        first_launch_animation = true,
    },
})

-- ── Bézier-Kurven ────────────────────────────────────────────
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("easeOutExpo",    { type = "bezier", points = { {0.16, 1},    {0.3, 1}     } })
hl.curve("easeInOutQuad",  { type = "bezier", points = { {0.45, 0},    {0.55, 1}    } })

-- Eigene Kurve für subtile Bewegungen
hl.curve("tokyoSmooth",    { type = "bezier", points = { {0.25, 0.8},  {0.25, 1}    } })
hl.curve("tokyoSnap",      { type = "bezier", points = { {0.05, 0.9},  {0.1, 1}     } })

-- ── Animationsregeln ─────────────────────────────────────────
-- Fenster öffnen/schließen
hl.animation("windows",      { enabled = true, duration = 250, curve = "tokyoSmooth",  style = "popin 80%" })
hl.animation("windowsIn",    { enabled = true, duration = 200, curve = "tokyoSmooth",  style = "popin 80%" })
hl.animation("windowsOut",   { enabled = true, duration = 200, curve = "easeOutQuint", style = "popin 80%" })
hl.animation("windowsMove",  { enabled = true, duration = 200, curve = "tokyoSnap" })

-- Ein-/Ausblenden
hl.animation("fade",         { enabled = true, duration = 200, curve = "easeOutQuint" })
hl.animation("fadeIn",       { enabled = true, duration = 150, curve = "easeOutQuint" })
hl.animation("fadeOut",      { enabled = true, duration = 150, curve = "easeOutQuint" })

-- Layer-Animationen (z.B. Waybar, Rofi)
hl.animation("layers",       { enabled = true, duration = 200, curve = "tokyoSmooth",  style = "fade" })
hl.animation("layersIn",     { enabled = true, duration = 150, curve = "tokyoSmooth",  style = "fade" })
hl.animation("layersOut",    { enabled = true, duration = 150, curve = "easeOutQuint", style = "fade" })

-- Rahmenfarbe
hl.animation("border",       { enabled = true, duration = 300, curve = "easeInOutCubic" })
hl.animation("borderangle",  { enabled = true, duration = 600, curve = "linear", style = "loop" })

-- Workspace-Wechsel
hl.animation("workspaces",   { enabled = true, duration = 250, curve = "tokyoSmooth",  style = "slide" })
