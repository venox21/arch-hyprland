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

    # ── Waybar Layout-Verwaltung ──────────────────────────────

    # default_opacity: Deckkraft (Alpha) des Leistenhintergrunds im Auslieferungszustand
    # bar_background:   False, wenn das Layout keinen eigenen Leistenhintergrund hat
    #                   (Pills/Dock) – der Transparenz-Regler wirkt dort nicht.
    WAYBAR_LAYOUTS: dict[str, dict] = {
        "classic": {
            "id": "classic",
            "name": "Tokyo Night Classic",
            "description": "Ausgewogene Leiste mit Systemmetriken und sanft abgerundeten Ecken",
            "preview": "󰂚   ⏻ | 36px Oben",
            "height": 36,
            "position": "top",
            "default_opacity": 0.85,
            "bar_background": True,
        },
        "crystal": {
            "id": "crystal",
            "name": "Crystal Clear",
            "description": "Klare Glas-Leiste mit Unschärfe, hellem Rand und stufenlos regelbarer Transparenz",
            "preview": "󰋩 Glas-Look | 36px Oben",
            "height": 36,
            "position": "top",
            "default_opacity": 0.22,
            "bar_background": True,
        },
        "pills": {
            "id": "pills",
            "name": "Floating Pills",
            "description": "Moderne schwebende Insel-Kapseln mit transparentem Hintergrund",
            "preview": "󱅫 Island-Look | 38px Schwebend",
            "height": 38,
            "position": "top",
            "default_opacity": 0.0,
            "bar_background": False,
        },
        "compact": {
            "id": "compact",
            "name": "Kompakte Top-Bar",
            "description": "Randlose, platzsparende Leiste direkt an der oberen Kante (28px)",
            "preview": "󰘔 Randlos Edge-to-Edge | 28px Oben",
            "height": 28,
            "position": "top",
            "default_opacity": 1.0,
            "bar_background": True,
        },
        "minimal": {
            "id": "minimal",
            "name": "Minimalist",
            "description": "Clean & ablenkungsfrei – nur Workspaces, Uhr, Audio & Benachrichtigungen",
            "preview": "󰍹 Aufgeräumt ohne CPU/RAM | 32px Schwebend",
            "height": 32,
            "position": "top",
            "default_opacity": 0.82,
            "bar_background": True,
        },
        "dock": {
            "id": "dock",
            "name": "Floating Bottom Dock",
            "description": "Elegantes schwebendes Dock am unteren Bildschirmrand (40px)",
            "preview": "󰞌 Dock am unteren Rand | 40px Unten",
            "height": 40,
            "position": "bottom",
            "default_opacity": 0.0,
            "bar_background": False,
        },
    }

    # Untergrenze der Deckkraft: Bei 0 würde Hyprland die Leiste nicht mehr
    # unscharf zeichnen (Layer-Regel ignore_alpha), daher bleibt ein Rest übrig.
    WAYBAR_MIN_OPACITY = 0.02

    # Erster window#waybar-Block mit einer background-Angabe (rgba/hex/transparent)
    _BAR_BG_RE = re.compile(
        r"(window#waybar\s*\{[^}]*?\bbackground(?:-color)?\s*:\s*)"
        r"(rgba?\([^)]*\)|#[0-9a-fA-F]{3,8}|transparent)(\s*;)",
        re.DOTALL,
    )

    @staticmethod
    def _css_color_to_rgb(token: str) -> tuple[int, int, int]:
        """Liest die RGB-Anteile aus einem CSS-Farbwert (rgb(a) oder #hex)."""
        token = token.strip()
        if token.startswith("#"):
            h = token[1:]
            if len(h) in (3, 4):
                h = "".join(ch * 2 for ch in h)
            return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
        nums = re.findall(r"[\d.]+", token)
        return int(float(nums[0])), int(float(nums[1])), int(float(nums[2]))

    @classmethod
    def set_css_bar_opacity(cls, css: str, opacity: float) -> tuple[str, bool]:
        """Setzt den Alpha-Wert des Leistenhintergrunds (window#waybar) in einer CSS.

        Gibt (neue_css, geändert) zurück. Hat die Leiste keinen eigenen
        Hintergrund (transparent), bleibt die CSS unverändert.
        """
        opacity = max(cls.WAYBAR_MIN_OPACITY, min(1.0, float(opacity)))
        match = cls._BAR_BG_RE.search(css)
        if not match or match.group(2) == "transparent":
            return css, False

        r, g, b = cls._css_color_to_rgb(match.group(2))
        new_value = f"rgba({r}, {g}, {b}, {opacity:.2f})"
        new_css = css[:match.start(2)] + new_value + css[match.end(2):]
        return new_css, True

    def get_waybar_opacity(self, layout_id: Optional[str] = None) -> float:
        """Gespeicherte Deckkraft (0.0–1.0) des Leistenhintergrunds für ein Layout."""
        layout_id = layout_id or self.get_active_waybar_layout()
        meta = self.WAYBAR_LAYOUTS.get(layout_id, {})
        default = meta.get("default_opacity", 0.85)
        stored = self.load_settings().get("waybar", {}).get("opacity_by_layout", {})
        try:
            value = float(stored.get(layout_id, default))
        except (TypeError, ValueError):
            value = default
        return max(0.0, min(1.0, value))

    def apply_waybar_opacity(self, opacity: float, layout_id: Optional[str] = None,
                             reload: bool = True) -> bool:
        """Speichert die Deckkraft für das Layout und schreibt sie in die aktive style.css.

        Transparenz in Prozent = (1 - opacity) * 100.
        """
        layout_id = layout_id or self.get_active_waybar_layout()
        opacity = max(0.0, min(1.0, float(opacity)))

        settings = self.load_settings()
        wb = settings.setdefault("waybar", {})
        wb.setdefault("opacity_by_layout", {})[layout_id] = round(opacity, 2)
        self.save_settings(settings)

        css_file = self.waybar_dir / "style.css"
        if not css_file.exists():
            return False
        try:
            css = css_file.read_text(encoding="utf-8")
            new_css, changed = self.set_css_bar_opacity(css, opacity)
            if changed and new_css != css:
                css_file.write_text(new_css, encoding="utf-8")
                if reload:
                    self.reload_waybar_style()
            return changed
        except OSError as e:
            print(f"Fehler beim Setzen der Waybar-Transparenz: {e}")
            return False

    def reload_waybar_style(self) -> bool:
        """Lädt Waybar-CSS ohne Neustart neu (SIGUSR2), sonst Neustart."""
        try:
            result = subprocess.run(["pkill", "-SIGUSR2", "-x", "waybar"],
                                    capture_output=True, timeout=3)
            if result.returncode == 0:
                return True
        except (OSError, subprocess.TimeoutExpired):
            pass
        return self.restart_waybar()

    def get_waybar_layouts(self) -> dict:
        """Gibt alle verfügbaren Waybar-Layouts zurück."""
        return self.WAYBAR_LAYOUTS

    def get_active_waybar_layout(self) -> str:
        """Ermittelt das aktuell aktive Waybar-Layout."""
        settings = self.load_settings()
        return settings.get("waybar", {}).get("layout", "classic")

    def apply_waybar_layout(self, layout_id: str) -> tuple[bool, str]:
        """Aktiviert ein Waybar-Layout, kopiert Config & CSS und startet Waybar neu."""
        if layout_id not in self.WAYBAR_LAYOUTS:
            return False, f"Unbekanntes Layout: {layout_id}"

        # 1. Quelle ermitteln
        src_dir = self.waybar_dir / "layouts" / layout_id
        if not (src_dir / "config.jsonc").exists():
            repo_src = Path(__file__).resolve().parent.parent / "config" / "waybar" / "layouts" / layout_id
            if (repo_src / "config.jsonc").exists():
                src_dir = repo_src

        if not (src_dir / "config.jsonc").exists() or not (src_dir / "style.css").exists():
            return False, f"Dateien für Layout '{layout_id}' wurden nicht gefunden."

        try:
            self.waybar_dir.mkdir(parents=True, exist_ok=True)
            self._backup_file(self.waybar_dir / "config.jsonc")
            self._backup_file(self.waybar_dir / "style.css")

            shutil.copy2(src_dir / "config.jsonc", self.waybar_dir / "config.jsonc")
            shutil.copy2(src_dir / "style.css", self.waybar_dir / "style.css")

            meta = self.WAYBAR_LAYOUTS[layout_id]
            settings = self.load_settings()
            if "waybar" not in settings:
                settings["waybar"] = {}
            settings["waybar"]["layout"] = layout_id
            settings["waybar"]["height"] = meta["height"]
            settings["waybar"]["position"] = meta["position"]
            self.save_settings(settings)

            # Gespeicherte Transparenz dieses Layouts auf die frisch kopierte CSS anwenden
            if meta.get("bar_background", True):
                self.apply_waybar_opacity(self.get_waybar_opacity(layout_id),
                                          layout_id, reload=False)

            self.restart_waybar()
            return True, f"Waybar-Layout '{meta['name']}' erfolgreich aktiviert!"
        except OSError as e:
            return False, f"Fehler beim Aktivieren des Layouts: {e}"

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

    # ── Systemzeit, NTP & Zeitzone ───────────────────────────

    def get_timedate_info(self) -> dict:
        """Liest aktuelle Zeit-, NTP- und Zeitzoneninformationen aus."""
        info = {
            "local_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "timezone": "Europe/Berlin",
            "ntp_active": True,
            "rtc_local": False,
        }
        try:
            res = subprocess.run(["timedatectl", "status"], capture_output=True, text=True, timeout=3)
            if res.returncode == 0:
                for line in res.stdout.splitlines():
                    line = line.strip()
                    if line.startswith("Local time:"):
                        info["local_time"] = line.split("Local time:", 1)[1].strip()
                    elif line.startswith("Time zone:"):
                        tz_part = line.split("Time zone:", 1)[1].strip()
                        info["timezone"] = tz_part.split()[0] if tz_part else "Europe/Berlin"
                    elif "NTP service: active" in line or "System clock synchronized: yes" in line:
                        info["ntp_active"] = True
                    elif "NTP service: inactive" in line or "System clock synchronized: no" in line:
                        info["ntp_active"] = False
                    elif "RTC in local TZ: yes" in line:
                        info["rtc_local"] = True
        except (OSError, subprocess.TimeoutExpired):
            pass
        return info

    def _run_timedate_cmd(self, args: list[str]) -> tuple[bool, str]:
        """Führt einen timedatectl-Befehl aus und fängt Berechtigungsfehler sauber ab."""
        cmd = ["timedatectl", "--no-ask-password"] + args
        try:
            # 1. Direkter Aufruf (funktioniert sofort mit Polkit-Regel)
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=3)
            if res.returncode == 0:
                return True, ""

            # 2. Falls sudoers drop-in / sudo ohne Passwort aktiv ist
            res_sudo = subprocess.run(["sudo", "-n", "timedatectl", "--no-ask-password"] + args,
                                      capture_output=True, text=True, timeout=3)
            if res_sudo.returncode == 0:
                return True, ""

            # 3. pkexec versuchen
            res_pk = subprocess.run(["pkexec", "timedatectl", "--no-ask-password"] + args,
                                    capture_output=True, text=True, timeout=5)
            if res_pk.returncode == 0:
                return True, ""

            raw_err = (res.stderr or res_sudo.stderr or res_pk.stderr or "").strip()
            if "Interactive authentication required" in raw_err or "Not authorized" in raw_err:
                return False, (
                    "Berechtigung erforderlich: Bitte führe im Terminal einmal './update.sh' aus, "
                    "um die Berechtigung für deine Benutzergruppe freizuschalten."
                )
            if "Automatic time synchronization is enabled" in raw_err:
                return False, (
                    "Automatische Zeitsynchronisation (NTP) ist noch aktiv. "
                    "Bitte zuerst den Schalter 'Automatische Uhrzeit (NTP)' ausschalten."
                )
            return False, raw_err or "Fehler beim Ausführen von timedatectl."
        except subprocess.TimeoutExpired:
            return False, "Zeitüberschreitung: timedatectl reagiert nicht."
        except OSError as e:
            return False, str(e)

    def set_ntp(self, enabled: bool) -> tuple[bool, str]:
        """Aktiviert oder deaktiviert NTP (automatische Zeitsynchronisation)."""
        val = "true" if enabled else "false"
        ok, err = self._run_timedate_cmd(["set-ntp", val])
        if ok:
            return True, f"NTP {'aktiviert' if enabled else 'deaktiviert'}"
        return False, err

    def set_timezone(self, tz: str) -> tuple[bool, str]:
        """Setzt die Systemzeitzone."""
        current = self.get_timedate_info().get("timezone", "")
        if current == tz:
            return True, f"Zeitzone ist bereits {tz}"

        ok, err = self._run_timedate_cmd(["set-timezone", tz])
        if ok:
            return True, f"Zeitzone auf {tz} gesetzt"

        # Fallback: symlink /etc/localtime
        zone_file = Path(f"/usr/share/zoneinfo/{tz}")
        if zone_file.exists():
            res = subprocess.run(["sudo", "-n", "ln", "-sf", str(zone_file), "/etc/localtime"],
                                 capture_output=True, text=True, timeout=3)
            if res.returncode == 0:
                return True, f"Zeitzone auf {tz} gesetzt"

        return False, err

    def set_system_time(self, time_str: str) -> tuple[bool, str]:
        """Setzt die Systemzeit manuell (deaktiviert zuvor NTP)."""
        time_str = time_str.strip()
        if re.match(r'^\d{1,2}:\d{2}$', time_str):
            time_str = f"{time_str}:00"
        elif re.match(r'^\d{1,2}:\d{2}:\d{2}$', time_str):
            parts = time_str.split(":")
            time_str = f"{int(parts[0]):02d}:{int(parts[1]):02d}:{int(parts[2]):02d}"

        # Vor manuellem Setzen NTP ausschalten
        self.set_ntp(False)

        ok, err = self._run_timedate_cmd(["set-time", time_str])
        if ok:
            return True, f"Uhrzeit auf {time_str} gesetzt"

        # Fallback mit date -s
        res = subprocess.run(["sudo", "-n", "date", "-s", time_str],
                             capture_output=True, text=True, timeout=3)
        if res.returncode == 0:
            subprocess.run(["sudo", "-n", "hwclock", "--systohc"],
                           capture_output=True, text=True, timeout=3)
            return True, f"Uhrzeit auf {time_str} gesetzt"

        return False, err

    def set_rtc_mode(self, local_tz: bool) -> tuple[bool, str]:
        """Konfiguriert Hardware-Uhr (RTC)."""
        val = "1" if local_tz else "0"
        ok, err = self._run_timedate_cmd(["set-local-rtc", val, "--adjust-system-clock"])
        if ok:
            return True, "RTC-Modus aktualisiert"
        return False, err

    # ── Eingabegeräte (Maus, Touchpad, Tastaturlayout) ───────

    def load_input_settings(self) -> dict:
        """Lädt die aktuellen Tastatur- und Mauseinstellungen."""
        settings = self.load_settings().get("input", {})
        defaults = self._default_settings()["input"]
        return self._deep_merge(defaults, settings)

    def save_input_settings(self, inp: dict) -> bool:
        """Speichert Tastatur- und Mauseinstellungen und aktualisiert input.lua."""
        self.update_setting("input", "kb_layout", inp.get("kb_layout", "de"))
        self.update_setting("input", "kb_variant", inp.get("kb_variant", ""))
        self.update_setting("input", "sensitivity", inp.get("sensitivity", 0.0))
        self.update_setting("input", "natural_scroll", inp.get("natural_scroll", True))
        self.update_setting("input", "tap_to_click", inp.get("tap_to_click", True))
        self.update_setting("input", "disable_while_typing", inp.get("disable_while_typing", True))

        input_file = self.hypr_dir / "input.lua"
        content = f"""-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Eingabegeräte – Tastatur, Maus, Touchpad                  ║
-- ╚══════════════════════════════════════════════════════════════╝

hl.config({{
    input = {{
        kb_layout  = "{inp.get('kb_layout', 'de')}",
        kb_variant = "{inp.get('kb_variant', '')}",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity = {inp.get('sensitivity', 0.0):.2f},

        repeat_rate  = 25,
        repeat_delay = 600,

        touchpad = {{
            natural_scroll    = {'true' if inp.get('natural_scroll', True) else 'false'},
            disable_while_typing = {'true' if inp.get('disable_while_typing', True) else 'false'},
            tap_to_click      = {'true' if inp.get('tap_to_click', True) else 'false'},
            drag_lock         = false,
            scroll_factor     = 1.0,
        }},
    }},

    cursor = {{
        no_hardware_cursors = false,
        inactive_timeout    = 5,
    }},
}})

hl.gesture({{
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
}})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
"""
        try:
            input_file.parent.mkdir(parents=True, exist_ok=True)
            self._backup_file(input_file)
            input_file.write_text(content, encoding="utf-8")

            # Sofort per hyprctl anwenden
            try:
                subprocess.run(["hyprctl", "keyword", "input:kb_layout", inp.get("kb_layout", "de")], capture_output=True, timeout=2)
                subprocess.run(["hyprctl", "keyword", "input:kb_variant", inp.get("kb_variant", "")], capture_output=True, timeout=2)
                subprocess.run(["hyprctl", "keyword", "input:sensitivity", str(inp.get("sensitivity", 0.0))], capture_output=True, timeout=2)
                subprocess.run(["hyprctl", "keyword", "input:touchpad:natural_scroll", "true" if inp.get("natural_scroll", True) else "false"], capture_output=True, timeout=2)
                subprocess.run(["hyprctl", "keyword", "input:touchpad:tap-to-click", "true" if inp.get("tap_to_click", True) else "false"], capture_output=True, timeout=2)
            except (OSError, subprocess.TimeoutExpired):
                pass
            return True
        except OSError as e:
            print(f"Fehler beim Speichern von input.lua: {e}")
            return False

    # ── Monitore & Bildschirme ─────────────────────────────────

    def save_monitor_config(self, output: str, width: int, height: int, hz: int, scale: float) -> bool:
        """Speichert Monitoreinstellungen in monitors.lua und wendet sie an."""
        mon_file = self.hypr_dir / "monitors.lua"
        mode_str = f"{width}x{height}@{hz}" if width > 0 and height > 0 and hz > 0 else "preferred"
        scale_str = f"{scale:.2f}" if scale > 0 else "1"

        content = f"""-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Monitor-Konfiguration                                      ║
-- ║  Automatische Erkennung + individuelle Profile              ║
-- ╚══════════════════════════════════════════════════════════════╝

hl.monitor({{
    output   = "{output}",
    mode     = "{mode_str}",
    position = "auto",
    scale    = "{scale_str}",
}})
"""
        try:
            mon_file.parent.mkdir(parents=True, exist_ok=True)
            self._backup_file(mon_file)
            mon_file.write_text(content, encoding="utf-8")

            try:
                mon_arg = f"{output},{mode_str},auto,{scale_str}" if output else f",{mode_str},auto,{scale_str}"
                subprocess.run(["hyprctl", "keyword", "monitor", mon_arg], capture_output=True, timeout=3)
            except (OSError, subprocess.TimeoutExpired):
                pass
            return True
        except OSError as e:
            print(f"Fehler beim Speichern von monitors.lua: {e}")
            return False

    # ── Tokyo Night Farbvarianten ──────────────────────────────

    THEME_PALETTES = {
        "classic": {
            "name": "Tokyo Night Classic (Blau & Lila)",
            "primary": "#7aa2f7",
            "secondary": "#bb9af7",
            "rgba_primary": "rgba(7aa2f7ee)",
            "rgba_secondary": "rgba(bb9af7ee)",
        },
        "storm": {
            "name": "Tokyo Night Storm (Cyan & Blau)",
            "primary": "#7dcfff",
            "secondary": "#7aa2f7",
            "rgba_primary": "rgba(7dcfffee)",
            "rgba_secondary": "rgba(7aa2f7ee)",
        },
        "teal": {
            "name": "Tokyo Night Cyberpunk (Teal & Cyan)",
            "primary": "#73daca",
            "secondary": "#2ac3de",
            "rgba_primary": "rgba(73dacaee)",
            "rgba_secondary": "rgba(2ac3deee)",
        },
        "neon": {
            "name": "Tokyo Night Neon (Lila & Pink)",
            "primary": "#bb9af7",
            "secondary": "#f7768e",
            "rgba_primary": "rgba(bb9af7ee)",
            "rgba_secondary": "rgba(f7768eee)",
        },
        "sunset": {
            "name": "Tokyo Night Sunset (Orange & Gold)",
            "primary": "#ff9e64",
            "secondary": "#e0af68",
            "rgba_primary": "rgba(ff9e64ee)",
            "rgba_secondary": "rgba(e0af68ee)",
        },
    }

    def apply_color_theme(self, theme_key: str) -> bool:
        """Wendet ein Tokyo Night Akzentfarb-Schema an."""
        if theme_key not in self.THEME_PALETTES:
            return False
        palette = self.THEME_PALETTES[theme_key]
        self.update_setting("theme", "variant", theme_key)

        colors_file = self.hypr_dir / "colors.lua"
        content = f"""-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Tokyo Night – Zentrale Farbpalette                        ║
-- ║  Farbvariante: {palette['name']}
-- ╚══════════════════════════════════════════════════════════════╝

local M = {{}}

-- ── Hintergrund ──────────────────────────────────────────────
M.bg_dark   = "rgba(1a1b26ff)"
M.bg        = "rgba(24283bff)"
M.bg_light  = "rgba(292e42ff)"
M.bg_hl     = "rgba(33467cff)"

-- ── Vordergrund ──────────────────────────────────────────────
M.fg        = "rgba(c0caf5ff)"
M.fg_dark   = "rgba(a9b1d6ff)"
M.fg_gutter = "rgba(3b4261ff)"

-- ── Farben ───────────────────────────────────────────────────
M.red       = "rgba(f7768eff)"
M.orange    = "rgba(ff9e64ff)"
M.yellow    = "rgba(e0af68ff)"
M.green     = "rgba(9ece6aff)"
M.teal      = "rgba(73dacaff)"
M.cyan      = "rgba(7dcfffff)"
M.blue      = "rgba(7aa2f7ff)"
M.magenta   = "rgba(bb9af7ff)"
M.purple    = "rgba(9d7cd8ff)"

-- ── Rahmen und Oberflächen ───────────────────────────────────
M.border_active   = "{palette['rgba_primary']}"
M.border_inactive = "rgba(33467caa)"
M.border_locked   = "{palette['rgba_secondary']}"

-- ── Schatten ─────────────────────────────────────────────────
M.shadow = 0xee1a1b26

-- ── Gradient für aktive Rahmen ───────────────────────────────
M.border_gradient = {{
    colors = {{ "{palette['rgba_primary']}", "{palette['rgba_secondary']}" }},
    angle  = 45,
}}

-- ── Transparenzstufen ────────────────────────────────────────
M.opacity_active   = 1.0
M.opacity_inactive = 0.92
M.dim_inactive     = 0.08

return M
"""
        try:
            colors_file.parent.mkdir(parents=True, exist_ok=True)
            self._backup_file(colors_file)
            colors_file.write_text(content, encoding="utf-8")
            self.reload_hyprland()
            self.restart_waybar()
            return True
        except OSError as e:
            print(f"Fehler beim Setzen des Farbschemas: {e}")
            return False

    def apply_rofi_opacity(self, opacity: float) -> bool:
        """Passt die Transparenz der Rofi-App-Suche an."""
        opacity = max(0.2, min(1.0, float(opacity)))
        self.update_setting("appearance", "rofi_opacity", opacity)

        # Mögliche Pfade zur config.rasi
        candidates = [
            self.config_dir / "rofi" / "config.rasi",
            Path(__file__).resolve().parent.parent / "config" / "rofi" / "config.rasi",
        ]

        bg_alt_op = max(0.15, opacity - 0.17)
        modified = False

        for conf in candidates:
            if conf.exists():
                try:
                    text = conf.read_text(encoding="utf-8")
                    # bg ersetzen
                    text = re.sub(
                        r"(bg:\s*)(rgba\([^)]+\)|#[0-9a-fA-F]{6,8})",
                        f"\\g<1>rgba(26, 27, 38, {opacity:.2f})",
                        text,
                    )
                    # bg-alt ersetzen
                    text = re.sub(
                        r"(bg-alt:\s*)(rgba\([^)]+\)|#[0-9a-fA-F]{6,8})",
                        f"\\g<1>rgba(36, 40, 59, {bg_alt_op:.2f})",
                        text,
                    )
                    self._backup_file(conf)
                    conf.write_text(text, encoding="utf-8")
                    modified = True
                except OSError as e:
                    print(f"Fehler beim Aktualisieren von {conf}: {e}")

        return modified or True

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
                "layout": "classic",
                "position": "top",
                "height": 36,
                "margin_top": 4,
                "margin_sides": 8,
                "show_tray": True,
                "font_size": 13,
                "opacity_by_layout": {},
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
                "rofi_opacity": 0.72,
            },
            "input": {
                "kb_layout": "de",
                "kb_variant": "",
                "sensitivity": 0.0,
                "natural_scroll": True,
                "tap_to_click": True,
                "disable_while_typing": True,
                "follow_mouse": 1,
            },
            "monitors": {
                "profile": "auto",
                "custom": {},
            },
            "theme": {
                "variant": "classic",
            },
        }
