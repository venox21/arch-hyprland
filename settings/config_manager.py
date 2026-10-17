#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║  Tokyo Night Hyprland – Konfigurationsverwaltung             ║
║  Liest/schreibt Waybar, Hyprland, und andere Einstellungen   ║
╚══════════════════════════════════════════════════════════════╝
"""

import glob
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

    def apply_waybar_layout(self, layout_id: str, reload: bool = True) -> tuple[bool, str]:
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

            if reload:
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
                data = json.loads(result.stdout)
                if isinstance(data, list):
                    return data
        except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError):
            pass
        return []

    # ── Monitor-Modi (Auflösung / Hz) ─────────────────────────

    _MODE_RE = re.compile(r"^\s*(\d+)x(\d+)@([\d.]+)\s*(?:Hz)?\s*$", re.IGNORECASE)

    @classmethod
    def parse_monitor_modes(cls, monitor: dict) -> dict:
        """Liest `availableModes` eines Monitors aus.

        Rückgabe: {(breite, höhe): [hz, ...]} – Hz-Werte absteigend sortiert,
        Auflösungen absteigend nach Pixelanzahl. Fehlt die Liste, wird nur
        der aktuelle Modus zurückgegeben.
        """
        modes: dict = {}
        for mode in monitor.get("availableModes") or []:
            match = cls._MODE_RE.match(str(mode))
            if not match:
                continue
            res = (int(match.group(1)), int(match.group(2)))
            hz = round(float(match.group(3)), 2)
            rates = modes.setdefault(res, [])
            if hz not in rates:
                rates.append(hz)

        if not modes and monitor.get("width") and monitor.get("height"):
            modes[(int(monitor["width"]), int(monitor["height"]))] = [
                round(float(monitor.get("refreshRate", 60)), 2)
            ]

        for rates in modes.values():
            rates.sort(reverse=True)
        return dict(sorted(modes.items(), key=lambda kv: (kv[0][0] * kv[0][1], kv[0][0]), reverse=True))

    @classmethod
    def get_max_refresh(cls, monitor: dict, resolution: Optional[tuple] = None) -> float:
        """Höchste verfügbare Bildwiederholrate (optional für eine Auflösung)."""
        modes = cls.parse_monitor_modes(monitor)
        if resolution is not None:
            return max(modes.get(tuple(resolution), [0.0]), default=0.0)
        return max((max(r) for r in modes.values() if r), default=0.0)

    @staticmethod
    def format_hz(hz: float) -> str:
        """Hz-Wert lesbar formatieren (164.99 -> '165', 59.94 -> '59.94')."""
        if abs(hz - round(hz)) < 0.05:
            return f"{round(hz)}"
        return f"{hz:.2f}".rstrip("0").rstrip(".")

    # ── Monitor-Anordnung ────────────────────────────────────

    @staticmethod
    def _logical_size(entry: dict) -> tuple:
        """Logische Größe (nach Skalierung/Rotation) eines Monitor-Eintrags."""
        if entry.get("width", 0) > 0 and entry.get("height", 0) > 0:
            w, h = entry["width"], entry["height"]
        else:
            w, h = entry.get("size", (1920, 1080))
        scale = float(entry.get("scale") or 1.0)
        if scale <= 0:
            scale = 1.0
        if int(entry.get("transform", 0) or 0) % 2 == 1:
            w, h = h, w
        return max(1, round(w / scale)), max(1, round(h / scale))

    @classmethod
    def compute_monitor_positions(cls, entries: list) -> dict:
        """Berechnet absolute Positionen aus relativen Anordnungen.

        Jeder Eintrag: {name, width, height, scale, size?, transform?,
        anchor: None | {"ref": name, "side": right|left|above|below|mirror,
        "offset"?: px}}. Der Versatz (offset) verschiebt den Monitor entlang
        der berührten Kante (bei links/rechts vertikal, bei über/unter horizontal).
        Der erste Eintrag ohne Anker ist der Hauptmonitor (0x0).
        Rückgabe: {name: (x, y)}; gespiegelte Monitore erhalten die Position
        ihres Referenzmonitors.
        """
        if not entries:
            return {}
        sizes = {e["name"]: cls._logical_size(e) for e in entries}
        root = next((e for e in entries if not e.get("anchor")), entries[0])
        pos = {root["name"]: (0, 0)}
        pending = [e for e in entries if e["name"] != root["name"]]

        def place(entry, ref_name, side):
            rx, ry = pos[ref_name]
            rw, rh = sizes[ref_name]
            w, h = sizes[entry["name"]]
            off = int((entry.get("anchor") or {}).get("offset", 0) or 0)
            if side == "left":
                return (rx - w, ry + off)
            if side == "above":
                return (rx + off, ry - h)
            if side == "below":
                return (rx + off, ry + rh)
            if side == "mirror":
                return (rx, ry)
            return (rx + rw, ry + off)

        progressed = True
        while pending and progressed:
            progressed = False
            for entry in list(pending):
                anchor = entry.get("anchor")
                if anchor and anchor.get("ref") in pos and anchor["ref"] != entry["name"]:
                    pos[entry["name"]] = place(entry, anchor["ref"], anchor.get("side", "right"))
                    pending.remove(entry)
                    progressed = True

        # Übrig gebliebene (Zyklen / fehlende Referenzen): rechts anhängen
        for entry in pending:
            right_edge = max(pos[n][0] + sizes[n][0] for n in pos)
            pos[entry["name"]] = (right_edge, 0)

        min_x = min(x for x, _ in pos.values())
        min_y = min(y for _, y in pos.values())
        return {n: (x - min_x, y - min_y) for n, (x, y) in pos.items()}

    @classmethod
    def infer_anchors(cls, monitors: list) -> dict:
        """Leitet die aktuelle Anordnung aus den Hyprland-Monitordaten ab.

        Rückgabe: {name: None | {"ref": name, "side": ...}}; der Hauptmonitor
        (bei 0x0) erhält None.
        """
        if not monitors:
            return {}
        entries = []
        for m in monitors:
            entries.append({
                "name": m.get("name", ""),
                "width": int(m.get("width", 0) or 0),
                "height": int(m.get("height", 0) or 0),
                "scale": m.get("scale", 1.0),
                "transform": m.get("transform", 0),
                "x": int(m.get("x", 0) or 0),
                "y": int(m.get("y", 0) or 0),
                "mirror": m.get("mirrorOf"),
                "id": m.get("id"),
            })
        by_id = {str(e["id"]): e["name"] for e in entries if e["id"] is not None}
        names = {e["name"] for e in entries}
        main = next((e for e in entries if e["x"] == 0 and e["y"] == 0 and e["mirror"] in (None, "none", "", -1)), entries[0])

        anchors: dict = {}
        for e in entries:
            if e is main:
                anchors[e["name"]] = None
                continue
            mirror = e["mirror"]
            if mirror not in (None, "none", "", -1):
                ref = str(mirror) if str(mirror) in names else by_id.get(str(mirror))
                if ref and ref != e["name"]:
                    anchors[e["name"]] = {"ref": ref, "side": "mirror"}
                    continue
            w, h = cls._logical_size(e)
            found = None
            # Hauptmonitor zuerst prüfen, danach die übrigen
            for r in [main] + [x for x in entries if x is not main and x is not e]:
                if r is e:
                    continue
                rw, rh = cls._logical_size(r)
                adj = cls._adjacency((e["x"], e["y"]), (w, h), (r["x"], r["y"]), (rw, rh))
                if adj:
                    found = cls._make_anchor(r["name"], adj[0], adj[1])
                    break
            anchors[e["name"]] = found or {"ref": main["name"], "side": "right"}
        return anchors

    @staticmethod
    def _make_anchor(ref: str, side: str, offset: int = 0) -> dict:
        """Anker-Dict erzeugen; der Versatz wird nur gespeichert, wenn er != 0 ist."""
        anchor = {"ref": ref, "side": side}
        if offset:
            anchor["offset"] = int(offset)
        return anchor

    @staticmethod
    def _adjacency(pos: tuple, size: tuple, ref_pos: tuple, ref_size: tuple):
        """Prüft, ob ein Monitor die Kante eines Referenzmonitors berührt.

        Rückgabe: (side, offset) oder None.
        """
        x, y = pos
        w, h = size
        rx, ry = ref_pos
        rw, rh = ref_size
        v_overlap = y < ry + rh and ry < y + h
        h_overlap = x < rx + rw and rx < x + w
        if x == rx + rw and v_overlap:
            return ("right", y - ry)
        if x + w == rx and v_overlap:
            return ("left", y - ry)
        if y == ry + rh and h_overlap:
            return ("below", x - rx)
        if y + h == ry and h_overlap:
            return ("above", x - rx)
        return None

    @staticmethod
    def _snap_axis(value: float, size: float, ref_pos: float, ref_size: float, align: float) -> int:
        """Position entlang einer Kante begrenzen und an Ausrichtungen einrasten.

        Der Monitor muss die Kante mindestens ein Viertel seiner Länge überlappen
        und rastet bündig am Anfang, Ende oder in der Mitte des Referenzmonitors ein.
        """
        min_overlap = max(1.0, min(size, ref_size) / 4)
        lo = ref_pos - size + min_overlap
        hi = ref_pos + ref_size - min_overlap
        value = min(max(value, lo), hi)
        targets = (ref_pos, ref_pos + ref_size - size, ref_pos + (ref_size - size) / 2)
        nearest = min(targets, key=lambda t: abs(t - value))
        if abs(nearest - value) <= align:
            value = nearest
        return int(round(value))

    @classmethod
    def snap_position(cls, sizes: dict, positions: dict, name: str, desired: tuple,
                      others: list, align: float = 40) -> Optional[tuple]:
        """Rastet einen gezogenen Monitor an die nächstgelegene Kante eines anderen ein.

        sizes/positions: {name: (w, h)} / {name: (x, y)} in logischen Pixeln.
        desired: gewünschte linke obere Ecke. others: Namen möglicher Referenzmonitore.
        Überlappungen mit anderen Monitoren werden vermieden, solange möglich.
        Rückgabe: (x, y) oder None, falls es keinen Referenzmonitor gibt.
        """
        w, h = sizes[name]
        dx, dy = desired
        refs = [o for o in others if o != name]
        candidates = []
        for o in refs:
            ox, oy = positions[o]
            ow, oh = sizes[o]
            for x in (ox + ow, ox - w):
                candidates.append((x, cls._snap_axis(dy, h, oy, oh, align)))
            for y in (oy + oh, oy - h):
                candidates.append((cls._snap_axis(dx, w, ox, ow, align), y))

        def overlaps(cx: int, cy: int) -> bool:
            for o in refs:
                ox, oy = positions[o]
                ow, oh = sizes[o]
                if cx < ox + ow and ox < cx + w and cy < oy + oh and oy < cy + h:
                    return True
            return False

        def dist(c: tuple) -> float:
            return (c[0] - dx) ** 2 + (c[1] - dy) ** 2

        free = [c for c in candidates if not overlaps(*c)]
        pool = free or candidates
        if not pool:
            return None
        best = min(pool, key=dist)
        return (int(best[0]), int(best[1]))

    @classmethod
    def relayout_anchors(cls, entries: list, positions: dict) -> dict:
        """Leitet Anker (inkl. Versatz) aus absoluten Positionen neu ab.

        Wird nach dem Verschieben eines Monitors per Drag & Drop genutzt. Der
        Hauptmonitor (Eintrag ohne Anker bzw. erster Eintrag) bleibt die Wurzel,
        gespiegelte Monitore behalten ihren Anker. Monitore, die nach dem
        Verschieben keine Kante mehr berühren, werden an den nächsten Monitor
        angesetzt. Rückgabe: {name: None | Anker-Dict}.
        """
        if not entries:
            return {}
        sizes = {e["name"]: cls._logical_size(e) for e in entries}
        root = next((e["name"] for e in entries if not e.get("anchor")), entries[0]["name"])
        pos = {n: tuple(p) for n, p in positions.items()}
        anchors: dict = {root: None}
        for e in entries:
            anchor = e.get("anchor") or {}
            if e["name"] != root and anchor.get("side") == "mirror":
                anchors[e["name"]] = dict(anchor)

        placed = [root]
        remaining = [e["name"] for e in entries if e["name"] not in anchors]
        while remaining:
            found = None
            for n in remaining:
                for r in placed:
                    adj = cls._adjacency(pos[n], sizes[n], pos[r], sizes[r])
                    if adj:
                        found = (n, r, adj)
                        break
                if found:
                    break
            if not found:
                # Nichts berührt die bisherige Gruppe → nächstgelegenen Monitor einrasten
                best = None
                for n in remaining:
                    snapped = cls.snap_position(sizes, pos, n, pos[n], placed)
                    if snapped is None:
                        continue
                    d = (snapped[0] - pos[n][0]) ** 2 + (snapped[1] - pos[n][1]) ** 2
                    if best is None or d < best[0]:
                        best = (d, n, snapped)
                if best is None:
                    for n in remaining:
                        anchors[n] = cls._make_anchor(root, "right")
                    break
                _, n, pos[n] = best
                continue
            n, r, (side, offset) = found
            anchors[n] = cls._make_anchor(r, side, offset)
            placed.append(n)
            remaining.remove(n)
        return anchors

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

    # ── Hardware- & Treiber-Informationen ─────────────────────

    def get_hardware_info(self) -> dict:
        """Ermittelt detaillierte Hardware- und Treiberinformationen."""
        info = {
            "cpu_model": "Unbekannt",
            "cpu_vendor": "Unbekannt",
            "cpu_cores": 0,
            "microcode": "Nicht geprüft",
            "gpus": [],
            "gpu_driver": "Unbekannt",
            "is_laptop": False,
            "battery_status": "Kein Akku",
            "ram_total": "Unbekannt",
            "kernel": "Unbekannt",
            "os_name": "Arch Linux",
        }

        # Kernel
        try:
            res = subprocess.run(["uname", "-r"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0:
                info["kernel"] = res.stdout.strip()
        except Exception:
            pass

        # CPU über /proc/cpuinfo oder lscpu
        try:
            if os.path.exists("/proc/cpuinfo"):
                with open("/proc/cpuinfo", "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        if "model name" in line and info["cpu_model"] == "Unbekannt":
                            info["cpu_model"] = line.split(":", 1)[1].strip()
                        elif "vendor_id" in line and info["cpu_vendor"] == "Unbekannt":
                            v = line.split(":", 1)[1].strip()
                            info["cpu_vendor"] = "AMD" if "AuthenticAMD" in v else ("Intel" if "GenuineIntel" in v else v)
                        elif "cpu cores" in line and info["cpu_cores"] == 0:
                            try:
                                info["cpu_cores"] = int(line.split(":", 1)[1].strip())
                            except ValueError:
                                pass
        except Exception:
            pass

        if info["cpu_model"] == "Unbekannt":
            try:
                res = subprocess.run(["lscpu"], capture_output=True, text=True, timeout=2)
                if res.returncode == 0:
                    for line in res.stdout.splitlines():
                        if "Model name:" in line and info["cpu_model"] == "Unbekannt":
                            info["cpu_model"] = line.split(":", 1)[1].strip()
                        elif "Vendor ID:" in line and info["cpu_vendor"] == "Unbekannt":
                            v = line.split(":", 1)[1].strip()
                            info["cpu_vendor"] = "AMD" if "AuthenticAMD" in v else ("Intel" if "GenuineIntel" in v else v)
            except Exception:
                pass

        # Microcode-Paket prüfen
        try:
            if info["cpu_vendor"] == "AMD":
                res = subprocess.run(["pacman", "-Qi", "amd-ucode"], capture_output=True, text=True, timeout=2)
                info["microcode"] = "amd-ucode (Aktiv & aktuell)" if res.returncode == 0 else "amd-ucode (Nicht installiert)"
            elif info["cpu_vendor"] == "Intel":
                res = subprocess.run(["pacman", "-Qi", "intel-ucode"], capture_output=True, text=True, timeout=2)
                info["microcode"] = "intel-ucode (Aktiv & aktuell)" if res.returncode == 0 else "intel-ucode (Nicht installiert)"
            else:
                info["microcode"] = "Kein Microcode erforderlich"
        except Exception:
            info["microcode"] = "Unbekannt"

        # RAM ermitteln
        try:
            if os.path.exists("/proc/meminfo"):
                with open("/proc/meminfo", "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        if line.startswith("MemTotal:"):
                            kb = int(line.split()[1])
                            gb = round(kb / (1024 * 1024), 1)
                            info["ram_total"] = f"{gb} GB"
                            break
        except Exception:
            pass

        # GPU via lspci
        try:
            res = subprocess.run(["lspci", "-k"], capture_output=True, text=True, timeout=3)
            if res.returncode == 0:
                lines = res.stdout.splitlines()
                for i, line in enumerate(lines):
                    if re.search(r'(VGA compatible controller|3D controller):', line, re.IGNORECASE):
                        gpu_name = re.sub(r'^[0-9a-f:.]+\s+(VGA compatible controller|3D controller):\s+', '', line, flags=re.IGNORECASE)
                        driver = "Mesa / Open-Source"
                        for j in range(i + 1, min(i + 4, len(lines))):
                            if "Kernel driver in use:" in lines[j]:
                                drv = lines[j].split(":", 1)[1].strip()
                                driver = f"Treiber: {drv}"
                                break
                        info["gpus"].append(f"{gpu_name} ({driver})")
        except Exception:
            pass

        if not info["gpus"]:
            info["gpus"].append("Keine dedizierte GPU gefunden (oder lspci fehlt)")

        # Laptop & Akku
        try:
            bat_paths = glob.glob("/sys/class/power_supply/BAT*") + glob.glob("/sys/class/power_supply/CMB*")
            if bat_paths:
                info["is_laptop"] = True
                bat_dir = bat_paths[0]
                cap_file = os.path.join(bat_dir, "capacity")
                stat_file = os.path.join(bat_dir, "status")
                capacity = "Unbekannt"
                status = ""
                if os.path.exists(cap_file):
                    with open(cap_file, "r") as f:
                        capacity = f"{f.read().strip()}%"
                if os.path.exists(stat_file):
                    with open(stat_file, "r") as f:
                        status = f.read().strip()
                status_map = {
                    "Charging": "Wird geladen",
                    "Discharging": "Im Akkubetrieb",
                    "Full": "Vollständig geladen",
                    "Not charging": "Netzbetrieb (Nicht ladend)"
                }
                status_de = status_map.get(status, status)
                info["battery_status"] = f"{capacity} ({status_de})" if status_de else capacity
            else:
                info["is_laptop"] = False
                info["battery_status"] = "Desktop-PC (Kein Akku)"
        except Exception:
            pass

        return info

    # ── Netzwerk- & Bluetooth-Steuerung ──────────────────────

    def get_network_status(self) -> dict:
        """Ermittelt den aktuellen Netzwerk- und WLAN-Status."""
        status = {
            "wifi_enabled": False,
            "connected": False,
            "connection_name": "Keine Verbindung",
            "connection_type": "Keine",
            "ip_address": "Nicht verbunden",
            "nm_available": False,
        }
        try:
            res = subprocess.run(["nmcli", "--version"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0:
                status["nm_available"] = True
        except Exception:
            return status

        # WLAN Radio Status
        try:
            res = subprocess.run(["nmcli", "radio", "wifi"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0:
                status["wifi_enabled"] = ("enabled" in res.stdout.lower())
        except Exception:
            pass

        # Aktive Verbindungen ermitteln
        try:
            res = subprocess.run(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"],
                                 capture_output=True, text=True, timeout=2)
            if res.returncode == 0 and res.stdout.strip():
                for line in res.stdout.strip().splitlines():
                    parts = line.split(":")
                    if len(parts) >= 2:
                        name, conn_type = parts[0], parts[1]
                        if "wireless" in conn_type or "802-11-wireless" in conn_type:
                            status["connected"] = True
                            status["connection_name"] = name
                            status["connection_type"] = "WLAN"
                            break
                        elif "ethernet" in conn_type or "802-3-ethernet" in conn_type:
                            status["connected"] = True
                            status["connection_name"] = name
                            status["connection_type"] = "LAN (Ethernet)"
                            break
                        elif not status["connected"]:
                            status["connected"] = True
                            status["connection_name"] = name
                            status["connection_type"] = conn_type
        except Exception:
            pass

        # IP-Adresse ermitteln
        try:
            res = subprocess.run(["ip", "-brief", "address"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0:
                for line in res.stdout.splitlines():
                    parts = line.split()
                    if len(parts) >= 3 and parts[1].upper() == "UP" and not parts[0].startswith("lo"):
                        ip = parts[2].split("/")[0]
                        status["ip_address"] = f"{ip} ({parts[0]})"
                        break
        except Exception:
            pass

        return status

    def set_wifi_enabled(self, enabled: bool) -> tuple[bool, str]:
        """Schaltet WLAN über nmcli an oder aus."""
        val = "on" if enabled else "off"
        try:
            res = subprocess.run(["nmcli", "radio", "wifi", val], capture_output=True, text=True, timeout=3)
            if res.returncode == 0:
                return True, f"WLAN wurde {'aktiviert' if enabled else 'deaktiviert'}."
            return False, res.stderr.strip() or "Fehler beim Umschalten des WLANs."
        except Exception as e:
            return False, str(e)

    def get_bluetooth_status(self) -> dict:
        """Ermittelt den aktuellen Bluetooth-Status und gekoppelte Geräte."""
        status = {
            "available": False,
            "powered": False,
            "connected_devices": [],
        }
        try:
            res = subprocess.run(["bluetoothctl", "show"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0:
                status["available"] = True
                status["powered"] = ("Powered: yes" in res.stdout)
            else:
                return status
        except Exception:
            return status

        # Gekoppelte / verbundene Geräte
        try:
            res = subprocess.run(["bluetoothctl", "devices", "Connected"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0 and res.stdout.strip():
                for line in res.stdout.strip().splitlines():
                    parts = line.split(maxsplit=2)
                    if len(parts) >= 3:
                        status["connected_devices"].append(parts[2])
        except Exception:
            pass

        return status

    def set_bluetooth_enabled(self, enabled: bool) -> tuple[bool, str]:
        """Schaltet Bluetooth über bluetoothctl an oder aus."""
        val = "on" if enabled else "off"
        try:
            res = subprocess.run(["bluetoothctl", "power", val], capture_output=True, text=True, timeout=3)
            if res.returncode == 0:
                return True, f"Bluetooth wurde {'aktiviert' if enabled else 'deaktiviert'}."
            # Fallback mit rfkill
            rf_val = "unblock" if enabled else "block"
            res2 = subprocess.run(["rfkill", rf_val, "bluetooth"], capture_output=True, text=True, timeout=3)
            if res2.returncode == 0:
                return True, f"Bluetooth wurde {'aktiviert' if enabled else 'deaktiviert'}."
            return False, res.stderr.strip() or "Fehler beim Umschalten von Bluetooth."
        except Exception as e:
            return False, str(e)

    # ── Eingabegeräte (Maus, Touchpad, Tastaturlayout) ───────

    def load_input_settings(self) -> dict:
        """Lädt die aktuellen Tastatur- und Mauseinstellungen."""
        settings = self.load_settings().get("input", {})
        defaults = self._default_settings()["input"]
        return self._deep_merge(defaults, settings)

    def save_input_settings(self, inp: dict, reload: bool = True) -> bool:
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
            if reload:
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

    def build_monitors_lua(self, entries: list) -> str:
        """Erzeugt den Inhalt von monitors.lua für alle Monitore.

        Jeder Eintrag: {name, width, height, hz, scale, size?, transform?, anchor?}
        (width/height = 0 → bevorzugter Modus, hz = 0 → höchste Rate der Auflösung).
        """
        positions = self.compute_monitor_positions(entries)
        blocks = []
        for e in entries:
            name = str(e["name"]).replace('"', "")
            width, height = int(e.get("width", 0) or 0), int(e.get("height", 0) or 0)
            hz = float(e.get("hz", 0) or 0)
            if width > 0 and height > 0:
                mode = f"{width}x{height}"
                if hz > 0:
                    mode += f"@{round(hz)}" if abs(hz - round(hz)) < 0.005 else f"@{hz:.2f}"
            else:
                mode = "preferred"
            scale = float(e.get("scale", 1.0) or 1.0)
            scale_str = f"{scale:.2f}".rstrip("0").rstrip(".") if scale > 0 else "1"
            x, y = positions.get(e["name"], (0, 0))
            lines = [
                "hl.monitor({",
                f'    output   = "{name}",',
                f'    mode     = "{mode}",',
                f'    position = "{x}x{y}",',
                f'    scale    = "{scale_str}",',
            ]
            anchor = e.get("anchor") or {}
            if anchor.get("side") == "mirror" and anchor.get("ref"):
                mirror_ref = str(anchor["ref"]).replace('"', "")
                lines.append(f'    mirror   = "{mirror_ref}",')
            transform = int(e.get("transform", 0) or 0)
            if transform:
                lines.append(f"    transform = {transform},")
            lines.append("})")
            blocks.append("\n".join(lines))

        header = """-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Monitor-Konfiguration                                      ║
-- ║  Erzeugt von der Tokyo-Night Einstellungs-App               ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Fallback für neu angeschlossene Monitore
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

"""
        return header + "\n\n".join(blocks) + "\n"

    def save_monitors_config(self, entries: list) -> bool:
        """Speichert die Konfiguration aller Monitore in monitors.lua und lädt Hyprland neu."""
        if not entries:
            return False
        mon_file = self.hypr_dir / "monitors.lua"
        try:
            content = self.build_monitors_lua(entries)
            mon_file.parent.mkdir(parents=True, exist_ok=True)
            self._backup_file(mon_file)
            mon_file.write_text(content, encoding="utf-8")
        except (OSError, KeyError, ValueError) as e:
            print(f"Fehler beim Speichern von monitors.lua: {e}")
            return False

        try:
            subprocess.run(["hyprctl", "reload"], capture_output=True, timeout=5)
        except (OSError, subprocess.TimeoutExpired):
            pass
        return True

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

    def apply_color_theme(self, theme_key: str, reload: bool = True) -> bool:
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
            if reload:
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

    def reapply_user_settings(self, reload: bool = False) -> dict:
        """Wendet gespeicherte Benutzereinstellungen (Farbschema, Waybar-Layout & Opazität,
        Rofi-Transparenz, Tastaturlayout) erneut an, damit sie nach Updates unverändert bleiben.
        """
        if not self.settings_file.exists():
            return {"applied": False, "reason": "No user_settings.json found"}

        results = {}
        settings = self.load_settings()

        # 1. Tokyo Night Farbschema (colors.lua)
        theme_variant = settings.get("theme", {}).get("variant")
        if theme_variant and theme_variant in self.THEME_PALETTES:
            try:
                self.apply_color_theme(theme_variant, reload=reload)
                results["theme"] = theme_variant
            except Exception as e:
                results["theme_error"] = str(e)

        # 2. Waybar-Layout & Deckkraft
        waybar_settings = settings.get("waybar", {})
        waybar_layout = waybar_settings.get("layout", "classic")
        active_config = self.waybar_dir / "config.jsonc"
        active_style = self.waybar_dir / "style.css"

        # Falls config.jsonc oder style.css fehlen, Layout initial ausrollen
        if not active_config.exists() or not active_style.exists():
            if waybar_layout in self.WAYBAR_LAYOUTS:
                self.apply_waybar_layout(waybar_layout, reload=reload)
                results["waybar_layout_restored"] = waybar_layout

        # Deckkraft für das aktive Layout auf aktive style.css anwenden
        if active_style.exists():
            try:
                opacity = self.get_waybar_opacity(waybar_layout)
                self.apply_waybar_opacity(opacity, waybar_layout, reload=reload)
                results["waybar_opacity"] = opacity
            except Exception as e:
                results["waybar_opacity_error"] = str(e)

        # 3. Rofi Transparenz
        rofi_opacity = settings.get("appearance", {}).get("rofi_opacity")
        if rofi_opacity is not None:
            try:
                self.apply_rofi_opacity(float(rofi_opacity))
                results["rofi_opacity"] = float(rofi_opacity)
            except Exception as e:
                results["rofi_error"] = str(e)

        # 4. Tastaturlayout & Eingabegeräte (input.lua)
        input_file = self.hypr_dir / "input.lua"
        inp = settings.get("input")
        if inp and isinstance(inp, dict):
            # Nur wiederherstellen, falls input.lua fehlt
            if not input_file.exists():
                try:
                    self.save_input_settings(inp, reload=reload)
                    results["input_restored"] = True
                except Exception as e:
                    results["input_error"] = str(e)

        # 5. Sprache (general.language) für SwayNC & Waybar beibehalten
        lang = settings.get("general", {}).get("language")
        if lang:
            try:
                self.apply_language_to_system(lang)
                results["language"] = lang
            except Exception as e:
                results["language_error"] = str(e)

        results["applied"] = True
        return results

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
            "general": {
                "language": "de",
            },
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

    # ── Versions- & Update-Verwaltung ─────────────────────────

    def get_repo_path(self) -> Optional[Path]:
        """Ermittelt den Pfad zum Git-Repository der Dotfiles."""
        candidates = [
            Path(__file__).resolve().parent.parent,
            Path.home() / "Desktop" / "hyprland" / "tokyo-hypr-dots",
            Path.home() / "Desktop" / "hyprland",
            Path.home() / "arch-hyprland",
            Path.home() / "tokyo-hypr-dots",
            Path.home() / "hyprland",
        ]
        for p in candidates:
            if (p / ".git").is_dir() or (p / "update.sh").is_file():
                return p
        return None

    def get_version(self) -> str:
        """Gibt die aktuelle Version der Tokyo Night Dotfiles zurück (z. B. '1.0')."""
        # 1. Installierte Version in ~/.config/hypr/VERSION
        installed = self.hypr_dir / "VERSION"
        if installed.is_file():
            try:
                ver = installed.read_text(encoding="utf-8").strip()
                if ver:
                    return ver
            except OSError:
                pass

        # 2. Im Repo suchen
        repo = self.get_repo_path()
        if repo:
            repo_ver = repo / "VERSION"
            if repo_ver.is_file():
                try:
                    ver = repo_ver.read_text(encoding="utf-8").strip()
                    if ver:
                        return ver
                except OSError:
                    pass

        return "1.0"

    def check_for_updates(self) -> dict:
        """Prüft online via git fetch, ob neue Updates auf GitHub verfügbar sind."""
        repo = self.get_repo_path()
        current_ver = self.get_version()
        now_str = datetime.now().strftime("%d.%m.%Y, %H:%M:%S")

        if not repo or not (repo / ".git").is_dir():
            return {
                "success": False,
                "current_version": current_ver,
                "update_available": False,
                "commits_behind": 0,
                "remote_branch": "origin/main",
                "last_checked": now_str,
                "message": "Git-Repository nicht gefunden (manuelle Installation).",
                "changelog": [],
            }

        try:
            # 1. Fetch remote changes mit kurzem Timeout (8 Sekunden)
            fetch_res = subprocess.run(
                ["git", "fetch", "origin", "main"],
                cwd=str(repo),
                capture_output=True,
                text=True,
                timeout=8,
            )
            if fetch_res.returncode != 0:
                subprocess.run(
                    ["git", "fetch"],
                    cwd=str(repo),
                    capture_output=True,
                    text=True,
                    timeout=8,
                )

            # 2. Prüfe wie viele Commits lokal hinter origin/main liegen
            rev_res = subprocess.run(
                ["git", "rev-list", "HEAD..origin/main", "--count"],
                cwd=str(repo),
                capture_output=True,
                text=True,
                timeout=4,
            )
            count = 0
            if rev_res.returncode == 0:
                try:
                    count = int(rev_res.stdout.strip())
                except ValueError:
                    count = 0

            changelog = []
            if count > 0:
                log_res = subprocess.run(
                    ["git", "log", "HEAD..origin/main", "--oneline", "-n", "5"],
                    cwd=str(repo),
                    capture_output=True,
                    text=True,
                    timeout=4,
                )
                if log_res.returncode == 0 and log_res.stdout.strip():
                    changelog = [line.strip() for line in log_res.stdout.strip().splitlines() if line.strip()]

            update_available = count > 0
            if update_available:
                msg = f"{count} neue Aktualisierung(en) auf GitHub verfügbar!"
            else:
                msg = "Tokyo Night Hyprland ist auf dem neuesten Stand."

            return {
                "success": True,
                "current_version": current_ver,
                "update_available": update_available,
                "commits_behind": count,
                "remote_branch": "origin/main",
                "last_checked": now_str,
                "message": msg,
                "changelog": changelog,
            }

        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "current_version": current_ver,
                "update_available": False,
                "commits_behind": 0,
                "remote_branch": "origin/main",
                "last_checked": now_str,
                "message": "Zeitüberschreitung beim Prüfen (Prüfe deine Internetverbindung).",
                "changelog": [],
            }
        except Exception as e:
            return {
                "success": False,
                "current_version": current_ver,
                "update_available": False,
                "commits_behind": 0,
                "remote_branch": "origin/main",
                "last_checked": now_str,
                "message": f"Prüfung fehlgeschlagen: {e}",
                "changelog": [],
            }

    def get_next_version(self) -> str:
        """Berechnet die nächste Versionsnummer (+0.1)."""
        curr = self.get_version()
        try:
            val = float(curr)
            return f"{val + 0.1:.1f}"
        except ValueError:
            return "1.1"

    def get_last_update_info(self) -> dict:
        """Liest die Zusammenfassung des letzten Updates aus last_update.json."""
        update_file = self.hypr_dir / "last_update.json"
        if update_file.is_file():
            try:
                with open(update_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if isinstance(data, dict):
                        return data
            except (json.JSONDecodeError, OSError):
                pass

        cur_ver = self.get_version()
        repo = self.get_repo_path()
        commits = []
        if repo and (repo / ".git").is_dir():
            try:
                res = subprocess.run(
                    ["git", "log", "-n", "5", "--pretty=format:%s"],
                    cwd=str(repo),
                    capture_output=True,
                    text=True,
                    timeout=3,
                )
                if res.returncode == 0 and res.stdout.strip():
                    commits = [c.strip() for c in res.stdout.strip().splitlines() if c.strip()]
            except Exception:
                pass

        return {
            "version": cur_ver,
            "previous_version": cur_ver,
            "date": "Erstinstallation / Vorheriges Release",
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "commits": commits or [
                "feat: Tokyo Shot Screenshot-Hub & Annotation-Editor",
                "feat: TUI App-Installer mit Checkbox-Auswahl",
                "feat: Versionsanzeige & Update-Center",
                "fix: Shell Re-Exec und Dateiberechtigungen korrigiert",
            ],
            "components": [
                {"name": "Hyprland Konfiguration & Lua-Skripte", "status": "Aktuell", "icon": "preferences-desktop-display-symbolic"},
                {"name": "Tokyo Shot Screenshot-Hub & Editor", "status": "Bereit", "icon": "camera-photo-symbolic"},
                {"name": "TUI App-Installer (pacman & yay)", "status": "Bereit", "icon": "system-software-install-symbolic"},
                {"name": "Hardware- & Treiber-Assistent", "status": "Aktiv", "icon": "preferences-system-devices-symbolic"},
                {"name": "Waybar Statusleiste & Layouts (Crystal/Classic)", "status": "Synchronisiert", "icon": "view-app-grid-symbolic"},
                {"name": "SwayNC Kontrollzentrum & Tokyo CSS", "status": "Aktiv", "icon": "preferences-system-notifications-symbolic"},
                {"name": "Einstellungs-App & Update-Zentrum", "status": "Aktiv", "icon": "system-software-update-symbolic"}
            ],
        }

    def get_recent_changelog(self) -> list[dict]:
        """Liest die wichtigsten Highlights aus CHANGELOG.md aus."""
        repo = self.get_repo_path()
        changelog_file = None
        if repo:
            candidate = repo / "CHANGELOG.md"
            if candidate.is_file():
                changelog_file = candidate

        if not changelog_file:
            local_cand = Path(__file__).resolve().parent.parent / "CHANGELOG.md"
            if local_cand.is_file():
                changelog_file = local_cand

        if not changelog_file or not changelog_file.is_file():
            return []

        try:
            content = changelog_file.read_text(encoding="utf-8")
            items = []
            pattern = re.compile(r"^[*-]\s+\*\*([^*]+)\*\*(?:\s*\(([^)]+)\))?:\s*(.+)$", re.MULTILINE)
            for match in pattern.finditer(content):
                title, path, desc = match.groups()
                items.append({
                    "title": title.strip(),
                    "path": path.strip() if path else "",
                    "description": desc.strip(),
                })
                if len(items) >= 8:
                    break
            return items
        except Exception:
            return []

    # ── Sprachverwaltung (Deutsch / Englisch) ──────────────────

    def get_language(self) -> str:
        """Gibt die konfigurierte Sprache zurück ('de' oder 'en')."""
        settings = self.load_settings()
        lang = settings.get("general", {}).get("language")
        if not lang:
            env_lang = os.environ.get("LANG", "").lower()
            lang = "de" if "de" in env_lang else "en"
        return "de" if str(lang).lower().startswith("de") else "en"

    def set_language(self, lang: str) -> bool:
        """Setzt die Sprache ('de' oder 'en') und synchronisiert Waybar & SwayNC."""
        lang_code = "de" if str(lang).lower().startswith("de") else "en"
        self.update_setting("general", "language", lang_code)
        self.apply_language_to_system(lang_code)
        return True

    def apply_language_to_system(self, lang: str) -> bool:
        """Passt SwayNC, Waybar und Lokalisierungsdateien an die gewählte Sprache an."""
        is_de = str(lang).lower().startswith("de")

        # 1. SwayNC anpassen
        swaync_file = self.config_dir / "swaync" / "config.json"
        if swaync_file.is_file():
            try:
                with open(swaync_file, "r", encoding="utf-8") as f:
                    sdata = json.load(f)

                cfg = sdata.get("widget-config", {})
                if "title" in cfg:
                    cfg["title"]["text"] = "Kontrollzentrum" if is_de else "Control Center"
                    cfg["title"]["button-text"] = "✕ Schließen" if is_de else "✕ Close"
                if "label#notif-header" in cfg:
                    cfg["label#notif-header"]["text"] = "Benachrichtigungen" if is_de else "Notifications"

                # quick-top
                qtop = cfg.get("buttons-grid#quick-top", {}).get("actions", [])
                if len(qtop) >= 3:
                    wifi_status = "Getrennt" if is_de else "Disconnected"
                    bt_status = "Getrennt" if is_de else "Disconnected"
                    qtop[0]["label"] = f"󰖩  {'WLAN' if is_de else 'Wi-Fi'}\n{wifi_status}"
                    qtop[1]["label"] = f"󰂯  Bluetooth\n{bt_status}"
                    qtop[2]["label"] = f"󰖔\n{'Nachtmodus' if is_de else 'Night Light'}"

                # quick-sub
                qsub = cfg.get("buttons-grid#quick-sub", {}).get("actions", [])
                if len(qsub) >= 3:
                    qsub[0]["label"] = f"󰂛\n{'Nicht stören' if is_de else 'Do Not Disturb'}"
                    qsub[1]["label"] = f"󰀝\n{'Flugmodus' if is_de else 'Airplane Mode'}"
                    qsub[2]["label"] = f"󰔎\n{'Dunkelmodus' if is_de else 'Dark Mode'}"

                with open(swaync_file, "w", encoding="utf-8") as f:
                    json.dump(sdata, f, indent=2, ensure_ascii=False)
            except Exception as e:
                print(f"Warnung beim Anpassen von SwayNC: {e}")

        # 2. Waybar anpassen
        wb_file = self.waybar_dir / "config.jsonc"
        if wb_file.is_file():
            try:
                content = wb_file.read_text(encoding="utf-8")
                if is_de:
                    content = content.replace('"format-linked": "󰌷  Connected"', '"format-linked": "󰌷  Verbunden"')
                    content = content.replace('"format-disconnected": "󰤭  Disconnected"', '"format-disconnected": "󰤭  Getrennt"')
                    content = content.replace('"format-muted": "󰝟 Muted"', '"format-muted": "󰝟 Stumm"')
                    content = content.replace('"format-source-muted": "󰍭 Muted"', '"format-source-muted": "󰍭 Stumm"')
                    content = content.replace('"tooltip-format": "Open Settings"', '"tooltip-format": "Einstellungen öffnen"')
                    content = content.replace('"tooltip-format": "View Shortcuts"', '"tooltip-format": "Tastenkürzel anzeigen"')
                    content = content.replace('"tooltip-format": "Power Menu"', '"tooltip-format": "Power-Menü"')
                else:
                    content = content.replace('"format-linked": "󰌷  Verbunden"', '"format-linked": "󰌷  Connected"')
                    content = content.replace('"format-disconnected": "󰤭  Getrennt"', '"format-disconnected": "󰤭  Disconnected"')
                    content = content.replace('"format-muted": "󰝟 Stumm"', '"format-muted": "󰝟 Muted"')
                    content = content.replace('"format-source-muted": "󰍭 Stumm"', '"format-source-muted": "󰍭 Muted"')
                    content = content.replace('"tooltip-format": "Einstellungen öffnen"', '"tooltip-format": "Open Settings"')
                    content = content.replace('"tooltip-format": "Tastenkürzel anzeigen"', '"tooltip-format": "View Shortcuts"')
                    content = content.replace('"tooltip-format": "Power-Menü"', '"tooltip-format": "Power Menu"')
                wb_file.write_text(content, encoding="utf-8")
            except Exception as e:
                print(f"Warnung beim Anpassen von Waybar: {e}")

        # 3. Locale-Datei für Shells aktualisieren
        locale_file = self.config_dir / "locale.conf"
        try:
            target_locale = "de_DE.UTF-8" if is_de else "en_US.UTF-8"
            locale_file.write_text(f"LANG={target_locale}\nLC_ALL={target_locale}\n", encoding="utf-8")
        except Exception:
            pass

        # 4. SwayNC & Waybar live aktualisieren falls aktiv
        try:
            subprocess.run(["swaync-client", "-R"], capture_output=True, timeout=1)
            subprocess.run(["swaync-client", "-rs"], capture_output=True, timeout=1)
        except Exception:
            pass

        if shutil.which("waybar"):
            try:
                subprocess.run(["pkill", "-USR2", "waybar"], capture_output=True, timeout=1)
            except Exception:
                pass

        return True

    def generate_system_locale(self, lang: Optional[str] = None) -> tuple[bool, str]:
        """Wendet die gewählte Locale permanent auf Systemdateien und localectl an."""
        lang_code = lang or self.get_language()
        is_de = str(lang_code).lower().startswith("de")
        target_locale = "de_DE.UTF-8" if is_de else "en_US.UTF-8"
        keymap = "de" if is_de else "us"

        self.apply_language_to_system(lang_code)

        # 1. localectl direkt testen
        if shutil.which("localectl"):
            try:
                r1 = subprocess.run(["localectl", "set-locale", f"LANG={target_locale}", "LC_COLLATE=C"], capture_output=True, text=True, timeout=4)
                if r1.returncode == 0:
                    subprocess.run(["localectl", "set-keymap", keymap], capture_output=True, text=True, timeout=4)
                    return True, f"System-Locale erfolgreich auf {target_locale} gesetzt."
            except Exception:
                pass

        # 2. pkexec für sudo-Rechte falls ohne Rechte nicht gestattet
        if shutil.which("pkexec") and shutil.which("localectl"):
            try:
                r2 = subprocess.run(["pkexec", "localectl", "set-locale", f"LANG={target_locale}", "LC_COLLATE=C"], capture_output=True, text=True, timeout=10)
                if r2.returncode == 0:
                    subprocess.run(["pkexec", "localectl", "set-keymap", keymap], capture_output=True, text=True, timeout=10)
                    return True, f"System-Locale via pkexec auf {target_locale} gesetzt."
            except Exception as e:
                return False, f"Fehler bei pkexec: {e}"

        return True, f"Locale in ~/.config/locale.conf auf {target_locale} gesetzt. Für systemweites Setzen: 'sudo localectl set-locale LANG={target_locale}'."




