# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden hier dokumentiert.

## [Unveröffentlicht]

### Hinzugefügt
- **Waybar-Layout „Crystal Clear“** (`config/waybar/layouts/crystal/`): Glas-Optik mit hellem Rand, Glanz und Text-Schatten; `classic` bleibt unverändert wählbar.
- **Waybar-Transparenz-Regler** (Einstellungen → Leisten-Stil und Aussehen): Slider plus Prozentfeld (0 % = deckend, 100 % = durchsichtig), wirkt live per CSS-Reload und wird pro Layout gespeichert.
- **Eigenes Screenshot-Tool „Tokyo Shot“** (`screenshot/`, `scripts/tokyo-shot`):
  - Moderner GTK4/libadwaita Screenshot-Hub mit 4 Aufnahmemodi (Bereich, Fenster, Monitor, Vollbild)
  - Vollwertiger Annotation-Editor mit Cairo: Stift, Richtungspfeile, Rechtecke, Zensurbalken/Unkenntlichmachen
  - Tokyo-Night-Farbpalette, Undo/Redo (`Strg+Z`/`Strg+Y`), Bild-im-Bild Pin-Funktion
  - Sofortige Zwischenablage, Zeitverzögerungstimer (0s, 3s, 5s, 10s), Desktop-Eintrag für Rofi
  - Vollständig in `install.sh`, `update.sh`, `uninstall.sh` und Tastenkürzel (`SUPER + ALT + S`, `SUPER + SHIFT + S`) integriert.
- **Interaktiver TUI App-Installer** (`install-apps.sh`, `scripts/app-installer.sh`):
  - Automatische Erkennung und Installation von `yay` (via `yay-bin.git` mit automatischer `git`/`base-devel`-Bereitstellung und Cleanup) sowie `gum`
  - Multi-Select Terminal-Menü mit Checkboxen (Leertaste, Pfeiltasten, Enter)
  - Paketauswahl: Google Chrome, Visual Studio Code, Spotify, Spotify + Spicetify, Steam, Obsidian
  - Automatische Aktivierung des `[multilib]` Repositories für Steam in `/etc/pacman.conf`
  - Paket-Deduplizierung und automatische Schreibrechte-Konfiguration für Spicetify (`/opt/spotify`)
- **GameMode / Performance-Toggle** (`scripts/gamemode.sh`, Hotkey: `SUPER + F1`, Kontrollzentrum):
  - Schaltet Hyprland-Effekte (Blur, Schatten, Animationen, Gaps) für maximale Gaming-FPS temporär ab
  - Aktiviert Tearing (`allow_tearing true`) und setzt den CPU-Governor auf `performance`
  - Integriert als Toggle im SwayNC-Kontrollzentrum mit Live-Statusanzeige
- **Arch System-Cleaner** (`scripts/clean-system.sh`, Kontrollzentrum, Rofi):
  - Bereinigt Pacman- & yay/AUR-Caches (`paccache -rk2`), entfernt verwaiste Pakete (`pacman -Qtdq`), stutzt Journal-Logs und Thumbnail-Caches
  - Führt Systemd-Gesundheitsprüfung durch und berechnet freigegebenen Speicherplatz
  - Direkt über das Kontrollzentrum oder als App in Rofi startbar

### Geändert
- **SDDM-Anmeldebildschirm komplett neu gestaltet** (`assets/sddm/tokyo-night/Main.qml`): große, dünne Uhr, Avatar mit Benutzername (Benutzerwechsel bei mehreren Konten), Passwortfeld als Pille mit Pfeil-Button, Shake-Animation bei falschem Passwort, Feststelltasten-Warnung, Ladeindikator, sanfter Ein-/Ausblend-Übergang, Sitzungswähler, Tastaturlayout-Umschalter sowie Standby/Neustart/Herunterfahren. Benötigt keine zusätzlichen Qt-Module.
- Waybar-Layerregel: `ignore_alpha` von 0.3 auf 0.01, damit auch sehr transparente Leisten unscharf bleiben.
- Die bisherige, wirkungslose Einstellung `waybar.transparency` wurde durch `waybar.opacity_by_layout` ersetzt.

## [1.2.0] – 2026-10-11

### Hinzugefügt
- **SwayNC Kontrollzentrum (Control Center) in Waybar**:
  - Interaktives Panel für schnellen Zugriff auf Schnelleinstellungen
  - **WLAN-Umschalter**: Schnelles Ein-/Ausschalten und Statusprüfung per `nmcli`
  - **Bluetooth-Umschalter**: Adapter-Steuerung per `bluetoothctl`
  - **Audioausgabe**: Schneller Mixer-Zugriff (`pavucontrol` / `pamixer`)
  - **Nachtmodus**: Blaulichtfilter / Farbtemperatur-Regelung (`wlsunset` / `gammastep` / `hyprshade`)
  - **Theme-Manager**: Direkter Schnellstart der Tokyo Night Einstellungs-App
  - **Energiesparmodus**: Dynamisches Deaktivieren von Blur, Animationen und Schatten für maximale Akkulaufzeit & Performance
  - **Benachrichtigungen**: Scrollbare Benachrichtigungsliste, DND (Nicht stören) Schalter und Alle-Löschen-Funktion
  - **Lautstärke- & Helligkeits-Schieberegler** sowie MPRIS Media Player
- **Neues Hilfsskript**: `scripts/control-center.sh`
- **Waybar-Modul**: `custom/swaync` mit dynamischen Glocken- und DND-Icons sowie Klick-Aktionen
- **Neue Tastenkürzel**:
  - `SUPER + N` – Kontrollzentrum öffnen/schließen
  - `SUPER + SHIFT + N` – Nicht stören (DND) umschalten

## [1.1.0] – 2026-10-10

### Hinzugefügt
- **JaKooLit Wallpaper-Bank Integration** – Klonen, Synchronisieren und Auswählen von über 150 Wallpapers aus https://github.com/JaKooLit/Wallpaper-Bank
- **Visueller Rofi Wallpaper-Kachelwähler** – `config/rofi/wallpaper.rasi` mit Thumbnail-Vorschau und Gitterlayout
- **Hintergrundbilder-Seite in GTK4 Einstellungs-App** – Vorschau, Aktivieren per Klick, Sync-Button, Zufallsauswahl
- **Neue Tastenkürzel**:
  - `SUPER + W` – Wallpaper-Kachelauswahl (JaKooLit-Standard)
  - `SUPER + SHIFT + W` – Wallpaper-Kachelauswahl (Tokyo-Dots-Standard)
  - `SUPER + ALT + W` – Zufälliges Hintergrundbild sofort setzen
- **Mitgelieferte Tokyo Night Starter-Wallpapers** in `assets/wallpapers/`
- **Installer-Erweiterung (`install.sh`)** – Optionale automatische Installation der gesamten JaKooLit Wallpaper-Bank in Phase 5

## [1.0.0] – 2026-10-10

### Hinzugefügt

- **Hyprland Lua-Konfiguration** – Modular mit colors, keybinds, monitors, rules, animations, autostart, input
- **Waybar** – Vollständige Konfiguration mit Tokyo Night CSS, allen Modulen
- **Einstellungs-App** – GTK4/libadwaita GUI mit 12 Seiten
- **Hotkey-Manager** – Tastenkürzel anzeigen, bearbeiten, hinzufügen, löschen, Konflikte erkennen
- **SDDM-Theme** – QML-basierter Anmeldebildschirm im Tokyo Night Design
- **Hyprlock** – Sperrbildschirm mit Uhr, Datum, Begrüßung
- **Rofi** – App-Launcher und Power-Menü mit Tokyo Night Theme
- **Kitty** – Terminal mit vollständigem Tokyo Night Farbschema
- **Mako** – Benachrichtigungen mit Dringlichkeitsstufen
- **Zsh + Starship** – Shell-Konfiguration mit Aliassen und Prompt
- **Screenshots** – Vollbild, Bereich, aktives Fenster
- **Clipboard** – Zwischenablage-Manager mit cliphist + Rofi
- **Wallpaper-Wechsler** – Hyprpaper-basiert mit Rofi-Auswahl
- **install.sh** – 9-Phasen-Installationsskript mit Backup
- **uninstall.sh** – Phasenweise Deinstallation
- **restore-backup.sh** – Interaktive Backup-Wiederherstellung
- **doctor.sh** – Post-Install-Diagnose
- **Automatisierte Tests** – Konfigurationstest, Installationstest, Python-Tests
