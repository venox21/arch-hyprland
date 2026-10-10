-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Animationen – Dezent und zurückhaltend                     ║
-- ╚══════════════════════════════════════════════════════════════╝

hl.config({
    animations = {
        enabled   = true,
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
hl.animation({ leaf = "windows",     enabled = true, speed = 2.5, bezier = "tokyoSmooth",  style = "popin 80%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 2.0, bezier = "tokyoSmooth",  style = "popin 80%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.0, bezier = "easeOutQuint", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.0, bezier = "tokyoSnap" })

-- Ein-/Ausblenden
hl.animation({ leaf = "fade",        enabled = true, speed = 2.0, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 1.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 1.5, bezier = "easeOutQuint" })

-- Layer-Animationen (z.B. Waybar, Rofi)
hl.animation({ leaf = "layers",      enabled = true, speed = 2.0, bezier = "tokyoSmooth",  style = "fade" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 1.5, bezier = "tokyoSmooth",  style = "fade" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "fade" })

-- Rahmenfarbe
hl.animation({ leaf = "border",      enabled = true, speed = 3.0, bezier = "easeInOutCubic" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 6.0, bezier = "linear", style = "loop" })

-- Workspace-Wechsel
hl.animation({ leaf = "workspaces",  enabled = true, speed = 2.5, bezier = "tokyoSmooth",  style = "slide" })
