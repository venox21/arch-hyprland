# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden hier dokumentiert.

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
