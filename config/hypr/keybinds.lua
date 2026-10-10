-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Tastenkürzel – Zentrale Hotkey-Definition                  ║
-- ║  Quelle der Wahrheit für alle Keybindings                   ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ── Programme ────────────────────────────────────────────────
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "rofi -show drun -theme ~/.config/rofi/config.rasi"
local browser     = "firefox"

-- Pfade zu Hilfsskripten
local scripts     = os.getenv("HOME") .. "/.config/hypr/scripts"

-- ══════════════════════════════════════════════════════════════
-- ██ Anwendungen
-- ══════════════════════════════════════════════════════════════

-- Terminal öffnen
hl.bind("SUPER + Return",        hl.dsp.exec_cmd(terminal))

-- Dateimanager öffnen
hl.bind("SUPER + E",             hl.dsp.exec_cmd(fileManager))

-- App-Launcher (Rofi)
hl.bind("SUPER + D",             hl.dsp.exec_cmd(menu))

-- Browser
hl.bind("SUPER + B",             hl.dsp.exec_cmd(browser))

-- Einstellungen
hl.bind("SUPER + I",             hl.dsp.exec_cmd(scripts .. "/settings.sh"))

-- ══════════════════════════════════════════════════════════════
-- ██ Fenster
-- ══════════════════════════════════════════════════════════════

-- Fenster schließen
hl.bind("SUPER + Q",             hl.dsp.exec_cmd("hyprctl dispatch killactive"))

-- Hyprland beenden
hl.bind("SUPER + SHIFT + M",     hl.dsp.exec_cmd("hyprctl dispatch exit"))

-- Fenster schwebend
hl.bind("SUPER + V",             hl.dsp.exec_cmd("hyprctl dispatch togglefloating"))

-- Fenster maximieren (Fullscreen Typ 1)
hl.bind("SUPER + F",             hl.dsp.exec_cmd("hyprctl dispatch fullscreen 1"))

-- Echtes Vollbild
hl.bind("SUPER + SHIFT + F",     hl.dsp.exec_cmd("hyprctl dispatch fullscreen 0"))

-- Pseudo-Kachel
hl.bind("SUPER + P",             hl.dsp.exec_cmd("hyprctl dispatch pseudo"))

-- Splitrichtung wechseln
hl.bind("SUPER + J",             hl.dsp.exec_cmd("hyprctl dispatch layoutmsg togglesplit"))

-- Fenster zentrieren
hl.bind("SUPER + C",             hl.dsp.exec_cmd("hyprctl dispatch centerwindow"))

-- Fenster anpinnen (immer im Vordergrund)
hl.bind("SUPER + SHIFT + P",     hl.dsp.exec_cmd("hyprctl dispatch pin"))

-- ══════════════════════════════════════════════════════════════
-- ██ Fokus bewegen
-- ══════════════════════════════════════════════════════════════

hl.bind("SUPER + Left",          hl.dsp.exec_cmd("hyprctl dispatch movefocus l"))
hl.bind("SUPER + Right",         hl.dsp.exec_cmd("hyprctl dispatch movefocus r"))
hl.bind("SUPER + Up",            hl.dsp.exec_cmd("hyprctl dispatch movefocus u"))
hl.bind("SUPER + Down",          hl.dsp.exec_cmd("hyprctl dispatch movefocus d"))

-- Alternativ mit H/J/K/L (Vim-Stil)
hl.bind("SUPER + H",             hl.dsp.exec_cmd("hyprctl dispatch movefocus l"))
hl.bind("SUPER + L",             hl.dsp.exec_cmd("hyprctl dispatch movefocus r"))
hl.bind("SUPER + K",             hl.dsp.exec_cmd("hyprctl dispatch movefocus u"))
-- SUPER+J wird bereits für toggle_split verwendet

-- ══════════════════════════════════════════════════════════════
-- ██ Fenster verschieben
-- ══════════════════════════════════════════════════════════════

hl.bind("SUPER + SHIFT + Left",  hl.dsp.exec_cmd("hyprctl dispatch movewindow l"))
hl.bind("SUPER + SHIFT + Right", hl.dsp.exec_cmd("hyprctl dispatch movewindow r"))
hl.bind("SUPER + SHIFT + Up",    hl.dsp.exec_cmd("hyprctl dispatch movewindow u"))
hl.bind("SUPER + SHIFT + Down",  hl.dsp.exec_cmd("hyprctl dispatch movewindow d"))

hl.bind("SUPER + SHIFT + H",     hl.dsp.exec_cmd("hyprctl dispatch movewindow l"))
hl.bind("SUPER + SHIFT + L",     hl.dsp.exec_cmd("hyprctl dispatch movewindow r"))
hl.bind("SUPER + SHIFT + K",     hl.dsp.exec_cmd("hyprctl dispatch movewindow u"))
hl.bind("SUPER + SHIFT + J",     hl.dsp.exec_cmd("hyprctl dispatch movewindow d"))

-- ══════════════════════════════════════════════════════════════
-- ██ Fenstergröße ändern
-- ══════════════════════════════════════════════════════════════

hl.bind("SUPER + CTRL + Left",   hl.dsp.exec_cmd("hyprctl dispatch resizeactive -40 0"))
hl.bind("SUPER + CTRL + Right",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive 40 0"))
hl.bind("SUPER + CTRL + Up",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -40"))
hl.bind("SUPER + CTRL + Down",   hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 40"))

-- ══════════════════════════════════════════════════════════════
-- ██ Workspaces
-- ══════════════════════════════════════════════════════════════

-- Workspace wechseln (1–10)
for i = 1, 9 do
    hl.bind("SUPER + " .. i,           hl.dsp.exec_cmd("hyprctl dispatch workspace " .. i))
    hl.bind("SUPER + SHIFT + " .. i,   hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace " .. i))
end
hl.bind("SUPER + 0",                   hl.dsp.exec_cmd("hyprctl dispatch workspace 10"))
hl.bind("SUPER + SHIFT + 0",           hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace 10"))

-- Zum nächsten/vorherigen Workspace scrollen
hl.bind("SUPER + mouse_down",          hl.dsp.exec_cmd("hyprctl dispatch workspace e+1"))
hl.bind("SUPER + mouse_up",            hl.dsp.exec_cmd("hyprctl dispatch workspace e-1"))

-- Spezieller Workspace (Scratchpad)
hl.bind("SUPER + S",                   hl.dsp.exec_cmd("hyprctl dispatch togglespecialworkspace magic"))
hl.bind("SUPER + SHIFT + S",           hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace special:magic"))

-- ══════════════════════════════════════════════════════════════
-- ██ Maus-Bindings
-- ══════════════════════════════════════════════════════════════

-- Fenster mit Maus bewegen
hl.bind("SUPER + mouse:272",     hl.dsp.exec_cmd("hyprctl dispatch movewindow l"), { mouse = true })
-- Fenster mit Maus vergrößern
hl.bind("SUPER + mouse:273",     hl.dsp.exec_cmd("hyprctl dispatch resizewindow l"), { mouse = true })

-- ══════════════════════════════════════════════════════════════
-- ██ Audio
-- ══════════════════════════════════════════════════════════════

-- Lautstärke
hl.bind("XF86AudioRaiseVolume",    hl.dsp.exec_cmd("pamixer -i 5"),  { locked = true })
hl.bind("XF86AudioLowerVolume",    hl.dsp.exec_cmd("pamixer -d 5"),  { locked = true })
hl.bind("XF86AudioMute",           hl.dsp.exec_cmd("pamixer -t"),    { locked = true })
hl.bind("XF86AudioMicMute",        hl.dsp.exec_cmd("pamixer --default-source -t"), { locked = true })

-- Mediaplayer
hl.bind("XF86AudioPlay",           hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",           hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",           hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- ══════════════════════════════════════════════════════════════
-- ██ Helligkeit
-- ══════════════════════════════════════════════════════════════

hl.bind("XF86MonBrightnessUp",     hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true })
hl.bind("XF86MonBrightnessDown",   hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true })

-- ══════════════════════════════════════════════════════════════
-- ██ Screenshots
-- ══════════════════════════════════════════════════════════════

-- Ganzer Bildschirm
hl.bind("Print",                    hl.dsp.exec_cmd(scripts .. "/screenshot.sh full"))

-- Bereich auswählen
hl.bind("SUPER + SHIFT + S",         hl.dsp.exec_cmd(scripts .. "/screenshot.sh area"))

-- Aktives Fenster
hl.bind("SUPER + Print",             hl.dsp.exec_cmd(scripts .. "/screenshot.sh window"))

-- ══════════════════════════════════════════════════════════════
-- ██ Zwischenablage
-- ══════════════════════════════════════════════════════════════

hl.bind("SUPER + SHIFT + V",         hl.dsp.exec_cmd(scripts .. "/clipboard.sh"))

-- ══════════════════════════════════════════════════════════════
-- ██ Bildschirmsperre und Power
-- ══════════════════════════════════════════════════════════════

-- Bildschirm sperren
hl.bind("SUPER + SHIFT + X",         hl.dsp.exec_cmd("hyprlock"))

-- Power-Menü
hl.bind("SUPER + SHIFT + E",         hl.dsp.exec_cmd(scripts .. "/power-menu.sh"))

-- ══════════════════════════════════════════════════════════════
-- ██ Sonstiges
-- ══════════════════════════════════════════════════════════════

-- Konfiguration neu laden
hl.bind("SUPER + SHIFT + R",         hl.dsp.exec_cmd("hyprctl reload"))

-- Wallpaper-Manager (Kachelauswahl / JaKooLit Wallpaper-Bank)
hl.bind("SUPER + W",                 hl.dsp.exec_cmd(scripts .. "/wallpaper.sh"))
hl.bind("SUPER + SHIFT + W",         hl.dsp.exec_cmd(scripts .. "/wallpaper.sh"))
hl.bind("SUPER + ALT + W",           hl.dsp.exec_cmd(scripts .. "/wallpaper.sh --random"))

-- Hotkey-Manager öffnen
hl.bind("SUPER + SHIFT + K",         hl.dsp.exec_cmd(scripts .. "/hotkeys.sh"))

-- Waybar neu starten
hl.bind("SUPER + SHIFT + B",         hl.dsp.exec_cmd(scripts .. "/waybar-restart.sh"))
