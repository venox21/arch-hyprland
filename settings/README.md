# Einstellungs-App und Hotkey-Manager

## Voraussetzungen

Die GUI-Anwendungen benötigen:

```bash
sudo pacman -S python python-gobject gtk4 libadwaita
```

## Einstellungs-App starten

```bash
# Über Waybar (Zahnrad-Symbol)
# Oder über das Terminal:
~/.config/hypr/scripts/settings.sh

# Oder direkt:
python3 ~/.config/hypr/settings/app.py
```

## Hotkey-Manager starten

```bash
# Über Waybar (Tastatur-Symbol)
# Oder über das Terminal:
~/.config/hypr/scripts/hotkeys.sh

# Oder mit Tastenkürzel:
# SUPER + SHIFT + K
```

## Architektur

```
settings/
├── app.py              – GTK4 Einstellungs-App
├── hotkey_manager.py   – GTK4 Hotkey-Manager
├── config_manager.py   – Konfigurationsverwaltung
└── requirements.txt    – Python-Abhängigkeiten
```

### config_manager.py

Zentrale Bibliothek für:
- Laden und Speichern der Benutzereinstellungen (JSON)
- Lesen und Schreiben der Waybar-Konfiguration (JSONC)
- Hyprland-Steuerung über hyprctl
- Backup-Erstellung

### hotkey_manager.py

Analysiert `keybinds.lua` direkt:
- Erkennt hl.bind() Aufrufe
- Extrahiert Kategorien aus den Kommentaren
- Unterstützt Bearbeiten, Hinzufügen, Löschen
- Erkennt Konflikte
- Erstellt automatisch Backups vor Änderungen
- Kann Standard-Belegung wiederherstellen
