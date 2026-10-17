# Settings App & Hotkey Manager

## Prerequisites

The GUI applications require Python with PyGObject, GTK4, and Libadwaita:

```bash
sudo pacman -S python python-gobject gtk4 libadwaita
```

## Launching the Settings App

```bash
# Via Waybar (gear icon)
# Or from the terminal:
~/.config/hypr/scripts/settings.sh

# Or directly with Python:
python3 ~/.config/hypr/settings/app.py
```

## Launching the Hotkey Manager

```bash
# Via Waybar (keyboard icon)
# Or from the terminal:
~/.config/hypr/scripts/hotkeys.sh

# Or with keyboard shortcut:
# SUPER + SHIFT + K
```

## Architecture

```
settings/
├── app.py              – GTK4 / Libadwaita Desktop Settings Application
├── hotkey_manager.py   – GTK4 Hotkey Manager and Keybinding Editor
├── config_manager.py   – Central configuration, backup, and state management
└── requirements.txt    – Python package dependencies
```

### config_manager.py

Central backend library handling:
- Loading, migrating, and persisting user settings (`~/.config/hypr/settings.json`)
- Reading and mutating Waybar configuration (`JSONC`) and CSS themes
- Direct Hyprland compositor control via `hyprctl`
- Real-time hardware telemetry and diagnostic probes
- Bilingual localization (English / German) and system state synchronization
- Automated timestamped backup generation and rollback

### hotkey_manager.py

Direct parser and editor for `keybinds.lua`:
- Parses `hl.bind()` function calls and arguments
- Extracts logical categories directly from comments
- Supports live editing, adding, and deleting shortcuts
- Automated shortcut collision and conflict detection
- Automatically backs up configuration before any modifications
- 1-click restore to defaults
