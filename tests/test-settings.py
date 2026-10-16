#!/usr/bin/env python3
# pyrefly: ignore-all-errors  -- config_manager/hotkey_manager via sys.path auf Arch Linux
"""
╔══════════════════════════════════════════════════════════════╗
║  Einstellungs-Test                                           ║
║  Prüft die Settings-App und den Config-Manager               ║
╚══════════════════════════════════════════════════════════════╝
"""

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock

# Settings-Ordner zum Pfad hinzufügen
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "settings"))

from config_manager import ConfigManager  # pyrefly: ignore[missing-import]


class TestConfigManager(unittest.TestCase):
    """Tests für den Konfigurationsmanager."""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.cm = ConfigManager()
        # Auf temporäres Verzeichnis umleiten
        self.cm.settings_file = Path(self.temp_dir) / "test_settings.json"

    def tearDown(self):
        # Temporäre Dateien aufräumen
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_default_settings(self):
        """Standard-Einstellungen müssen alle Sektionen enthalten."""
        settings = self.cm.load_settings()
        self.assertIn("clock", settings)
        self.assertIn("performance", settings)
        self.assertIn("waybar", settings)
        self.assertIn("audio", settings)
        self.assertIn("network", settings)
        self.assertIn("appearance", settings)

    def test_save_and_load(self):
        """Einstellungen speichern und laden."""
        settings = self.cm.load_settings()
        settings["clock"]["format_24h"] = False
        settings["waybar"]["height"] = 42

        self.assertTrue(self.cm.save_settings(settings))

        # Cache leeren
        self.cm._settings_cache = None
        loaded = self.cm.load_settings()

        self.assertEqual(loaded["clock"]["format_24h"], False)
        self.assertEqual(loaded["waybar"]["height"], 42)

    def test_update_setting(self):
        """Einzelne Einstellung aktualisieren."""
        self.cm.update_setting("clock", "show_seconds", True)

        self.cm._settings_cache = None
        settings = self.cm.load_settings()
        self.assertTrue(settings["clock"]["show_seconds"])

    def test_settings_file_format(self):
        """Einstellungsdatei muss gültiges JSON sein."""
        settings = self.cm.load_settings()
        self.cm.save_settings(settings)

        with open(self.cm.settings_file, "r") as f:
            loaded = json.load(f)

        self.assertIsInstance(loaded, dict)

    def test_deep_merge(self):
        """Deep-Merge muss verschachtelte Dicts korrekt behandeln."""
        base = {"a": {"b": 1, "c": 2}, "d": 3}
        override = {"a": {"c": 99}, "e": 4}

        result = self.cm._deep_merge(base, override)

        self.assertEqual(result["a"]["b"], 1)
        self.assertEqual(result["a"]["c"], 99)
        self.assertEqual(result["d"], 3)
        self.assertEqual(result["e"], 4)

    def test_corrupted_settings_file(self):
        """Bei defekter Einstellungsdatei: Standard-Werte laden."""
        self.cm.settings_file.parent.mkdir(parents=True, exist_ok=True)
        self.cm.settings_file.write_text("{ ungültiges JSON !!!", encoding="utf-8")

        settings = self.cm.load_settings()
        self.assertIn("clock", settings)

    def test_missing_section_in_saved_file(self):
        """Fehlende Sektionen in gespeicherter Datei: mit Defaults ergänzen."""
        partial = {"clock": {"format_24h": False}}
        self.cm.settings_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.cm.settings_file, "w") as f:
            json.dump(partial, f)

        self.cm._settings_cache = None
        settings = self.cm.load_settings()

        self.assertEqual(settings["clock"]["format_24h"], False)
        self.assertIn("waybar", settings)  # Default-Sektion muss vorhanden sein
        self.assertIn("performance", settings)

    def test_clock_defaults(self):
        """Uhr-Standardeinstellungen prüfen."""
        settings = self.cm.load_settings()
        clock = settings["clock"]
        self.assertTrue(clock["format_24h"])
        self.assertFalse(clock["show_date"])
        self.assertFalse(clock["show_seconds"])
        self.assertTrue(clock["tooltip_enabled"])

    def test_performance_defaults(self):
        """Leistungs-Standardeinstellungen prüfen."""
        settings = self.cm.load_settings()
        perf = settings["performance"]
        self.assertTrue(perf["show_cpu"])
        self.assertTrue(perf["show_ram"])
        self.assertFalse(perf["show_gpu"])
        self.assertEqual(perf["update_interval"], 5)
        self.assertEqual(perf["warning_cpu_threshold"], 80)

    def test_waybar_defaults(self):
        """Waybar-Standardeinstellungen prüfen."""
        settings = self.cm.load_settings()
        wb = settings["waybar"]
        self.assertEqual(wb["position"], "top")
        self.assertEqual(wb["height"], 36)
        self.assertTrue(wb["show_tray"])

    def test_appearance_defaults(self):
        """Darstellungs-Standardeinstellungen prüfen."""
        settings = self.cm.load_settings()
        app = settings["appearance"]
        self.assertEqual(app["border_size"], 2)
        self.assertEqual(app["gaps_in"], 4)
        self.assertEqual(app["rounding"], 8)
        self.assertTrue(app["blur_enabled"])
        self.assertTrue(app["animations_enabled"])
        self.assertIn("rofi_opacity", app)

    def test_rofi_opacity(self):
        """Rofi-Transparenz anwenden testen."""
        rofi_dir = Path(self.temp_dir) / "rofi"
        rofi_dir.mkdir(parents=True, exist_ok=True)
        self.cm.config_dir = Path(self.temp_dir)
        config_rasi = rofi_dir / "config.rasi"
        config_rasi.write_text("*\n{\n    bg: #1a1b26;\n    bg-alt: #24283b;\n}\n", encoding="utf-8")

        self.assertTrue(self.cm.apply_rofi_opacity(0.70))
        content = config_rasi.read_text(encoding="utf-8")
        self.assertIn("rgba(26, 27, 38, 0.70)", content)
        settings = self.cm.load_settings()
        self.assertEqual(settings["appearance"]["rofi_opacity"], 0.70)

    def test_wallpapers_management(self):
        """Wallpaper auflisten und aktivieren testen."""
        wp_dir = Path(self.temp_dir) / "wallpapers"
        wp_dir.mkdir(parents=True, exist_ok=True)
        self.cm.hypr_dir = Path(self.temp_dir)

        # Erstelle Test-Wallpaper
        img1 = wp_dir / "wallpaper1.jpg"
        img2 = wp_dir / "wallpaper2.png"
        img1.write_bytes(b"dummy image 1")
        img2.write_bytes(b"dummy image 2 with different size")

        wps = self.cm.get_wallpapers()
        self.assertEqual(len(wps), 2)
        names = [w["name"] for w in wps]
        self.assertIn("wallpaper1", names)
        self.assertIn("wallpaper2", names)

        # Wallpaper setzen
        self.assertTrue(self.cm.set_wallpaper(str(img1)))
        current = wp_dir / "current.jpg"
        self.assertTrue(current.exists())
        self.assertEqual(current.read_bytes(), b"dummy image 1")

    def test_timedate_info(self):
        """Timedatectl Abfrage testen (mit Fallbacks)."""
        info = self.cm.get_timedate_info()
        self.assertIn("local_time", info)
        self.assertIn("timezone", info)
        self.assertIn("ntp_active", info)
        self.assertIn("rtc_local", info)

    def test_input_settings(self):
        """Tastatur- und Mauseinstellungen laden und speichern."""
        self.cm.hypr_dir = Path(self.temp_dir)
        inp = self.cm.load_input_settings()
        self.assertIn("kb_layout", inp)
        self.assertIn("sensitivity", inp)
        self.assertIn("natural_scroll", inp)

        inp["kb_layout"] = "us"
        inp["sensitivity"] = 0.5
        self.assertTrue(self.cm.save_input_settings(inp))
        input_file = self.cm.hypr_dir / "input.lua"
        self.assertTrue(input_file.exists())
        content = input_file.read_text(encoding="utf-8")
        self.assertIn('kb_layout  = "us"', content)
        self.assertIn("sensitivity = 0.50", content)

    def test_save_monitor_config(self):
        """Monitorkonfiguration speichern."""
        self.cm.hypr_dir = Path(self.temp_dir)
        self.assertTrue(self.cm.save_monitor_config("DP-1", 2560, 1440, 144, 1.25))
        mon_file = self.cm.hypr_dir / "monitors.lua"
        self.assertTrue(mon_file.exists())
        content = mon_file.read_text(encoding="utf-8")
        self.assertIn('output   = "DP-1"', content)
        self.assertIn('mode     = "2560x1440@144"', content)
        self.assertIn('scale    = "1.25"', content)

    def test_theme_palettes(self):
        """Tokyo Night Akzent-Paletten prüfen und anwenden."""
        self.cm.hypr_dir = Path(self.temp_dir)
        palettes = self.cm.THEME_PALETTES
        self.assertIn("classic", palettes)
        self.assertIn("storm", palettes)
        self.assertIn("teal", palettes)
        self.assertIn("neon", palettes)
        self.assertIn("sunset", palettes)

        self.assertTrue(self.cm.apply_color_theme("neon"))
        colors_file = self.cm.hypr_dir / "colors.lua"
        self.assertTrue(colors_file.exists())
        content = colors_file.read_text(encoding="utf-8")
        self.assertIn("Tokyo Night Neon", content)

    def test_waybar_layouts(self):
        """Waybar-Layouts prüfen und aktivieren."""
        self.cm.waybar_dir = Path(self.temp_dir) / "waybar"
        layouts = self.cm.get_waybar_layouts()
        self.assertIn("classic", layouts)
        self.assertIn("pills", layouts)
        self.assertIn("compact", layouts)
        self.assertIn("minimal", layouts)
        self.assertIn("dock", layouts)

        # Layout Pills anwenden
        with patch.object(self.cm, "restart_waybar", return_value=True):
            ok, msg = self.cm.apply_waybar_layout("pills")
            self.assertTrue(ok)
            self.assertTrue((self.cm.waybar_dir / "config.jsonc").exists())
            self.assertTrue((self.cm.waybar_dir / "style.css").exists())
            self.assertEqual(self.cm.get_active_waybar_layout(), "pills")

            # Layout Compact anwenden
            ok, msg = self.cm.apply_waybar_layout("compact")
            self.assertTrue(ok)
            self.assertEqual(self.cm.get_active_waybar_layout(), "compact")

    def test_crystal_layout_exists(self):
        """Das Crystal-Layout ist registriert und seine Dateien existieren."""
        self.assertIn("crystal", self.cm.get_waybar_layouts())
        layout_dir = (Path(__file__).resolve().parent.parent
                      / "config" / "waybar" / "layouts" / "crystal")
        self.assertTrue((layout_dir / "config.jsonc").exists())
        self.assertTrue((layout_dir / "style.css").exists())

    def test_css_bar_opacity_rgba(self):
        """Alpha einer rgba-Hintergrundfarbe wird ersetzt, Farbe bleibt."""
        css = "window#waybar {\n    background: rgba(36, 40, 59, 0.85);\n    color: #fff;\n}\n"
        new, changed = ConfigManager.set_css_bar_opacity(css, 0.30)
        self.assertTrue(changed)
        self.assertIn("background: rgba(36, 40, 59, 0.30);", new)

    def test_css_bar_opacity_hex(self):
        """Hex-Hintergrund wird in rgba mit passendem Alpha umgewandelt."""
        css = "window#waybar {\n    background: #16161e;\n}\n"
        new, changed = ConfigManager.set_css_bar_opacity(css, 0.5)
        self.assertTrue(changed)
        self.assertIn("rgba(22, 22, 30, 0.50)", new)

    def test_css_bar_opacity_transparent_and_hidden(self):
        """Transparente Leisten und .hidden-Blöcke bleiben unangetastet."""
        css = "window#waybar {\n    background: transparent;\n}\nwindow#waybar.hidden {\n    opacity: 0.2;\n}\n"
        new, changed = ConfigManager.set_css_bar_opacity(css, 0.5)
        self.assertFalse(changed)
        self.assertEqual(new, css)

    def test_css_bar_opacity_floor(self):
        """Volle Transparenz lässt einen Rest-Alpha, damit der Blur bleibt."""
        css = "window#waybar {\n    background: rgba(1, 2, 3, 0.9);\n}\n"
        new, _ = ConfigManager.set_css_bar_opacity(css, 0.0)
        self.assertIn("rgba(1, 2, 3, 0.02)", new)

    def test_apply_waybar_opacity_per_layout(self):
        """Transparenz wird je Layout gespeichert und beim Wechsel wieder angewendet."""
        self.cm.waybar_dir = Path(self.temp_dir) / "waybar"
        with patch.object(self.cm, "restart_waybar", return_value=True), \
             patch.object(self.cm, "reload_waybar_style", return_value=True):
            ok, _ = self.cm.apply_waybar_layout("crystal")
            self.assertTrue(ok)
            # Standardwert des Layouts liegt in der CSS
            css = (self.cm.waybar_dir / "style.css").read_text(encoding="utf-8")
            self.assertIn("rgba(26, 27, 38, 0.22)", css)

            self.assertTrue(self.cm.apply_waybar_opacity(0.4))
            self.assertAlmostEqual(self.cm.get_waybar_opacity("crystal"), 0.4)
            css = (self.cm.waybar_dir / "style.css").read_text(encoding="utf-8")
            self.assertIn("rgba(26, 27, 38, 0.40)", css)

            # Zu Classic wechseln: eigener Standard, Crystal-Wert bleibt erhalten
            self.cm.apply_waybar_layout("classic")
            self.assertAlmostEqual(self.cm.get_waybar_opacity("classic"), 0.85)
            self.cm.apply_waybar_layout("crystal")
            css = (self.cm.waybar_dir / "style.css").read_text(encoding="utf-8")
            self.assertIn("rgba(26, 27, 38, 0.40)", css)

    def test_all_layout_css_regex(self):
        """Alle Layouts mit Leistenhintergrund sind per Regler steuerbar."""
        base = Path(__file__).resolve().parent.parent / "config" / "waybar" / "layouts"
        for lid, meta in self.cm.get_waybar_layouts().items():
            css = (base / lid / "style.css").read_text(encoding="utf-8")
            _, changed = ConfigManager.set_css_bar_opacity(css, 0.5)
            self.assertEqual(changed, meta["bar_background"], lid)



class TestKeybindParser(unittest.TestCase):
    """Tests für den Keybind-Parser."""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.keybinds_file = os.path.join(self.temp_dir, "keybinds.lua")

        # Minimale Test-Keybinds-Datei
        test_content = '''
-- ══════════════════════════════════════════════════════════════
-- ██ Anwendungen
-- ══════════════════════════════════════════════════════════════

-- Terminal öffnen
hl.bind("SUPER + Return",        hl.dsp.exec_cmd("kitty"))

-- App-Launcher
hl.bind("SUPER + D",             hl.dsp.exec_cmd("rofi -show drun"))

-- ══════════════════════════════════════════════════════════════
-- ██ Fenster
-- ══════════════════════════════════════════════════════════════

-- Fenster schließen
hl.bind("SUPER + Q",             hl.dsp.window.close())

-- Fenster maximieren
hl.bind("SUPER + F",             hl.dsp.window.fullscreen({ mode = "maximize" }))
'''
        with open(self.keybinds_file, "w", encoding="utf-8") as f:
            f.write(test_content)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_parse_bindings(self):
        """Parser muss Bindings korrekt erkennen."""
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "settings"))
        from hotkey_manager import KeybindParser  # pyrefly: ignore[missing-import]

        parser = KeybindParser(self.keybinds_file)
        bindings = parser.parse()

        self.assertGreater(len(bindings), 0)

        # SUPER + Return muss gefunden werden
        keys = [b.keys for b in bindings]
        self.assertIn("SUPER + Return", keys)
        self.assertIn("SUPER + Q", keys)

    def test_categories(self):
        """Parser muss Kategorien erkennen."""
        from hotkey_manager import KeybindParser  # pyrefly: ignore[missing-import]

        parser = KeybindParser(self.keybinds_file)
        bindings = parser.parse()

        categories = set(b.category for b in bindings)
        self.assertIn("Anwendungen", categories)
        self.assertIn("Fenster", categories)

    def test_no_conflicts_in_test_file(self):
        """Test-Datei darf keine Konflikte haben."""
        from hotkey_manager import KeybindParser  # pyrefly: ignore[missing-import]

        parser = KeybindParser(self.keybinds_file)
        bindings = parser.parse()

        keys = [b.keys for b in bindings]
        self.assertEqual(len(keys), len(set(keys)), "Doppelte Bindings gefunden")

    def test_find_conflicts(self):
        """Konfliktsuche muss funktionieren."""
        from hotkey_manager import KeybindParser  # pyrefly: ignore[missing-import]

        parser = KeybindParser(self.keybinds_file)
        conflicts = parser.find_conflicts("SUPER + Return")
        self.assertEqual(len(conflicts), 1)

        no_conflicts = parser.find_conflicts("SUPER + Z")
        self.assertEqual(len(no_conflicts), 0)

    def test_update_binding(self):
        """Binding ändern muss funktionieren."""
        from hotkey_manager import KeybindParser  # pyrefly: ignore[missing-import]

        parser = KeybindParser(self.keybinds_file)
        result = parser.update_binding("SUPER + Return", "SUPER + T")
        self.assertTrue(result)

        # Prüfen ob geändert
        bindings = parser.parse()
        keys = [b.keys for b in bindings]
        self.assertNotIn("SUPER + Return", keys)
        self.assertIn("SUPER + T", keys)

    def test_validate_keys(self):
        """Key-Validierung prüfen."""
        from hotkey_manager import HotkeyManagerWindow  # pyrefly: ignore[missing-import]

        # Mock-Fenster erstellen für Validierung
        # Direkte Methode testen
        valid_keys = [
            "SUPER + Return", "SUPER + SHIFT + Q", "SUPER + 1",
            "SUPER + Left", "SUPER + F", ", Print",
            ", XF86AudioRaiseVolume",
        ]

        invalid_keys = [
            "", "   ", "SUPER + ", "INVALID + A",
        ]

        # Wir testen _validate_keys direkt
        class MockWindow:
            pass

        win = MockWindow()
        win._validate_keys = HotkeyManagerWindow._validate_keys.__get__(win)

        for key in valid_keys:
            self.assertTrue(win._validate_keys(key), f"'{key}' sollte gültig sein")

        for key in invalid_keys:
            self.assertFalse(win._validate_keys(key), f"'{key}' sollte ungültig sein")


if __name__ == "__main__":
    unittest.main(verbosity=2)
