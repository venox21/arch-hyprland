-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Monitor-Konfiguration                                      ║
-- ║  Automatische Erkennung + individuelle Profile              ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ── Standard: Alle Monitore automatisch erkennen ─────────────
-- Verwende bevorzugte Auflösung und automatische Positionierung
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- ── Individuelle Monitorprofile ──────────────────────────────
-- Entkommentiere und passe folgende Beispiele an deine Hardware an.
-- Verwende `hyprctl monitors` um die Namen deiner Monitore zu erfahren.

-- Beispiel: Einzelmonitor 1440p
-- hl.monitor({
--     output   = "DP-1",
--     mode     = "2560x1440@144",
--     position = "0x0",
--     scale    = "1",
-- })

-- Beispiel: Dual-Monitor Setup
-- hl.monitor({
--     output   = "DP-1",
--     mode     = "2560x1440@144",
--     position = "0x0",
--     scale    = "1",
-- })
-- hl.monitor({
--     output   = "HDMI-A-1",
--     mode     = "1920x1080@60",
--     position = "2560x0",
--     scale    = "1",
-- })

-- Beispiel: Laptop mit externem Monitor
-- hl.monitor({
--     output   = "eDP-1",
--     mode     = "1920x1080@60",
--     position = "0x0",
--     scale    = "1",
-- })
-- hl.monitor({
--     output   = "HDMI-A-1",
--     mode     = "2560x1440@60",
--     position = "1920x0",
--     scale    = "1",
-- })

-- ── Workspace-Zuweisung an Monitore ──────────────────────────
-- Standardmäßig werden Workspaces automatisch verteilt.
-- Für feste Zuweisungen, entkommentiere und passe an:

-- hl.config({
--     workspace = {
--         { name = "1", monitor = "DP-1" },
--         { name = "2", monitor = "DP-1" },
--         { name = "3", monitor = "DP-1" },
--         { name = "4", monitor = "DP-1" },
--         { name = "5", monitor = "DP-1" },
--         { name = "6", monitor = "HDMI-A-1" },
--         { name = "7", monitor = "HDMI-A-1" },
--         { name = "8", monitor = "HDMI-A-1" },
--         { name = "9", monitor = "HDMI-A-1" },
--         { name = "10", monitor = "HDMI-A-1" },
--     },
-- })
