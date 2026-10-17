# Tokyo Night Hyprland Dots

<p align="center">
  <img src="assets/sddm/tokyo-night/background.png" alt="Tokyo Night Hyprland" width="800" style="border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.5);" />
</p>

<p align="center">
  <strong>A complete, highly polished, and minimalist Hyprland desktop environment themed with Tokyo Night for Arch Linux.</strong>
</p>

<p align="center">
  <a href="https://archlinux.org"><img src="https://img.shields.io/badge/OS-Arch_Linux-1793D1?logo=arch-linux&logoColor=white" alt="Arch Linux" /></a>
  <a href="https://hyprland.org"><img src="https://img.shields.io/badge/WM-Hyprland-00FFFF?logo=hyprland&logoColor=black" alt="Hyprland" /></a>
  <a href="https://github.com/enkia/tokyo-night-vscode-theme"><img src="https://img.shields.io/badge/Theme-Tokyo_Night-7aa2f7" alt="Tokyo Night" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" /></a>
  <a href="https://github.com/venox21/arch-hyprland"><img src="https://img.shields.io/github/stars/venox21/arch-hyprland?style=flat&color=bb9af7" alt="Stars" /></a>
</p>

---

> **Language / Sprache:** **[🇬🇧 English](README.md)** | [🇩🇪 Deutsch](README_DE.md)

---

## ✨ Features

- 🎨 **Unified Tokyo Night Aesthetic** – Cohesive color scheme applied across Hyprland, Waybar, SwayNC, Rofi, Kitty, SDDM, GTK4, and terminal tools.
- 🖥 **Modular Lua Hyprland Configuration** – Clean, maintainable, and easily extensible configuration divided by domain (monitors, binds, rules, animations, effects).
- 📊 **Waybar with Custom Layouts** – Pre-configured layouts including **Classic** and **Crystal Clear** (glassmorphism design with live alpha transparency controls).
- ⚙️ **GTK4 / Libadwaita Settings App** – Complete visual control center for animations, borders, blur, wallpapers, layouts, hardware telemetry, and real-time network/Bluetooth toggles.
- 🌐 **First-Class Bilingual Support (i18n)** – Full English and German support selectable during installation or toggled on the fly in the Settings App.
- 🔔 **SwayNC Control Center** – Quick access panel for Wi-Fi SSID status, Bluetooth connections, Night Light (4000K), Power Saver, GameMode, and media player controls.
- ⌨️ **Integrated Hotkey Manager** – Inspect, search, edit, and detect conflicts in your keybindings directly from a visual interface.
- 📸 **Tokyo Shot (Screenshot Manager & Annotation Editor)** – Native GTK4/Cairo screenshot tool with 4 capture modes, arrow/pen/rectangle annotations, blur/censor tools, picture-in-picture pin, and delay timers.
- 🛠 **Automated Hardware & Driver Engine (`./hardware-check.sh`)** – Idempotent detection and automated setup for AMD/Intel CPU microcode, NVIDIA DKMS & Wayland flags, Mesa/RADV drivers, and laptop battery management (`brightnessctl`, `auto-cpufreq`/`tlp`).
- 🎮 **GameMode / Maximum FPS Switch** – One-click toggle (`SUPER + F1` or SwayNC) to disable all compositor effects, enable tearing, and switch CPU governors to performance.
- 🧹 **Arch System Cleaner** – Clean Pacman/AUR caches, remove orphaned packages, trim journal logs, and audit systemd health in 1 click.
- 📦 **Interactive TUI App Installer (`./install-apps.sh`)** – Multi-select terminal installer for daily browsers, media suites, developer tools, and an optional **Cyber Security & Pentesting Suite** (Burp Suite, Wireshark, Metasploit, Ghidra, BlackArch repository).
- 🖼 **JaKooLit Wallpaper-Bank Integration** – Visual Rofi thumbnail browser and GTK previewer with access to over 150+ wallpapers.
- 🔒 **Sleek SDDM & Hyprlock** – Custom minimalist SDDM login screen with thin typography, smooth animations, and caps-lock indicators.
- 💾 **Reliable Backup & Restore** – Automated timestamped configuration backups with seamless 1-command rollback.

---

## 📋 Prerequisites

- **Arch Linux** (installed and running)
- Active internet connection
- Standard user with `sudo` privileges
- Base system utilities (`git`, `base-devel`)

---

## 🚀 Installation

Clone the repository and run the automated installer:

```bash
# 1. Clone the repository
git clone https://github.com/venox21/arch-hyprland.git
cd arch-hyprland

# 2. Run pre-install configuration tests (optional)
bash tests/test-config.sh
bash tests/test-install.sh

# 3. Launch the automated installer
chmod +x install.sh
./install.sh
```

### What the installer does:
1. **Language & Keyboard Selection**: Choose your preferred language (English or German) and keymap.
2. **System Health Check**: Verifies Arch Linux environment, internet access, and package manager state.
3. **Automated Backup**: Creates a timestamped backup of any existing configs in `~/.config/hypr/backups/`.
4. **Package Installation**: Installs Hyprland, Waybar, SwayNC, Rofi, Kitty, SDDM, audio/network utilities, and dependencies via `pacman` and `yay`.
5. **Configuration Deployment**: Symlinks or copies modular configurations and assets.
6. **Hardware & Driver Optimization**: Automatically checks CPU microcode, GPU drivers (NVIDIA/AMD/Intel), and laptop power management.
7. **Service Activation**: Enables SDDM, NetworkManager, Bluetooth, and audio daemons.
8. **Final Validation**: Verifies file integrity and prompts for a clean reboot.

---

## 🏁 Post-Installation & First Steps

After rebooting into your new Tokyo Night Hyprland desktop:

```bash
# 1. Run system doctor to verify all components and services
./doctor.sh

# 2. Re-run hardware & driver inspection if hardware changed
./hardware-check.sh

# 3. Launch the interactive App & Security Tool Installer (optional)
./install-apps.sh
```

---

## 📦 Interactive TUI App Installer

Run `./install-apps.sh` (or `~/.config/hypr/scripts/app-installer.sh`) at any time to install curated applications using an interactive terminal interface (navigate with arrow keys, toggle with <kbd>Space</kbd>, confirm with <kbd>Enter</kbd>):

| Category | Available Applications |
| :--- | :--- |
| **Browsers & Communication** | Google Chrome, Zen Browser, Discord, Vesktop (Wayland Discord with screenshare fix) |
| **Media & Gaming** | Steam, Heroic Games Launcher (Epic, GOG, Amazon), Spotify (+ Spicetify theme), VLC Player |
| **Productivity** | Visual Studio Code, Obsidian, Btop System Monitor, Thunar |
| **Cyber Security & Pentesting** | **Core Bundle**: Nmap, Wireshark (non-root packet capture), Burp Suite, Gobuster, SQLmap<br>**Advanced**: Metasploit Framework, Ghidra (NSA Reverse Engineering), Aircrack-ng, Hashcat, John the Ripper, FFUF<br>**BlackArch Integration**: 1-click setup of the official BlackArch repository (2800+ hacking tools) |

---

## ⌨️ Default Keybindings

The Tokyo Night setup uses the <kbd>SUPER</kbd> (Windows) key as its main modifier.

| Keybinding | Action |
| :--- | :--- |
| `SUPER + Return` | Open Terminal (`Kitty`) |
| `SUPER + D` | Application Launcher (`Rofi`) |
| `SUPER + Q` | Close Active Window |
| `SUPER + E` | File Manager (`Thunar`) |
| `SUPER + B` | Web Browser |
| `SUPER + V` | Toggle Floating Window |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + 1..0` | Switch to Workspace 1–10 |
| `SUPER + SHIFT + 1..0` | Move Active Window to Workspace 1–10 |
| `SUPER + Arrow Keys` | Move Focus |
| `SUPER + SHIFT + Arrow Keys`| Move Active Window Position |
| `SUPER + SHIFT + S` | Tokyo Shot: Interactive Region Capture & Annotation |
| `SUPER + Print` | Tokyo Shot: Active Window Capture |
| `Print` | Tokyo Shot: Fullscreen Capture |
| `SUPER + ALT + S` | Open Tokyo Shot Hub & Annotation Editor |
| `SUPER + SHIFT + V` | Clipboard Manager History (`cliphist` + `Rofi`) |
| `SUPER + SHIFT + X` | Lock Screen (`Hyprlock`) |
| `SUPER + SHIFT + E` | Power / Logout Menu |
| `SUPER + I` | Desktop Settings App (GTK4 / Libadwaita) |
| `SUPER + N` | Open/Close Control Center & Notifications (`SwayNC`) |
| `SUPER + SHIFT + N` | Toggle Do Not Disturb (DND) |
| `SUPER + SHIFT + K` | Open Hotkey Manager GUI |
| `SUPER + W` | Wallpaper Selector (Rofi Visual Grid) |
| `SUPER + ALT + W` | Set Random Wallpaper |
| `SUPER + SHIFT + R` | Reload Hyprland Configuration |
| `SUPER + SHIFT + B` | Restart Waybar |
| `SUPER + F1` | Toggle GameMode / Performance Mode (Max FPS) |

*All keybindings can be searched, edited, or expanded via the Hotkey Manager (`SUPER + SHIFT + K`).*

---

## 🔔 SwayNC Control Center

The built-in Control Center provides immediate access to essential system controls:
- **How to open**: Click the bell icon in Waybar or press `SUPER + N` (Right-click or `SUPER + SHIFT + N` for instant DND toggle).
- **Wi-Fi**: Live connected SSID indicator and 1-click network switcher (`nm-connection-editor` / `nmtui`).
- **Bluetooth**: Connected device status and adapter management via Blueman.
- **Audio Output**: Volume controls and instant mixer launch.
- **Night Light**: Warm color temperature toggle (4000K).
- **Theme Settings**: 1-click shortcut to the GTK4 Tokyo Night Settings App.
- **Power Saver**: Temporarily disables animations, shadows, and blur for maximum battery life on laptops.
- **GameMode**: Disables all compositor effects and gaps, enables tearing, and sets CPU governor to performance.
- **System Cleaner**: 1-click maintenance tool to free disk space and clean caches.
- **Notifications & Media**: Notification grouping, bulk clear, volume/brightness sliders, and MPRIS player controls.

---

## 🖼 Wallpapers & JaKooLit Wallpaper-Bank

The setup comes pre-bundled with Tokyo Night wallpapers and deep integration with the **[JaKooLit Wallpaper-Bank](https://github.com/JaKooLit/Wallpaper-Bank)**:

1. **Visual Thumbnail Selector (`SUPER + W`)**:
   - Rofi grid with thumbnail previews cached in `~/.cache/wallpaper-thumbs/`.
   - Includes quick-action tiles for *Random Wallpaper* and *Sync Wallpaper-Bank*.
2. **Synchronize Wallpaper-Bank**:
   - Direct option in Rofi selector (`SUPER + W` -> *📥 Sync Wallpaper-Bank*).
   - Via terminal: `~/.config/hypr/scripts/wallpaper.sh --sync`.
   - Directly within the GTK4 Settings App under the **Wallpapers** tab.
3. **Custom Wallpapers**:
   - Drop your own images (`.png`, `.jpg`, `.jpeg`, `.webp`) into `~/.config/hypr/wallpapers/` or `~/Pictures/wallpapers/`. Thumbnails are generated automatically.

---

## ⚙️ Settings App & Hotkey Manager

Launch via:
- Waybar gear icon (`⚙`)
- Keyboard shortcut: `SUPER + I`
- Terminal: `~/.config/hypr/scripts/settings.sh` or `python3 ~/.config/hypr/settings/app.py`

### Key Settings Categories:
- **Language & Region**: Live switching between English and German.
- **Hardware & Drivers**: Real-time CPU, GPU, NVIDIA Wayland status, battery telemetry, and 1-click system diagnostics.
- **Network & Bluetooth**: Real-time Wi-Fi and Bluetooth switches and status monitors.
- **Bar Style & Layout**: Switch between Waybar layouts (*Classic*, *Crystal Clear*) and adjust background transparency with live CSS reloading.
- **Effects & Blur**: Granular controls for Hyprland window decorations, rounded corners, gaps, blur passes, and animations.
- **Monitor Management**: Visual multi-monitor arrangement, resolution, refresh rate, and positioning.

---

## 🖥 Monitor Configuration

Monitor configurations are managed via `~/.config/hypr/monitors.lua` (or graphically via the Settings App):

```lua
-- Run 'hyprctl monitors' to inspect connected display outputs
hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@144",
    position = "0x0",
    scale    = "1",
})
```

---

## 🔄 Updating & Synchronizing

To pull upstream improvements and sync configuration files:

```bash
git pull
./update.sh
```

`update.sh` synchronizes config files, updates theme permissions, refreshes icons, and restarts Waybar and SwayNC smoothly.

---

## 🛠 Troubleshooting

```bash
# Run the automated system diagnostics script
./doctor.sh

# View live Hyprland compositor logs
hyprctl logs  # or alias 'hypr-logs' in zsh

# Reload Hyprland configuration on the fly
hyprctl reload

# Restart Waybar
~/.config/hypr/scripts/waybar-restart.sh

# Restore a previous backup
./restore-backup.sh
```

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!
- Check existing issues or file a new one via [GitHub Issues](https://github.com/venox21/arch-hyprland/issues).
- Pull requests are appreciated. Please follow the existing modular script and configuration conventions.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
