#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║  Tokyo Night Hyprland – Konfigurationsverwaltung             ║
║  Liest/schreibt Waybar, Hyprland, und andere Einstellungen   ║
╚══════════════════════════════════════════════════════════════╝
"""

import json
import os
import re
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any, Optional


class ConfigManager:
    """Zentrale Konfigurationsverwaltung für alle Komponenten."""

    def __init__(self):
        self.config_dir = Path.home() / ".config"
        self.hypr_dir = self.config_dir / "hypr"
        self.waybar_dir = self.config_dir / "waybar"
        self.settings_file = self.hypr_dir / "settings" / "user_settings.json"
        self._settings_cache: Optional[dict] = None

    # ── Einstellungen laden/speichern ─────────────────────────

    def load_settings(self) -> dict:
        """Lädt die gespeicherten Benutzereinstellungen."""
        if self._settings_cache is not None:
            return self._settings_cache

        defaults = self._default_settings()

        if self.settings_file.exists():
            try:
                with open(self.settings_file, "r", encoding="utf-8") as f:
                    saved = json.load(f)
                # Merge: defaults als Basis, gespeicherte Werte überschreiben
                merged = self._deep_merge(defaults, saved)
                self._settings_cache = merged
                return merged
            except (json.JSONDecodeError, OSError) as e:
                print(f"Warnung: Einstellungen konnten nicht geladen werden: {e}")

        self._settings_cache = defaults
        return defaults

    def save_settings(self, settings: dict) -> bool:
        """Speichert die Benutzereinstellungen."""
        try:
            self.settings_file.parent.mkdir(parents=True, exist_ok=True)
            with open(self.settings_file, "w", encoding="utf-8") as f:
                json.dump(settings, f, indent=2, ensure_ascii=False)
            self._settings_cache = settings
            return True
        except OSError as e:
            print(f"Fehler beim Speichern: {e}")
            return False

    def update_setting(self, section: str, key: str, value: Any) -> bool:
        """Aktualisiert eine einzelne Einstellung."""
        settings = self.load_settings()
        if section not in settings:
            settings[section] = {}
        settings[section][key] = value
        return self.save_settings(settings)

    # ── Waybar-Konfiguration ──────────────────────────────────

    def load_waybar_config(self) -> dict:
        """Lädt die Waybar-Konfiguration."""
        config_file = self.waybar_dir / "config.jsonc"
        if not config_file.exists():
            return {}
        try:
            content = config_file.read_text(encoding="utf-8")
            # JSONC: Zeilenkommentare entfernen
            content = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
            return json.loads(content)
        except (json.JSONDecodeError, OSError) as e:
            print(f"Fehler beim Laden der Waybar-Konfiguration: {e}")
            return {}

    def save_waybar_config(self, config: dict) -> bool:
        """Speichert die Waybar-Konfiguration als JSONC."""
        config_file = self.waybar_dir / "config.jsonc"
        try:
            self._backup_file(config_file)
            content = json.dumps(config, indent=4, ensure_ascii=False)
            config_file.write_text(content, encoding="utf-8")
            return True
        except OSError as e:
            print(f"Fehler beim Speichern der Waybar-Konfiguration: {e}")
            return False

    def restart_waybar(self) -> bool:
        """Startet Waybar sicher neu."""
        script = self.hypr_dir / "scripts" / "waybar-restart.sh"
        if script.exists():
            try:
                subprocess.Popen(["bash", str(script)],
                                 stdout=subprocess.DEVNULL,
                                 stderr=subprocess.DEVNULL)
                return True
            except OSError:
                pass

        # Fallback
        try:
            subprocess.run(["pkill", "-x", "waybar"],
                           capture_output=True, timeout=3)
            subprocess.Popen(["waybar"],
                             stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
            return True
        except (OSError, subprocess.TimeoutExpired):
            return False

    # ── Hyprland-Einstellungen ────────────────────────────────

    def reload_hyprland(self) -> bool:
        """Lädt die Hyprland-Konfiguration neu."""
        try:
            result = subprocess.run(
                ["hyprctl", "reload"],
                capture_output=True, text=True, timeout=5
            )
            return result.returncode == 0
        except (OSError, subprocess.TimeoutExpired):
            return False

    def get_hyprland_version(self) -> str:
        """Gibt die Hyprland-Version zurück."""
        try:
            result = subprocess.run(
                ["hyprctl", "version"],
                capture_output=True, text=True, timeout=3
            )
            if result.returncode == 0:
                return result.stdout.strip().split("\n")[0]
        except (OSError, subprocess.TimeoutExpired):
            pass
        return "Unbekannt"

    def get_monitors(self) -> list:
        """Gibt die verfügbaren Monitore zurück."""
        try:
            result = subprocess.run(
                ["hyprctl", "monitors", "-j"],
                capture_output=True, text=True, timeout=3
            )
            if result.returncode == 0:
                return json.loads(result.stdout)
        except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError):
            pass
    # ── Wallpaper-Verwaltung ─────────────────────────────────

    def get_wallpaper_dirs(self) -> list[Path]:
        """Gibt die überwachten Wallpaper-Verzeichnisse zurück."""
        dirs = [self.hypr_dir / "wallpapers", Path.home() / "Pictures" / "wallpapers"]
        return [d for d in dirs if d.exists()]

    def get_wallpapers(self) -> list[dict]:
        """Sammelt alle verfügbaren Wallpaper inklusive Wallpaper-Bank."""
        wallpapers = []
        valid_exts = {".jpg", ".jpeg", ".png", ".webp"}
        current_file = self.hypr_dir / "wallpapers" / "current.jpg"
        current_size = current_file.stat().st_size if current_file.exists() else None

        seen_paths = set()
        for folder in self.get_wallpaper_dirs():
            for root, _, files in os.walk(folder):
                for f in sorted(files):
                    path = Path(root) / f
                    if path.suffix.lower() in valid_exts and path.name != "current.jpg":
                        resolved = str(path.resolve())
                        if resolved in seen_paths:
                            continue
                        seen_paths.add(resolved)

                        is_current = False
                        if current_size is not None:
                            try:
                                is_current = (path.stat().st_size == current_size and
                                              path.name != "current.jpg")
                            except OSError:
                                pass

                        wallpapers.append({
                            "path": str(path),
                            "name": path.stem,
                            "filename": path.name,
                            "folder": path.parent.name,
                            "is_current": is_current,
                            "is_bank": "Wallpaper-Bank" in str(path),
                        })

        return sorted(wallpapers, key=lambda w: (not w["is_current"], w["name"].lower()))

    def set_wallpaper(self, wallpaper_path: str) -> bool:
        """Aktiviert das angegebene Wallpaper für Hyprpaper und das System."""
        src = Path(wallpaper_path)
        if not src.exists():
            return False

        target = self.hypr_dir / "wallpapers" / "current.jpg"
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, target)

            # Hyprpaper neu laden
            try:
                subprocess.run(["hyprctl", "hyprpaper", "unload", "all"],
                               capture_output=True, timeout=3)
                subprocess.run(["hyprctl", "hyprpaper", "preload", str(target)],
                               capture_output=True, timeout=3)
                subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f", {target}"],
                               capture_output=True, timeout=3)
            except (OSError, subprocess.TimeoutExpired):
                pass

            # swww falls vorhanden
            try:
                subprocess.run(["swww", "img", str(target), "--transition-type", "wipe"],
                               capture_output=True, timeout=3)
            except (OSError, subprocess.TimeoutExpired):
                pass

            return True
        except OSError as e:
            print(f"Fehler beim Setzen des Wallpapers: {e}")
            return False

    def sync_wallpaper_bank(self) -> tuple[bool, str]:
        """Klont oder aktualisiert die JaKooLit Wallpaper-Bank."""
        bank_dir = self.hypr_dir / "wallpapers" / "Wallpaper-Bank"
        repo_url = "https://github.com/JaKooLit/Wallpaper-Bank.git"

        try:
            bank_dir.parent.mkdir(parents=True, exist_ok=True)
            if not (bank_dir / ".git").exists():
                res = subprocess.run(
                    ["git", "clone", "--depth", "1", repo_url, str(bank_dir)],
                    capture_output=True, text=True, timeout=120
                )
                if res.returncode == 0:
                    return True, "JaKooLit Wallpaper-Bank erfolgreich heruntergeladen!"
                return False, f"Git-Fehler: {res.stderr}"
            else:
                res = subprocess.run(
                    ["git", "-C", str(bank_dir), "pull", "--ff-only"],
                    capture_output=True, text=True, timeout=60
                )
                if res.returncode == 0:
                    return True, "Wallpaper-Bank aktualisiert!"
                return False, f"Update-Fehler: {res.stderr}"
        except (OSError, subprocess.TimeoutExpired) as e:
            return False, str(e)

    # ── Backup ────────────────────────────────────────────────

    def create_backup(self, label: str = "settings") -> Optional[str]:
        """Erstellt ein Backup der aktuellen Konfiguration."""
        backup_base = self.config_dir / "tokyo-hypr-backup"
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        backup_dir = backup_base / f"{label}_{timestamp}"

        try:
            backup_dir.mkdir(parents=True, exist_ok=True)
            for name in ["hypr", "waybar"]:
                src = self.config_dir / name
                if src.exists():
                    shutil.copytree(src, backup_dir / name, dirs_exist_ok=True)
            return str(backup_dir)
        except OSError as e:
            print(f"Backup-Fehler: {e}")
            return None

    # ── Hilfsfunktionen ───────────────────────────────────────

    def _backup_file(self, path: Path):
        """Erstellt eine .bak-Kopie einer Datei."""
        if path.exists():
            bak = path.with_suffix(path.suffix + ".bak")
            shutil.copy2(path, bak)

    def _deep_merge(self, base: dict, override: dict) -> dict:
        """Verschmilzt zwei Dicts rekursiv."""
        result = base.copy()
        for key, value in override.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge(result[key], value)
            else:
                result[key] = value
        return result

    def _default_settings(self) -> dict:
        """Gibt die Standard-Einstellungen zurück."""
        return {
            "clock": {
                "format_24h": True,
                "show_date": False,
                "date_format": "%d.%m.%Y",
                "show_seconds": False,
                "show_timezone": False,
                "tooltip_enabled": True,
                "tooltip_format": "calendar",
            },
            "performance": {
                "show_cpu": True,
                "show_ram": True,
                "show_gpu": False,
                "show_temperature": True,
                "show_network_speed": True,
                "update_interval": 5,
                "compact_mode": False,
                "warning_cpu_threshold": 80,
                "warning_ram_threshold": 85,
                "warning_temp_threshold": 85,
                "tooltip_details": True,
            },
            "waybar": {
                "position": "top",
                "height": 36,
                "margin_top": 4,
                "margin_sides": 8,
                "show_tray": True,
                "font_size": 13,
                "transparency": 0.85,
                "compact_mode": False,
            },
            "audio": {
                "show_volume": True,
                "show_microphone": True,
                "step_size": 5,
            },
            "network": {
                "show_speed": True,
                "show_ip": False,
            },
            "appearance": {
                "color_profile": "tokyo-night",
                "border_size": 2,
                "gaps_in": 4,
                "gaps_out": 8,
                "rounding": 8,
                "blur_enabled": True,
                "blur_size": 4,
                "blur_passes": 2,
                "shadow_enabled": True,
                "active_opacity": 1.0,
                "inactive_opacity": 0.92,
                "animations_enabled": True,
            },
        }
