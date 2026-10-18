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

-- Tokyo Shot (Screenshot-Manager & Editor)
hl.window_rule({
    match = { class = "org.tokyo.shot" },
    float = true,
    center = true,
    size = "620 640",
})
hl.window_rule({
    match = { title = "Tokyo Shot – Editor" },
    float = true,
    center = true,
    size = "1100 760",
})
hl.window_rule({
    match = { title = ".*Tokyo Shot.*" },
    float = true,
    center = true,
})
hl.window_rule({
    match = { title = "Tokyo Shot – Pin" },
    float = true,
    pin = true,
    size = "420 280",
    move = "100%-430 40",
})

-- App-Installer (TUI im Terminal)
hl.window_rule({
    match = { class = "tokyo-app-installer" },
    float = true,
    size = "860 620",
    center = true,
})

-- App-Uninstaller (TUI im Terminal)
hl.window_rule({
    match = { class = "tokyo-app-uninstaller" },
    float = true,
    size = "860 620",
    center = true,
})

-- System-Cleaner (TUI im Terminal)
hl.window_rule({
    match = { class = "tokyo-system-cleaner" },
    float = true,
    size = "860 620",
    center = true,
})

-- Firewall-Manager (TUI im Terminal)
hl.window_rule({
    match = { class = "tokyo-firewall" },
    float = true,
    size = "860 620",
    center = true,
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

-- Waybar-Blur (niedriger ignore_alpha, damit auch sehr transparente Leisten
-- unscharf bleiben – Transparenz ist in den Einstellungen regelbar)
hl.layer_rule({
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0.01,
})

-- SwayNC Kontrollzentrum & Benachrichtigungen Blur
hl.layer_rule({
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = 0.2,
})
hl.layer_rule({
    match = { namespace = "swaync-notification-window" },
    blur = true,
    ignore_alpha = 0.2,
})
