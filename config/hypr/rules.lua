-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Fensterregeln                                              ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ── Schwebende Fenster ───────────────────────────────────────
-- Dialoge und kleine Fenster
hl.window_rule({
    rule  = "float",
    class = { "pavucontrol", "nm-connection-editor", "blueman-manager" },
})

hl.window_rule({
    rule  = "float",
    title = { "Open File", "Save File", "Datei öffnen", "Datei speichern",
              "Confirm", "Bestätigen", "Properties", "Eigenschaften" },
})

-- Dateimanager als Floating
hl.window_rule({
    rule   = "float",
    class  = { "thunar" },
    title  = { "Dateivorgang", "File Operation Progress" },
})

-- Einstellungs-App
hl.window_rule({
    rule  = "float",
    class = { "tokyo-settings" },
})
hl.window_rule({
    rule  = "size 900 650",
    class = { "tokyo-settings" },
})
hl.window_rule({
    rule  = "center",
    class = { "tokyo-settings" },
})

-- ── Polkit-Agent ─────────────────────────────────────────────
hl.window_rule({
    rule  = "float",
    class = { "polkit-gnome-authentication-agent-1",
              "hyprpolkitagent" },
})
hl.window_rule({
    rule  = "center",
    class = { "polkit-gnome-authentication-agent-1",
              "hyprpolkitagent" },
})

-- ── Bild-im-Bild ────────────────────────────────────────────
hl.window_rule({
    rule  = "float",
    title = { "Picture-in-Picture", "Bild-im-Bild" },
})
hl.window_rule({
    rule  = "pin",
    title = { "Picture-in-Picture", "Bild-im-Bild" },
})
hl.window_rule({
    rule  = "size 480 270",
    title = { "Picture-in-Picture", "Bild-im-Bild" },
})
hl.window_rule({
    rule  = "move 100%-490 40",
    title = { "Picture-in-Picture", "Bild-im-Bild" },
})

-- ── Transparenz ──────────────────────────────────────────────
hl.window_rule({
    rule  = "opacity 0.92 0.88",
    class = { "kitty" },
})

-- ── Workspace-Zuweisungen (optional) ─────────────────────────
-- Entkommentiere und passe an deine Bedürfnisse an:
-- hl.window_rule({ rule = "workspace 1", class = { "firefox" } })
-- hl.window_rule({ rule = "workspace 2", class = { "kitty" } })
-- hl.window_rule({ rule = "workspace 3", class = { "thunar" } })
-- hl.window_rule({ rule = "workspace 9", class = { "discord" } })
-- hl.window_rule({ rule = "workspace 10", class = { "spotify" } })

-- ── Layerregeln ──────────────────────────────────────────────
-- Rofi-Blur
hl.layer_rule({
    rule      = "blur",
    namespace = { "rofi" },
})
hl.layer_rule({
    rule      = "ignorezero",
    namespace = { "rofi" },
})

-- Waybar-Blur
hl.layer_rule({
    rule      = "blur",
    namespace = { "waybar" },
})
hl.layer_rule({
    rule      = "ignorealpha 0.3",
    namespace = { "waybar" },
})
