# Tokyo Night Hyprland Dots

Ein vollständiges, minimalistisches Hyprland-Desktop-Setup im Tokyo-Night-Stil für Arch Linux.

## Funktionen

- 🎨 **Tokyo Night Farbpalette** – einheitlich über alle Komponenten
- 🖥 **Hyprland Lua-Konfiguration** – modular, sauber, erweiterbar
- 📊 **Waybar** – mit Systemleistung, Uhr, Audio, Netzwerk und mehr
- ⚙️ **Einstellungs-App** – GTK4/libadwaita GUI für alle Einstellungen
- ⌨️ **Hotkey-Manager** – Tastenkürzel anzeigen, suchen, bearbeiten
- 🔒 **Hyprlock** – Sperrbildschirm mit Uhr und Passwort
- 🖼 **Hyprpaper** – Hintergrundbilder mit Wechsel-Funktion
- 🚀 **Rofi** – App-Launcher und Power-Menü
- 📋 **Clipboard** – Zwischenablage-Historie mit Suche
- 📸 **Tokyo Shot (Screenshot-Manager & Editor)** – Eigenes, modernes GTK4/libadwaita Tool mit Live-Editor (Stift, Pfeile, Rechteck, Zensieren, Bild-im-Bild-Pin), Verzögerungstimer und automatischer Zwischenablage
- 🔐 **SDDM** – Anmeldebildschirm im Tokyo Night Design
- 💾 **Backup & Restore** – Sichere Installation mit Wiederherstellung
- 🧪 **Automatisierte Tests** – Konfigurations-, Installations- und Einstellungstests

## Voraussetzungen

- Arch Linux (installiert)
- Internetzugang (für Paketinstallation)
- sudo-Zugriff

## Installation

```bash
# Repository klonen oder herunterladen
git clone https://github.com/venox21/arch-hyprland.git
cd arch-hyprland

# Tests vor der Installation ausführen (optional)
bash tests/test-config.sh
bash tests/test-install.sh

# Installation starten
chmod +x install.sh
./install.sh
```

Das Installationsskript:
1. Prüft dein System
2. Erstellt ein Backup vorhandener Konfigurationen
3. Installiert fehlende Pakete
4. Kopiert alle Konfigurationsdateien
5. Richtet SDDM ein
6. Aktiviert Systemdienste
7. Validiert die Installation
8. Fragt vor dem Neustart

## Nach dem Neustart

```bash
# Diagnose ausführen
./doctor.sh

# Beliebte Programme installieren (optional)
./install-apps.sh
```

## TUI App-Installer

Mit `./install-apps.sh` (oder `~/.config/hypr/scripts/app-installer.sh`) steht ein interaktiver Terminal-Installer zur Verfügung (navigierbar mit Pfeiltasten, Checkbox-Auswahl per Leertaste, Bestätigung per Enter):
- **Google Chrome** (`google-chrome` via AUR)
- **Visual Studio Code** (`visual-studio-code-bin` via AUR)
- **Spotify (Nur Client)** (`spotify` via AUR)
- **Spotify + Spicetify** (`spotify`, `spicetify-cli`, `spicetify-marketplace-bin` inkl. automatischer Schreibrechte-Konfiguration)
- **Steam** (`steam` inkl. automatischer Aktivierung des `[multilib]` Repositories)
- **Obsidian** (`obsidian`)

Automatischer Check und Setup von `yay` und `gum` bei Bedarf.

## Aktualisierung & Synchronisation

Um Änderungen aus dem Git-Repository schnell zu übernehmen und alle Konfigurationsdateien automatisch zu aktualisieren:

```bash
git pull
./update.sh
```

Das Skript `update.sh` synchronisiert alle Konfigurationen, setzt die Dateirechte, konfiguriert Themes/Icons und lädt SwayNC sowie Waybar neu.

## Deinstallation

```bash
./uninstall.sh
```

## Backup wiederherstellen

```bash
./restore-backup.sh
```

## Tastenkürzel

| Taste | Funktion |
|-------|----------|
| `SUPER + Return` | Terminal (Kitty) |
| `SUPER + D` | App-Launcher (Rofi) |
| `SUPER + Q` | Fenster schließen |
| `SUPER + E` | Dateimanager (Thunar) |
| `SUPER + B` | Browser |
| `SUPER + V` | Fenster schwebend |
| `SUPER + F` | Fenster maximieren |
| `SUPER + 1-0` | Workspace 1–10 |
| `SUPER + SHIFT + 1-0` | Fenster zu Workspace |
| `SUPER + Pfeiltasten` | Fokus bewegen |
| `SUPER + SHIFT + Pfeile` | Fenster verschieben |
| `SUPER + SHIFT + S` | Screenshot (Bereich aufnehmen & bearbeiten) |
| `SUPER + Print` | Screenshot (Aktives Fenster) |
| `Print` | Screenshot (Vollbild) |
| `SUPER + ALT + S` | Tokyo Shot (Screenshot-Hub & Editor öffnen) |
| `SUPER + SHIFT + V` | Zwischenablage |
| `SUPER + SHIFT + X` | Bildschirm sperren |
| `SUPER + SHIFT + E` | Power-Menü |
| `SUPER + I` | Einstellungen |
| `SUPER + N` | Kontrollzentrum & Benachrichtigungen (SwayNC) |
| `SUPER + SHIFT + N` | Nicht stören (DND) umschalten |
| `SUPER + SHIFT + K` | Hotkey-Manager |
| `SUPER + W` | Wallpaper-Manager (Visuelle Kachelauswahl / Wallpaper-Bank) |
| `SUPER + SHIFT + W` | Wallpaper-Manager (Alternative) |
| `SUPER + ALT + W` | Zufälliges Wallpaper wechseln |
| `SUPER + SHIFT + R` | Konfiguration neu laden |
| `SUPER + SHIFT + B` | Waybar neu starten |
| `SUPER + F1` | GameMode / Performance-Toggle (Maximale FPS) |

Alle Tastenkürzel sind im Hotkey-Manager anzeig- und bearbeitbar.

## Kontrollzentrum & Benachrichtigungen (SwayNC)

Das integrierte Tokyo Night Kontrollzentrum bietet schnellen Zugriff auf alle essenziellen Systemeinstellungen:
- **Aufruf**: Klick auf das Glockensymbol in der Waybar oder per `SUPER + N` (DND-Schnellschalter: Rechtsklick oder `SUPER + SHIFT + N`)
- **WLAN**: Drahtlosnetzwerke scannen, auswählen und direkt verbinden (inkl. Passwortabfrage oder nm-connection-editor)
- **Bluetooth**: Bluetooth-Geräte verbinden, koppeln und verwalten (via Blueman GUI oder Rofi)
- **Audioausgabe**: Schneller Zugriff auf Lautstärkeregler und Mixer
- **Nachtmodus**: Blaulichtfilter mit warmer Farbtemperatur (4000K)
- **Theme**: Sofortiger Aufruf der Tokyo Night Einstellungs-App
- **Energiesparmodus**: Schaltet rechenintensive Effekte (Blur, Schatten, Animationen) temporär aus, um die Akkulaufzeit zu maximieren
- **GameMode**: Schaltet alle Effekte & Gaps ab, aktiviert Tearing und den Performance-Governor für maximale Gaming-FPS
- **System-Cleaner**: 1-Klick Terminal-Wartung für Paket-Caches, verwaiste Pakete, Systemd-Logs und Temp-Dateien
- **Benachrichtigungen**: Interaktive Benachrichtigungsliste, Einzel- und Gesamtlöschung, DND-Modus
- **Schieberegler & Medien**: Lautstärke- und Helligkeitsregler sowie MPRIS Media Player Steuerung

## Hintergrundbild & JaKooLit Wallpaper-Bank

Das Setup beinhaltet eine vollständige visuelle Wallpaper-Verwaltung inklusive Integration der **[JaKooLit Wallpaper-Bank](https://github.com/JaKooLit/Wallpaper-Bank)**:

1. **Visuelle Kachelauswahl (`SUPER + W`)**:
   - Rofi-Kachelraster mit Thumbnail-Vorschauen (`~/.cache/wallpaper-thumbs/`)
   - Enthält Schnellauswahl für *Zufälliges Wallpaper* und *Wallpaper-Bank synchronisieren*
2. **JaKooLit Wallpaper-Bank Synchronisieren**:
   - Entweder direkt im Rofi-Menü (`SUPER + W` -> *📥 Wallpaper-Bank synchronisieren*),
   - Im Terminal über `~/.config/hypr/scripts/wallpaper.sh --sync`,
   - Oder in den GTK4 Einstellungen unter **Hintergrundbilder**.
3. **Eigene Bilder einbinden**:
   - Beliebige Bilder (`.jpg`, `.jpeg`, `.png`, `.webp`) in `~/.config/hypr/wallpapers/` oder `~/Pictures/wallpapers/` ablegen. Sie werden automatisch mit Thumbnails im Wähler und in den Einstellungen aufgeführt.

## Einstellungs-App

Erreichbar über:
- Waybar (⚙-Symbol)
- `SUPER + I`
- Terminal: `~/.config/hypr/scripts/settings.sh`

## Monitorkonfiguration

Bearbeite `~/.config/hypr/monitors.lua`:

```lua
-- Verwende hyprctl monitors um deine Monitornamen zu erfahren
hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@144",
    position = "0x0",
    scale    = "1",
})
```

## Fehlerbehebung

```bash
# Diagnose ausführen
./doctor.sh

# Hyprland-Logs anzeigen
hypr-logs  # (Alias in .zshrc)

# Konfiguration prüfen
hyprctl reload

# Waybar neu starten
~/.config/hypr/scripts/waybar-restart.sh
```

## Lizenz

MIT License
