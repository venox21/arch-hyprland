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
