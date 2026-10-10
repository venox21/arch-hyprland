-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Tokyo Night – Zentrale Farbpalette                        ║
-- ║  Alle Farben als RGBA-Hex für Hyprland Lua API             ║
-- ╚══════════════════════════════════════════════════════════════╝

local M = {}

-- ── Hintergrund ──────────────────────────────────────────────
M.bg_dark   = "rgba(1a1b26ff)"   -- Dunkelster Hintergrund
M.bg        = "rgba(24283bff)"   -- Standard-Hintergrund
M.bg_light  = "rgba(292e42ff)"   -- Leicht heller
M.bg_hl     = "rgba(33467cff)"   -- Hervorhebung

-- ── Vordergrund ──────────────────────────────────────────────
M.fg        = "rgba(c0caf5ff)"   -- Standardtext
M.fg_dark   = "rgba(a9b1d6ff)"   -- Gedämpfter Text
M.fg_gutter = "rgba(3b4261ff)"   -- Zeilennummern, Gutter

-- ── Farben ───────────────────────────────────────────────────
M.red       = "rgba(f7768eff)"   -- Fehler, kritisch
M.orange    = "rgba(ff9e64ff)"   -- Warnungen
M.yellow    = "rgba(e0af68ff)"   -- Hinweise
M.green     = "rgba(9ece6aff)"   -- Erfolg
M.teal      = "rgba(73dacaff)"   -- Akzent 2
M.cyan      = "rgba(7dcfffff)"   -- Akzent 3
M.blue      = "rgba(7aa2f7ff)"   -- Primärfarbe
M.magenta   = "rgba(bb9af7ff)"   -- Sekundärfarbe
M.purple    = "rgba(9d7cd8ff)"   -- Lila-Variante

-- ── Rahmen und Oberflächen ───────────────────────────────────
M.border_active   = "rgba(7aa2f7ee)"   -- Aktiver Fensterrahmen
M.border_inactive = "rgba(33467caa)"   -- Inaktiver Fensterrahmen
M.border_locked   = "rgba(bb9af7ee)"   -- Gesperrter Rahmen

-- ── Schatten ─────────────────────────────────────────────────
M.shadow = 0xee1a1b26                   -- Schattenfarbe (als Integer)

-- ── Gradient für aktive Rahmen ───────────────────────────────
M.border_gradient = {
    colors = { "rgba(7aa2f7ee)", "rgba(bb9af7ee)" },
    angle  = 45,
}

-- ── Transparenzstufen ────────────────────────────────────────
M.opacity_active   = 1.0
M.opacity_inactive = 0.92

-- ── Dim ──────────────────────────────────────────────────────
M.dim_inactive = 0.08

return M
