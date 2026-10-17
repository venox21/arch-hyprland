# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Waybar Layout "Crystal Clear"** (`config/waybar/layouts/crystal/`): Glassmorphism aesthetic with bright border, subtle shine, and text shadows; classic layout remains selectable.
- **Waybar Transparency Slider** (Settings → Bar Style and Appearance): Slider and percentage field (0% = opaque, 100% = fully transparent), applied live via CSS reload and saved per layout.
- **Tokyo Shot Native Screenshot Hub** (`screenshot/`, `scripts/tokyo-shot`): Modern GTK4/libadwaita screenshot suite with 4 capture modes, Cairo annotation editor (pen, arrows, rectangles, blur/censor, PiP pin), Tokyo Night palette, delay timers, and clipboard integration.
- **Interactive TUI App Installer** (`install-apps.sh`, `scripts/app-installer.sh`): Terminal installer with yay/gum auto-provisioning, multi-select checkboxes, everyday apps, and a complete Cyber Security / Pentesting suite (Burp Suite, Wireshark, Metasploit, Ghidra, BlackArch repository).
- **GameMode Performance Toggle** (`scripts/gamemode.sh`, Hotkey: `SUPER + F1`, Control Center): Temporarily disables compositor effects (blur, shadows, animations, gaps), enables tearing, and sets CPU governor to performance for maximum gaming FPS.
- **Arch System Cleaner** (`scripts/clean-system.sh`, Control Center, Rofi): 1-click maintenance cleaning pacman/yay caches, removing orphans (`pacman -Qtdq`), vacuuming systemd journals, and auditing system health.
- **Automated Hardware & Driver Engine** (`hardware-check.sh`, `scripts/hardware-check.sh`, Rofi): Idempotent detection and setup for CPU microcode (AMD/Intel), GPU drivers (NVIDIA DKMS/Wayland flags, AMD/Intel Mesa/RADV), and laptop battery management (`brightnessctl`, `auto-cpufreq`/`tlp`).
- **Hardware & Drivers Center in Settings** (`settings/app.py`, `settings/config_manager.py`): Real-time hardware telemetry display (CPU, GPU, battery, RAM) and 1-click diagnostic/installer actions.
- **Native Network & Bluetooth Controls in Settings**: Live connection status, Wi-Fi toggles, NetworkManager GUI integration, and Bluetooth adapter power switch with device pairing.
- **Language & Region Selector in Settings**: Live language switching between English and German with instant UI updates and system synchronization.

### Changed
- **SDDM Login Screen Redesign** (`assets/sddm/tokyo-night/Main.qml`): Modern minimalist layout with thin clock, user avatar, pill password input, error shake animation, caps-lock warning, session selector, and power controls.
- **Waybar Layer Rule**: Adjusted `ignore_alpha` from 0.3 to 0.01 so blur remains visible even on highly transparent bars.
- **Waybar Opacity Management**: Replaced inactive `waybar.transparency` setting with `waybar.opacity_by_layout`.

## [1.2.0] – 2026-10-11

### Added
- **SwayNC Control Center in Waybar**: Interactive quick settings panel for Wi-Fi status, Bluetooth, Audio output, Night Light, Theme shortcuts, and Power Saver.
- **Control Center Helper Script** (`scripts/control-center.sh`): Script for quick toggles, system cleaner, and dynamic SwayNC interaction.
- **Waybar SwayNC Module**: Custom status bar module with dynamic bell and DND icons with click actions.
- **Control Center Keybindings**: `SUPER + N` to toggle panel and `SUPER + SHIFT + N` to toggle Do Not Disturb.

## [1.1.0] – 2026-10-10

### Added
- **JaKooLit Wallpaper-Bank Integration**: Clone, synchronize, and choose from over 150 wallpapers from the JaKooLit repository.
- **Visual Rofi Wallpaper Grid**: `config/rofi/wallpaper.rasi` with thumbnail previews and grid layout.
- **Wallpapers Tab in GTK4 Settings**: Live preview, 1-click activation, sync trigger, and random wallpaper action.
- **Wallpaper Keybindings**: `SUPER + W` (grid selector), `SUPER + SHIFT + W` (dots standard), and `SUPER + ALT + W` (random wallpaper).
- **Tokyo Night Starter Wallpapers**: High-resolution curated wallpapers bundled in `assets/wallpapers/`.
- **Installer Wallpaper Integration**: Optional automated installation of JaKooLit Wallpaper-Bank during Phase 5.

## [1.0.0] – 2026-10-10

### Added
- **Modular Hyprland Lua Configuration**: Clean separation of colors, keybinds, monitors, rules, animations, autostart, and input.
- **Tokyo Night Waybar**: Full status bar configuration with Tokyo Night styling and modules.
- **GTK4 Settings Application**: Comprehensive desktop configuration interface with 12 setting categories.
- **Visual Hotkey Manager**: Search, edit, add, delete, and validate keybindings with conflict detection.
- **Tokyo Night SDDM Theme**: Minimalist QML-based login screen.
- **Hyprlock Lockscreen**: Modern lockscreen with clock, date, and user greetings.
- **Tokyo Night Rofi Launcher**: Application launcher and power menu.
- **Kitty Terminal Styling**: Tokyo Night color scheme and font configurations.
- **Mako Notification Daemon**: Themed desktop notifications with urgency levels.
- **Zsh & Starship Shell**: Optimized shell configuration with aliases and cross-shell prompt.
- **Screenshot Utilities**: Fullscreen, region selection, and active window screenshot bindings.
- **Clipboard Manager**: History search and selection with cliphist and Rofi.
- **Wallpaper Engine**: Hyprpaper integration with dynamic wallpaper switching.
- **Automated Installer** (`install.sh`): 9-phase automated installer with rollback backup support.
- **Uninstaller** (`uninstall.sh`): Phase-based cleanup and uninstallation utility.
- **Backup Restoration** (`restore-backup.sh`): Interactive configuration restoration tool.
- **Doctor Diagnostics** (`doctor.sh`): Post-installation diagnostic and health check tool.
- **Automated Test Suite**: Configuration, installation, and Python unit testing suites.
