-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Fensterregeln                                              ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ── Schwebende Fenster ───────────────────────────────────────
-- Dialoge und kleine Fenster
hl.window_rule({
    match = { class = "pavucontrol" },
    float = true,
})
hl.window_rule({
    match = { class = "nm-connection-editor" },
    float = true,
})
hl.window_rule({
    match = { class = "blueman-manager" },
    float = true,
})
hl.window_rule({
    match = { class = "floating_kitty" },
    float = true,
})

hl.window_rule({
    match = { title = "Open File" },
    float = true,
})
hl.window_rule({
    match = { title = "Save File" },
    float = true,
})
hl.window_rule({
    match = { title = "Datei öffnen" },
    float = true,
})
hl.window_rule({
    match = { title = "Datei speichern" },
    float = true,
})
hl.window_rule({
    match = { title = "Confirm" },
    float = true,
})
hl.window_rule({
    match = { title = "Bestätigen" },
    float = true,
})
hl.window_rule({
    match = { title = "Properties" },
    float = true,
})
hl.window_rule({
    match = { title = "Eigenschaften" },
    float = true,
})

-- Dateimanager Dateivorgang als Floating
hl.window_rule({
    match = { class = "thunar", title = "Dateivorgang" },
    float = true,
})
hl.window_rule({
    match = { class = "thunar", title = "File Operation Progress" },
    float = true,
})

-- Einstellungs-App
hl.window_rule({
    match = { class = "tokyo-settings" },
    float = true,
    size = "960 680",
    center = true,
    opacity = "0.97 0.93",
})

-- Rofi Fensterregeln (Fallback)
hl.window_rule({
    match = { class = "rofi" },
    float = true,
    center = true,
})
hl.window_rule({
    match = { class = "Rofi" },
    float = true,
    center = true,
})

-- ── Polkit-Agent ─────────────────────────────────────────────
hl.window_rule({
    match = { class = "polkit-gnome-authentication-agent-1" },
    float = true,
    center = true,
})
hl.window_rule({
    match = { class = "hyprpolkitagent" },
    float = true,
    center = true,
})

-- ── Bild-im-Bild ────────────────────────────────────────────
hl.window_rule({
    match = { title = "Picture-in-Picture" },
    float = true,
    pin = true,
    size = "480 270",
    move = "100%-490 40",
})
hl.window_rule({
    match = { title = "Bild-im-Bild" },
    float = true,
    pin = true,
    size = "480 270",
    move = "100%-490 40",
})

-- ── Transparenz ──────────────────────────────────────────────
hl.window_rule({
    match = { class = "kitty" },
    opacity = "0.92 0.88",
})

-- ── Workspace-Zuweisungen (optional) ─────────────────────────
-- Entkommentiere und passe an deine Bedürfnisse an:
-- hl.window_rule({ match = { class = "firefox" }, workspace = "1" })
-- hl.window_rule({ match = { class = "kitty" },   workspace = "2" })
-- hl.window_rule({ match = { class = "thunar" },  workspace = "3" })
-- hl.window_rule({ match = { class = "discord" }, workspace = "9" })
-- hl.window_rule({ match = { class = "spotify" }, workspace = "10" })

-- ── Layerregeln ──────────────────────────────────────────────
-- Rofi-Blur
hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.0,
})

-- Waybar-Blur
hl.layer_rule({
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0.3,
})

-- SwayNC Kontrollzentrum & Benachrichtigungen Blur
hl.layer_rule({
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = 0.5,
})
hl.layer_rule({
    match = { namespace = "swaync-notification-window" },
    blur = true,
    ignore_alpha = 0.5,
})
