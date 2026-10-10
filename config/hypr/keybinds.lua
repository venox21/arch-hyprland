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

-- Kontrollzentrum & Benachrichtigungen (SwayNC)
hl.bind("SUPER + N",             hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind("SUPER + SHIFT + N",     hl.dsp.exec_cmd("swaync-client -d -sw"))

-- ══════════════════════════════════════════════════════════════
-- ██ Fensterverwaltung (Native Hyprland Dispatchers)
-- ══════════════════════════════════════════════════════════════

-- Fenster schließen
hl.bind("SUPER + Q",             hl.dsp.window.close())

-- Hyprland beenden
hl.bind("SUPER + SHIFT + M",     hl.dsp.exec_cmd("hyprctl dispatch exit"))

-- Fenster schwebend / gekachelt umschalten
hl.bind("SUPER + V",             hl.dsp.window.float({ action = "toggle" }))

-- Fenster maximieren (Dwindle behält Bar)
hl.bind("SUPER + F",             hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Echtes Vollbild
hl.bind("SUPER + SHIFT + F",     hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Pseudo-Kachel
hl.bind("SUPER + P",             hl.dsp.window.pseudo())

-- Splitrichtung wechseln (Dwindle)
hl.bind("SUPER + J",             hl.dsp.layout("togglesplit"))

-- Fenster zentrieren
hl.bind("SUPER + C",             hl.dsp.window.center())

-- Fenster anpinnen (auf allen Workspaces)
hl.bind("SUPER + SHIFT + P",     hl.dsp.window.pin({ action = "toggle" }))

-- ══════════════════════════════════════════════════════════════
-- ██ Fokus bewegen
-- ══════════════════════════════════════════════════════════════

hl.bind("SUPER + Left",          hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + Right",         hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + Up",            hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + Down",          hl.dsp.focus({ direction = "down" }))

-- Alternativ mit H/K/L (Vim-Stil, SUPER+J ist togglesplit)
hl.bind("SUPER + H",             hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + L",             hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + K",             hl.dsp.focus({ direction = "up" }))

-- ══════════════════════════════════════════════════════════════
-- ██ Fenster verschieben
-- ══════════════════════════════════════════════════════════════

hl.bind("SUPER + SHIFT + Left",  hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + Up",    hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + Down",  hl.dsp.window.move({ direction = "down" }))

hl.bind("SUPER + SHIFT + H",     hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + L",     hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + K",     hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + J",     hl.dsp.window.move({ direction = "down" }))

-- ══════════════════════════════════════════════════════════════
-- ██ Fenstergröße ändern
-- ══════════════════════════════════════════════════════════════

hl.bind("SUPER + CTRL + Left",   hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + Right",  hl.dsp.window.resize({ x = 40, y = 0, relative = true }),  { repeating = true })
hl.bind("SUPER + CTRL + Up",     hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + Down",   hl.dsp.window.resize({ x = 0, y = 40, relative = true }),  { repeating = true })

-- ══════════════════════════════════════════════════════════════
-- ██ Workspaces
-- ══════════════════════════════════════════════════════════════

-- Workspace wechseln (1–10)
for i = 1, 9 do
    hl.bind("SUPER + " .. i,           hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i,   hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + 0",                   hl.dsp.focus({ workspace = 10 }))
hl.bind("SUPER + SHIFT + 0",           hl.dsp.window.move({ workspace = 10 }))

-- Zum nächsten/vorherigen Workspace scrollen
hl.bind("SUPER + mouse_down",          hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",            hl.dsp.focus({ workspace = "e-1" }))

-- Spezieller Workspace (Scratchpad)
hl.bind("SUPER + S",                   hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + CTRL + S",            hl.dsp.window.move({ workspace = "special:magic" }))

-- ══════════════════════════════════════════════════════════════
-- ██ Maus-Bindings (Fenster ziehen / vergrößern)
-- ══════════════════════════════════════════════════════════════

-- Fenster mit Maus bewegen (Super + Linke Maustaste gedrückt halten)
hl.bind("SUPER + mouse:272",     hl.dsp.window.drag(), { mouse = true })

-- Fenster mit Maus vergrößern (Super + Rechte Maustaste gedrückt halten)
hl.bind("SUPER + mouse:273",     hl.dsp.window.resize(), { mouse = true })

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
