#!/usr/bin/env python3
# pyrefly: ignore-all-errors  -- gi/GTK4 nur auf Arch Linux (python-gobject) verfügbar
"""
╔══════════════════════════════════════════════════════════════╗
║  Tokyo Night Hyprland – Einstellungs-App                     ║
║  GTK4 + libadwaita GUI für alle Desktop-Einstellungen        ║
╚══════════════════════════════════════════════════════════════╝
"""

import sys
import os
import glob
import threading
from pathlib import Path

# Wayland-Umgebung automatisch ermitteln (SSH / TTY Support)
if "WAYLAND_DISPLAY" not in os.environ:
    uid = os.getuid() if hasattr(os, "getuid") else 1000
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{uid}")
    os.environ["XDG_RUNTIME_DIR"] = runtime_dir
    sockets = [s for s in glob.glob(f"{runtime_dir}/wayland-*") if not s.endswith(".lock")]
    if sockets:
        os.environ["WAYLAND_DISPLAY"] = os.path.basename(sockets[0])

if "HYPRLAND_INSTANCE_SIGNATURE" not in os.environ:
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/run/user/1000")
    hypr_dir = os.path.join(runtime_dir, "hypr")
    if os.path.isdir(hypr_dir):
        sigs = [f for f in os.listdir(hypr_dir) if not f.endswith(".lock")]
        if sigs:
            os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = sigs[0]

# Sicherstellen, dass der Settings-Ordner im Pfad ist
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import gi  # pyrefly: ignore[missing-import]
    gi.require_version("Gtk", "4.0")
    gi.require_version("Adw", "1")
    from gi.repository import Gtk, Adw, Gio, GLib, Gdk  # pyrefly: ignore[missing-import]
except ImportError:
    class _MockBase:
        def __init__(self, *args, **kwargs):
            pass
        def __getattr__(self, name):
            def _dummy(*args, **kwargs):
                return self
            return _dummy
        def set_selected(self, *a, **kw): pass
        def get_selected(self, *a, **kw): return 0
        def get_text(self, *a, **kw): return ""
        def set_text(self, *a, **kw): pass
        def add_suffix(self, *a, **kw): pass
        def set_subtitle(self, *a, **kw): pass
        def set_title(self, *a, **kw): pass
        def add_css_class(self, *a, **kw): pass
        def connect(self, *a, **kw): pass
        def get_active(self, *a, **kw): return False
        def set_active(self, *a, **kw): pass
        def get_value(self, *a, **kw): return 0.0
        def set_value(self, *a, **kw): pass
        def append(self, *a, **kw): pass
        def add(self, *a, **kw): pass
        def set_model(self, *a, **kw): pass
        def set_margin_start(self, *a, **kw): pass
        def set_margin_end(self, *a, **kw): pass
        def set_margin_top(self, *a, **kw): pass
        def set_margin_bottom(self, *a, **kw): pass
        def set_placeholder_text(self, *a, **kw): pass
        def set_visible(self, *a, **kw): pass
        def set_halign(self, *a, **kw): pass
        def set_valign(self, *a, **kw): pass
        def set_hexpand(self, *a, **kw): pass
        def set_sensitive(self, *a, **kw): pass
        def set_content_height(self, *a, **kw): pass
        def set_draw_func(self, *a, **kw): pass
        def queue_draw(self, *a, **kw): pass
        def set_pixel_size(self, *a, **kw): pass
        def get_row_at_index(self, *a, **kw): return self
        def get_index(self, *a, **kw): return 0
        @classmethod
        def new_with_range(cls, *a, **kw): return cls()
        @classmethod
        def new_from_icon_name(cls, *a, **kw): return cls()
        @classmethod
        def add_provider_for_display(cls, *a, **kw): pass
    class _MockAdw:
        Application = _MockBase
        ApplicationWindow = _MockBase
        NavigationSplitView = _MockBase
        NavigationPage = _MockBase
        HeaderBar = _MockBase
        WindowTitle = _MockBase
        ActionRow = _MockBase
        PreferencesGroup = _MockBase
        PreferencesPage = _MockBase
        SwitchRow = _MockBase
        ComboRow = _MockBase
        SpinRow = _MockBase
        EntryRow = _MockBase
    class _MockGtk:
        Box = _MockBase
        Button = _MockBase
        ListBox = _MockBase
        DrawingArea = _MockBase
        CssProvider = _MockBase
        StyleContext = _MockBase
        Adjustment = _MockBase
        Scale = _MockBase
        SpinButton = _MockBase
        PositionType = type("PositionType", (), {"BOTTOM": 0, "TOP": 1})
        STYLE_PROVIDER_PRIORITY_APPLICATION = 600
        STYLE_PROVIDER_PRIORITY_USER = 800
        SelectionMode = type("SelectionMode", (), {"SINGLE": 0})
        Orientation = type("Orientation", (), {"VERTICAL": 0, "HORIZONTAL": 1})
        Align = type("Align", (), {"CENTER": 0, "START": 1, "END": 2})
        ScrolledWindow = _MockBase
        Label = _MockBase
        Image = _MockBase
        FlowBox = _MockBase
        SearchEntry = _MockBase
        StringList = type("StringList", (), {"new": staticmethod(lambda items: _MockBase())})
        class IconTheme:
            @staticmethod
            def get_for_display(display):
                return _MockGtk.IconTheme()
            def has_icon(self, name):
                return False
    class _MockGdk:
        class Display:
            @staticmethod
            def get_default():
                return None
    class _MockGio:
        class ApplicationFlags:
            FLAGS_NONE = 0
    Adw = _MockAdw()
    Gtk = _MockGtk()
    Gdk = _MockGdk()
    Gio = _MockGio()
    GLib = None

from config_manager import ConfigManager  # pyrefly: ignore[missing-import]


class TokyoSettingsApp(Adw.Application):
    """Hauptanwendung für die Einstellungen."""

    def __init__(self):
        super().__init__(
            application_id="de.tokyo-hypr.settings",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        self.config = ConfigManager()

    def do_activate(self):
        try:
            Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        except Exception:
            pass
        win = SettingsWindow(application=self, config=self.config)
        win.present()


class SettingsWindow(Adw.ApplicationWindow):
    """Hauptfenster mit Seitennavigation."""

    def __init__(self, config: ConfigManager, **kwargs):
        super().__init__(**kwargs)
        self.config = config
        self.settings = config.load_settings()

        # Dunkles Tokyo Night Theme erzwingen
        try:
            Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        except Exception:
            pass

        self.set_title("Tokyo Night – Einstellungen")
        self.set_default_size(960, 680)
        self.set_resizable(True)

        # WM_CLASS für Fensterregeln setzen
        self.set_startup_id("tokyo-settings")

        # ── Haupt-Layout: NavigationSplitView ─────────────────
        self.split_view = Adw.NavigationSplitView()
        self.set_content(self.split_view)

        # Sidebar erstellen
        sidebar_page = Adw.NavigationPage(title="Einstellungen")
        sidebar_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        sidebar_page.set_child(sidebar_box)

        # Header für Sidebar
        sidebar_header = Adw.HeaderBar()
        sidebar_header.set_title_widget(Adw.WindowTitle(
            title="Einstellungen",
            subtitle="Tokyo Night"
        ))
        sidebar_box.append(sidebar_header)

        # Schnelle Suche in den Einstellungen
        search_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        search_box.set_margin_start(10)
        search_box.set_margin_end(10)
        search_box.set_margin_top(8)
        search_box.set_margin_bottom(6)

        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_placeholder_text("Einstellungen durchsuchen...")
        self.search_entry.connect("search-changed", self._on_search_changed)
        search_box.append(self.search_entry)
        sidebar_box.append(search_box)

        # Navigations-Liste
        self.nav_list = Gtk.ListBox()
        self.nav_list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.nav_list.add_css_class("navigation-sidebar")
        self.nav_list.connect("row-selected", self._on_nav_selected)

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_child(self.nav_list)
        sidebar_box.append(scroll)

        self.split_view.set_sidebar(sidebar_page)

        # Funktion zur dynamischen Ermittlung des besten verfügbaren Icons
        def _get_best_icon(candidates):
            if isinstance(candidates, str):
                candidates = [candidates]
            try:
                display = Gdk.Display.get_default()
                if display and hasattr(Gtk, "IconTheme"):
                    theme = Gtk.IconTheme.get_for_display(display)
                    for cand in candidates:
                        if theme.has_icon(cand):
                            return cand
            except Exception:
                pass
            return candidates[0] if candidates else "dialog-information-symbolic"

        # ── Seiten definieren (mit Fallback-Icons für alle GTK-Themes) ──
        self.pages = [
            ("Allgemein", [
                "preferences-system-symbolic",
                "emblem-system-symbolic",
                "applications-system-symbolic",
                "org.gnome.Settings-symbolic",
                "preferences-other-symbolic",
            ], self._page_general),
            ("Leisten-Stil & Waybar", [
                "view-app-grid-symbolic",
                "view-grid-symbolic",
                "open-menu-symbolic",
                "view-list-symbolic",
            ], self._page_waybar),
            ("Uhr und Datum", [
                "preferences-system-time-symbolic",
                "alarm-symbolic",
                "x-office-calendar-symbolic",
                "appointment-soon-symbolic",
            ], self._page_clock),
            ("Eingabegeräte", [
                "input-mouse-symbolic",
                "input-keyboard-symbolic",
                "preferences-desktop-peripherals-symbolic",
                "input-gaming-symbolic",
            ], self._page_input),
            ("Monitore & Bildschirme", [
                "video-display-symbolic",
                "preferences-desktop-display-symbolic",
                "display-symbolic",
            ], self._page_monitors),
            ("Systemleistung", [
                "utilities-system-monitor-symbolic",
                "speedometer-symbolic",
                "applications-system-symbolic",
                "dialog-information-symbolic",
            ], self._page_performance),
            ("Netzwerk & Bluetooth", [
                "network-wireless-symbolic",
                "network-wireless-signal-excellent-symbolic",
                "network-workgroup-symbolic",
                "bluetooth-active-symbolic",
                "network-wired-symbolic",
            ], self._page_network),
            ("Audio", [
                "audio-volume-high-symbolic",
                "audio-speakers-symbolic",
                "multimedia-volume-control-symbolic",
            ], self._page_audio),
            ("Fenster und Animationen", [
                "preferences-desktop-display-symbolic",
                "video-display-symbolic",
                "display-symbolic",
                "preferences-desktop-theme-symbolic",
            ], self._page_appearance),
            ("Farben und Transparenz", [
                "preferences-color-symbolic",
                "format-color-fill-symbolic",
                "color-select-symbolic",
                "applications-graphics-symbolic",
            ], self._page_colors),
            ("Hintergrundbilder", [
                "preferences-desktop-wallpaper-symbolic",
                "image-x-generic-symbolic",
                "emblem-photos-symbolic",
                "folder-pictures-symbolic",
            ], self._page_wallpaper),
            ("Tastenkürzel", [
                "input-keyboard-symbolic",
                "accessories-keyboard-shortcut-symbolic",
                "preferences-desktop-keyboard-shortcuts-symbolic",
                "keyboard-symbolic",
            ], self._page_keybinds),
            ("Autostart", [
                "media-playback-start-symbolic",
                "media-playback-start",
                "system-run-symbolic",
            ], self._page_autostart),
            ("Backup", [
                "drive-harddisk-symbolic",
                "document-save-symbolic",
                "system-software-update-symbolic",
            ], self._page_backup),
            ("Hardware & Treiber", [
                "preferences-system-devices-symbolic",
                "computer-symbolic",
                "video-display-symbolic",
                "applications-system-symbolic",
            ], self._page_hardware),
            ("Diagnostik", [
                "dialog-information-symbolic",
                "help-browser-symbolic",
                "utilities-terminal-symbolic",
            ], self._page_diagnostics),
            ("Version & Update", [
                "system-software-update-symbolic",
                "software-update-available-symbolic",
                "system-software-install-symbolic",
                "emblem-system-symbolic",
            ], self._page_version_update),
        ]

        for title, icon_candidates, _ in self.pages:
            row = Adw.ActionRow(title=title)
            chosen_icon = _get_best_icon(icon_candidates)
            row.set_icon_name(chosen_icon)
            row.set_activatable(True)
            self.nav_list.append(row)

        # Erste Seite auswählen
        first_row = self.nav_list.get_row_at_index(0)
        if first_row:
            self.nav_list.select_row(first_row)

        # CSS laden
        self._apply_css()

    def _apply_css(self):
        """Tokyo Night Modern & Clean Glassmorphism CSS anwenden."""
        css = b"""
        @define-color accent_color #7aa2f7;
        @define-color accent_bg_color #7aa2f7;
        @define-color accent_fg_color #1a1b26;

        @define-color window_bg_color #1a1b26;
        @define-color window_fg_color #c0caf5;

        @define-color view_bg_color #1a1b26;
        @define-color view_fg_color #c0caf5;

        @define-color headerbar_bg_color #16161e;
        @define-color headerbar_fg_color #c0caf5;
        @define-color headerbar_border_color rgba(122, 162, 247, 0.12);

        @define-color card_bg_color #1f2335;
        @define-color card_fg_color #c0caf5;
        @define-color card_border_color rgba(122, 162, 247, 0.16);

        @define-color popover_bg_color #1f2335;
        @define-color popover_fg_color #c0caf5;

        @define-color dialog_bg_color #1a1b26;
        @define-color dialog_fg_color #c0caf5;

        @define-color secondary_sidebar_bg_color #16161e;
        @define-color secondary_sidebar_fg_color #c0caf5;

        @define-color destructive_color #f7768e;
        @define-color destructive_bg_color #f7768e;
        @define-color destructive_fg_color #1a1b26;

        @define-color success_color #9ece6a;
        @define-color success_bg_color #9ece6a;
        @define-color success_fg_color #1a1b26;

        @define-color warning_color #e0af68;
        @define-color warning_bg_color #e0af68;
        @define-color warning_fg_color #1a1b26;

        @define-color error_color #f7768e;
        @define-color error_bg_color #f7768e;
        @define-color error_fg_color #1a1b26;

        /* Fenster, Background & Typografie */
        window, .background {
            background-color: #1a1b26;
            color: #c0caf5;
            font-family: "JetBrainsMono Nerd Font", "Inter", sans-serif;
        }

        headerbar {
            background-color: #16161e;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            box-shadow: none;
            padding: 8px 14px;
        }

        headerbar windowhandle {
            background: transparent;
        }

        headerbar .title {
            color: #7aa2f7;
            font-weight: 700;
            font-size: 14px;
            letter-spacing: -0.2px;
        }

        headerbar .subtitle {
            color: #787c99;
            font-size: 11px;
            font-weight: 500;
        }

        /* Sidebar Navigation & Suche */
        .navigation-sidebar {
            background-color: #16161e;
            border-right: 1px solid rgba(255, 255, 255, 0.05);
            padding: 8px 6px;
        }

        .navigation-sidebar row {
            padding: 9px 12px;
            margin: 2px 4px;
            border-radius: 10px;
            color: #a9b1d6;
            background-color: transparent;
            transition: all 140ms cubic-bezier(0.4, 0, 0.2, 1);
            border: 1px solid transparent;
        }

        .navigation-sidebar row:hover {
            background-color: rgba(122, 162, 247, 0.09);
            color: #c0caf5;
        }

        .navigation-sidebar row:selected {
            background: linear-gradient(90deg, rgba(122, 162, 247, 0.22) 0%, rgba(122, 162, 247, 0.08) 100%);
            color: #7aa2f7;
            font-weight: 700;
            border: 1px solid rgba(122, 162, 247, 0.35);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
        }

        .navigation-sidebar row image {
            margin-right: 8px;
            color: #7aa2f7;
        }

        /* SearchEntry in Sidebar */
        searchentry {
            background-color: #13141c;
            color: #c0caf5;
            border: 1px solid rgba(122, 162, 247, 0.20);
            border-radius: 10px;
            padding: 6px 10px;
            transition: all 140ms ease;
        }

        searchentry:focus-within {
            border-color: #7aa2f7;
            box-shadow: 0 0 0 2px rgba(122, 162, 247, 0.25);
            background-color: #16161e;
        }

        /* Hero Banner Dashboard */
        .hero-banner {
            background: linear-gradient(135deg, rgba(122, 162, 247, 0.16) 0%, rgba(187, 154, 247, 0.10) 100%);
            border: 1px solid rgba(122, 162, 247, 0.25);
            border-radius: 14px;
            padding: 18px 22px;
            margin-bottom: 6px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.25), inset 0 1px 0 rgba(255, 255, 255, 0.08);
        }

        .hero-title {
            font-size: 18px;
            font-weight: 800;
            color: #7aa2f7;
            letter-spacing: -0.3px;
        }

        .hero-subtitle {
            font-size: 12px;
            color: #a9b1d6;
        }

        .hero-badge {
            background-color: rgba(158, 206, 106, 0.18);
            color: #9ece6a;
            border: 1px solid rgba(158, 206, 106, 0.35);
            border-radius: 9999px;
            padding: 3px 10px;
            font-size: 11px;
            font-weight: 700;
        }

        /* Content-Bereich & Modern Cards */
        scrolledwindow, viewport {
            background-color: #1a1b26;
        }

        preferencesgroup > box {
            margin-bottom: 14px;
        }

        preferencesgroup > box > label {
            color: #7aa2f7;
            font-weight: 700;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.8px;
            margin-bottom: 4px;
            margin-start: 4px;
        }

        preferencesgroup > box > label.subtitle,
        preferencesgroup > box > label:not(:first-child) {
            color: #787c99;
            font-size: 12px;
            font-weight: 400;
            text-transform: none;
            letter-spacing: normal;
            margin-bottom: 8px;
            margin-start: 4px;
        }

        .card, preferencesgroup list {
            background-color: #1f2335;
            border: 1px solid rgba(122, 162, 247, 0.16);
            border-radius: 14px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.28), inset 0 1px 0 rgba(255, 255, 255, 0.05);
            color: #c0caf5;
        }

        preferencesgroup list > row {
            padding: 12px 18px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.04);
            color: #c0caf5;
            background-color: transparent;
            transition: background-color 120ms ease;
        }

        preferencesgroup list > row:last-child {
            border-bottom: none;
        }

        preferencesgroup list > row:hover {
            background-color: rgba(122, 162, 247, 0.05);
        }

        row label.title {
            color: #c0caf5;
            font-weight: 500;
            font-size: 13px;
        }

        row label.subtitle {
            color: #787c99;
            font-size: 11px;
            margin-top: 2px;
        }

        /* Buttons */
        button {
            background-color: #24283b;
            color: #c0caf5;
            border: 1px solid rgba(122, 162, 247, 0.25);
            border-radius: 10px;
            padding: 7px 16px;
            font-weight: 600;
            font-size: 12px;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
            transition: all 140ms ease;
        }

        button:hover {
            background-color: #2e344e;
            color: #ffffff;
            border-color: #7aa2f7;
            box-shadow: 0 4px 14px rgba(122, 162, 247, 0.25);
        }

        button:active {
            background-color: #3b4261;
        }

        button.suggested-action {
            background: linear-gradient(135deg, #7aa2f7 0%, #638bee 100%);
            color: #1a1b26;
            border: 1px solid rgba(255, 255, 255, 0.15);
            font-weight: 700;
            box-shadow: 0 4px 14px rgba(122, 162, 247, 0.35);
        }

        button.suggested-action:hover {
            background: linear-gradient(135deg, #89b4fa 0%, #7aa2f7 100%);
            color: #16161e;
            box-shadow: 0 6px 18px rgba(122, 162, 247, 0.5);
        }

        button.destructive-action {
            background: linear-gradient(135deg, #f7768e 0%, #e0607a 100%);
            color: #1a1b26;
            border: 1px solid rgba(255, 255, 255, 0.15);
            font-weight: 700;
            box-shadow: 0 4px 14px rgba(247, 118, 142, 0.35);
        }

        button.destructive-action:hover {
            background: linear-gradient(135deg, #ff8b9e 0%, #f7768e 100%);
            box-shadow: 0 6px 18px rgba(247, 118, 142, 0.5);
        }

        /* Switches */
        switch {
            background-color: #16161e;
            border: 1px solid rgba(122, 162, 247, 0.25);
            border-radius: 9999px;
            min-width: 44px;
            min-height: 24px;
            padding: 2px;
            transition: all 180ms cubic-bezier(0.4, 0, 0.2, 1);
        }

        switch:checked {
            background: linear-gradient(135deg, #7aa2f7, #638bee);
            border-color: transparent;
            box-shadow: 0 0 10px rgba(122, 162, 247, 0.4);
        }

        switch slider {
            background-color: #c0caf5;
            border-radius: 9999px;
            min-width: 18px;
            min-height: 18px;
            margin: 1px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.35);
            transition: all 180ms cubic-bezier(0.4, 0, 0.2, 1);
        }

        switch:checked slider {
            background-color: #ffffff;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4);
        }

        /* Eingabefelder & Spinbuttons */
        entry, spinbutton {
            background-color: #16161e;
            color: #c0caf5;
            border: 1px solid rgba(122, 162, 247, 0.22);
            border-radius: 10px;
            padding: 7px 12px;
            transition: all 140ms ease;
        }

        entry:focus, spinbutton:focus {
            border-color: #7aa2f7;
            box-shadow: 0 0 0 2px rgba(122, 162, 247, 0.25);
            background-color: #13141c;
        }

        /* Dropdowns & Popovers */
        popover, popover.background, popover contents {
            background-color: #1f2335;
            border: 1px solid rgba(122, 162, 247, 0.25);
            border-radius: 12px;
            color: #c0caf5;
            box-shadow: 0 12px 32px rgba(0, 0, 0, 0.6);
        }

        popover listview row {
            padding: 8px 12px;
            color: #c0caf5;
            border-radius: 8px;
            margin: 2px 4px;
        }

        popover listview row:hover {
            background-color: rgba(122, 162, 247, 0.15);
        }

        popover listview row:selected {
            background-color: rgba(122, 162, 247, 0.25);
            color: #7aa2f7;
            font-weight: 600;
        }

        /* Scrollbars */
        scrollbar {
            background: transparent;
        }

        scrollbar slider {
            background-color: rgba(122, 162, 247, 0.2);
            border-radius: 6px;
            min-width: 6px;
            min-height: 6px;
            transition: background-color 150ms ease;
        }

        scrollbar slider:hover {
            background-color: rgba(122, 162, 247, 0.55);
        }

        /* Status */
        .status-ok { color: #9ece6a; font-weight: bold; }
        .status-warn { color: #e0af68; font-weight: bold; }
        .status-error { color: #f7768e; font-weight: bold; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )

    def _on_search_changed(self, entry):
        """Filtert die Einstellungs-Kategorien live während des Tippens."""
        query = entry.get_text().strip().lower()
        for idx, (title, _, _) in enumerate(self.pages):
            row = self.nav_list.get_row_at_index(idx)
            if row:
                row.set_visible(not query or query in title.lower())

    def _on_nav_selected(self, listbox, row):
        """Navigationsauswahl verarbeiten."""
        if row is None:
            return
        index = row.get_index()
        if 0 <= index < len(self.pages):
            title, _, page_func = self.pages[index]
            content = page_func()

            content_page = Adw.NavigationPage(title=title)
            page_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

            # Header für Content-Bereich
            header = Adw.HeaderBar()
            header.set_show_back_button(True)
            page_box.append(header)

            # Scroll-Container mit großzügigen, sauberen Rändern
            scroll = Gtk.ScrolledWindow()
            scroll.set_vexpand(True)
            content.set_margin_start(28)
            content.set_margin_end(28)
            content.set_margin_top(20)
            content.set_margin_bottom(28)
            scroll.set_child(content)
            page_box.append(scroll)

            content_page.set_child(page_box)
            self.split_view.set_content(content_page)

    def _select_page_by_title(self, target_title: str):
        """Wechselt direkt zu einer bestimmten Seite."""
        for idx, (title, _, _) in enumerate(self.pages):
            if title == target_title or target_title in title:
                row = self.nav_list.get_row_at_index(idx)
                if row:
                    self.nav_list.select_row(row)
                    self._on_nav_selected(self.nav_list, row)
                break

    # ══════════════════════════════════════════════════════════
    # ██ Seiten
    # ══════════════════════════════════════════════════════════

    def _page_general(self) -> Gtk.Widget:
        """Allgemeine Informationen und Desktop-Dashboard."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        # ── Hero Banner ──────────────────────────────────────────
        hero_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        hero_box.add_css_class("hero-banner")

        hero_text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        title_lbl = Gtk.Label(label="Tokyo Night Hyprland")
        title_lbl.add_css_class("hero-title")
        badge_lbl = Gtk.Label(label="Aktiv")
        badge_lbl.add_css_class("hero-badge")
        title_box.append(title_lbl)
        title_box.append(badge_lbl)

        hypr_ver = self.config.get_hyprland_version()
        sub_lbl = Gtk.Label(label=f"Hyprland {hypr_ver} • Modern Wayland mit Frosted Glass & Dynamic Blur")
        sub_lbl.add_css_class("hero-subtitle")
        sub_lbl.set_halign(Gtk.Align.START)

        hero_text.append(title_box)
        hero_text.append(sub_lbl)
        hero_box.append(hero_text)
        box.append(hero_box)

        # ── Systeminformationen ──────────────────────────────────
        group = Adw.PreferencesGroup(title="System & Hardware", description="Wichtige Desktop- und Hyprland-Metriken")

        version_row = Adw.ActionRow(title="Hyprland-Version", subtitle="Wayland Compositor")
        version_badge = Gtk.Label(label=hypr_ver)
        version_badge.add_css_class("hero-badge")
        version_row.add_suffix(version_badge)
        group.add(version_row)

        tokyo_ver = self.config.get_version()
        dots_row = Adw.ActionRow(
            title=f"Tokyo Night Version: v{tokyo_ver}",
            subtitle="Versionsstand der Konfiguration & Skripte (erhöht sich bei jedem Update um 0.1)"
        )
        dots_badge = Gtk.Label(label=f"v{tokyo_ver}")
        dots_badge.add_css_class("hero-badge")
        dots_row.add_suffix(dots_badge)

        update_check_btn = Gtk.Button(label="Updates prüfen", valign=Gtk.Align.CENTER)
        update_check_btn.connect("clicked", lambda _: self._select_page_by_title("Version & Update"))
        dots_row.add_suffix(update_check_btn)
        dots_row.set_activatable_widget(update_check_btn)
        group.add(dots_row)

        hw_link_row = Adw.ActionRow(title="Hardware & Treiber", subtitle="CPU, GPU, NVIDIA/Mesa-Status und Akku prüfen")
        hw_link_btn = Gtk.Button(label="Öffnen", valign=Gtk.Align.CENTER)
        hw_link_btn.connect("clicked", lambda _: self._select_page_by_title("Hardware"))
        hw_link_row.add_suffix(hw_link_btn)
        group.add(hw_link_row)

        net_link_row = Adw.ActionRow(title="Netzwerk & Bluetooth", subtitle="Live-Verbindungsstatus, WLAN-Schalter und Gerätekopplung")
        net_link_btn = Gtk.Button(label="Öffnen", valign=Gtk.Align.CENTER)
        net_link_btn.connect("clicked", lambda _: self._select_page_by_title("Netzwerk"))
        net_link_row.add_suffix(net_link_btn)
        group.add(net_link_row)

        monitors = self.config.get_monitors()
        mon_count = len(monitors) if monitors else 0
        mon_row = Adw.ActionRow(title="Monitore", subtitle=f"{mon_count} Display(s) aktiv erkannt" if mon_count else "Keine Daten (Hyprland läuft nicht?)")
        mon_btn = Gtk.Button(label="Konfigurieren", valign=Gtk.Align.CENTER)
        mon_btn.connect("clicked", lambda _: self._select_page_by_title("Monitore"))
        mon_row.add_suffix(mon_btn)
        group.add(mon_row)

        active_layout_id = self.config.get_active_waybar_layout()
        active_meta = self.config.get_waybar_layouts().get(active_layout_id, {})
        wb_style_row = Adw.ActionRow(
            title="Aktiver Leisten-Stil (Waybar)",
            subtitle=f"{active_meta.get('name', 'Classic')} – {active_meta.get('preview', '')}",
        )
        wb_btn = Gtk.Button(label="Stil wechseln", valign=Gtk.Align.CENTER)
        wb_btn.connect("clicked", lambda _: self._select_page_by_title("Leisten-Stil"))
        wb_style_row.add_suffix(wb_btn)
        group.add(wb_style_row)

        box.append(group)

        # ── Schnell-Aktionen ─────────────────────────────────────
        actions = Adw.PreferencesGroup(title="Schnell-Aktionen", description="Häufig genutzte Desktop-Befehle")

        rofi_row = Adw.ActionRow(
            title="App-Suche öffnen (Rofi)",
            subtitle="Transparentes Schnellstartmenü für alle installierten Anwendungen (SUPER + D)",
        )
        rofi_btn = Gtk.Button(label="Launcher starten", valign=Gtk.Align.CENTER)
        rofi_btn.add_css_class("suggested-action")
        rofi_btn.connect("clicked", lambda _: os.system("rofi -show drun -theme ~/.config/rofi/config.rasi &"))
        rofi_row.add_suffix(rofi_btn)
        actions.add(rofi_row)

        reload_row = Adw.ActionRow(title="Konfiguration neu laden", subtitle="Startet Waybar neu und aktualisiert Hyprland sofort")
        reload_btn = Gtk.Button(label="Neu laden", valign=Gtk.Align.CENTER)
        reload_btn.add_css_class("suggested-action")
        reload_btn.connect("clicked", lambda _: (self.config.reload_hyprland(), self.config.restart_waybar(), self._show_info("Neu geladen", "Hyprland und Waybar wurden erfolgreich aktualisiert!")))
        reload_row.add_suffix(reload_btn)
        reload_row.set_activatable_widget(reload_btn)
        actions.add(reload_row)

        box.append(actions)
        return box

    def _page_waybar(self) -> Gtk.Widget:
        """Waybar-Einstellungen und Layout-Auswahl."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        wb = self.settings.get("waybar", {})

        # ── 1. Leisten-Stil & Layout-Auswahl ──────────────────
        layout_group = Adw.PreferencesGroup(
            title="Leisten-Stil & Layout",
            description="Wähle zwischen schwebenden Inseln, randloser Top-Bar oder minimalistischem Look",
        )

        layouts = self.config.get_waybar_layouts()
        layout_keys = list(layouts.keys())
        layout_titles = [f"{layouts[k]['name']} ({layouts[k]['preview']})" for k in layout_keys]

        layout_row = Adw.ComboRow(
            title="Aktives Waybar-Layout",
            subtitle="Schaltet das komplette Design, Modul-Set und CSS der Statusleiste um",
        )
        layout_row.set_model(Gtk.StringList.new(layout_titles))

        active_layout = self.config.get_active_waybar_layout()
        selected_layout_idx = 0
        if active_layout in layout_keys:
            selected_layout_idx = layout_keys.index(active_layout)
        layout_row.set_selected(selected_layout_idx)

        # Aktueller Status & Beschreibung
        desc_row = Adw.ActionRow(
            title="Layout-Beschreibung",
            subtitle=layouts.get(active_layout, {}).get("description", ""),
        )
        layout_group.add(layout_row)
        layout_group.add(desc_row)
        box.append(layout_group)

        # ── Transparenz (Regler + Prozentfeld) ────────────────
        transp_group, refresh_transparency = self._build_waybar_transparency_group()
        box.append(transp_group)

        # ── 2. Feinabstimmung ─────────────────────────────────
        group = Adw.PreferencesGroup(
            title="Feinabstimmung",
            description="Individuelle Anpassung von Position, Höhe und Modulen",
        )

        # Position
        pos_row = Adw.ComboRow(title="Position")
        pos_model = Gtk.StringList.new(["Oben", "Unten"])
        pos_row.set_model(pos_model)
        pos_row.set_selected(0 if wb.get("position", "top") == "top" else 1)
        pos_row.connect("notify::selected", lambda r, _: self._update_waybar_setting(
            "position", "top" if r.get_selected() == 0 else "bottom"))
        group.add(pos_row)

        # Höhe
        height_row = Adw.SpinRow.new_with_range(20, 60, 2)
        height_row.set_title("Leistenhöhe (px)")
        height_row.set_value(wb.get("height", 36))
        height_row.connect("notify::value", lambda r, _: self._update_waybar_setting(
            "height", int(r.get_value())))
        group.add(height_row)

        # Schriftgröße
        font_row = Adw.SpinRow.new_with_range(9, 18, 1)
        font_row.set_title("Schriftgröße (pt)")
        font_row.set_value(wb.get("font_size", 13))
        font_row.connect("notify::value", lambda r, _: self._update_waybar_setting(
            "font_size", int(r.get_value())))
        group.add(font_row)

        # Tray
        tray_row = Adw.SwitchRow(title="System-Tray anzeigen", subtitle="Hintergrundprogramme und Tray-Icons einblenden")
        tray_row.set_active(wb.get("show_tray", True))
        tray_row.connect("notify::active", lambda r, _: self._update_waybar_setting(
            "show_tray", r.get_active()))
        group.add(tray_row)

        box.append(group)

        # Listener für Layout-Wechsel
        curr_layout = [active_layout]

        def on_layout_changed(r, _):
            idx = r.get_selected()
            if idx < len(layout_keys):
                chosen_id = layout_keys[idx]
                if chosen_id == curr_layout[0]:
                    return
                ok, msg = self.config.apply_waybar_layout(chosen_id)
                if ok:
                    curr_layout[0] = chosen_id
                    meta = layouts[chosen_id]
                    desc_row.set_subtitle(meta.get("description", ""))
                    pos_row.set_selected(0 if meta["position"] == "top" else 1)
                    height_row.set_value(meta["height"])
                    refresh_transparency(chosen_id)
                    self._show_info("Waybar-Layout", msg)
                else:
                    self._show_info("Fehler", msg)

        layout_row.connect("notify::selected", on_layout_changed)

        # Speichern & Anwenden
        apply_btn = Gtk.Button(label="Einstellungen anwenden und Waybar neu starten")
        apply_btn.add_css_class("suggested-action")
        apply_btn.set_margin_start(16)
        apply_btn.set_margin_end(16)
        apply_btn.set_margin_top(8)
        apply_btn.connect("clicked", self._apply_waybar_settings)
        box.append(apply_btn)

        return box

    def _page_clock(self) -> Gtk.Widget:
        """Uhr- und Systemzeit-Einstellungen."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        # ── 1. Systemzeit & Zeitsynchronisation ──────────────────
        timedate = self.config.get_timedate_info()
        sys_group = Adw.PreferencesGroup(
            title="Systemzeit & Zeitsynchronisation",
            description="Rechner-Uhrzeit, Internet-Synchronisation (NTP) und Zeitzone",
        )

        status_row = Adw.ActionRow(
            title="Aktuelle Systemzeit",
            subtitle=f"{timedate.get('local_time', '')} ({timedate.get('timezone', '')})",
        )
        refresh_btn = Gtk.Button(label="Aktualisieren", valign=Gtk.Align.CENTER)
        def on_refresh_time(_):
            fresh = self.config.get_timedate_info()
            status_row.set_subtitle(f"{fresh.get('local_time', '')} ({fresh.get('timezone', '')})")
            ntp_row.set_active(fresh.get("ntp_active", True))
        refresh_btn.connect("clicked", on_refresh_time)
        status_row.add_suffix(refresh_btn)
        sys_group.add(status_row)

        ntp_row = Adw.SwitchRow(
            title="Automatische Uhrzeit (NTP / Internet)",
            subtitle="Gleicht die Uhrzeit automatisch über Zeitserver im Internet ab",
        )
        ntp_row.set_active(timedate.get("ntp_active", True))
        def on_ntp_toggled(r, _):
            ok, msg = self.config.set_ntp(r.get_active())
            if not ok:
                self._show_info("NTP-Fehler", msg)
        ntp_row.connect("notify::active", on_ntp_toggled)
        sys_group.add(ntp_row)

        tz_row = Adw.ComboRow(
            title="Zeitzone",
            subtitle="Regionale Zeitzone für Sommer- und Winterzeit",
        )
        tz_options = [
            ("Europe/Berlin (Deutschland / MEZ)", "Europe/Berlin"),
            ("Europe/Vienna (Österreich)", "Europe/Vienna"),
            ("Europe/Zurich (Schweiz)", "Europe/Zurich"),
            ("Europe/London (Großbritannien / GMT)", "Europe/London"),
            ("UTC (Koordinierte Weltzeit)", "UTC"),
            ("America/New_York (US Osten / EST)", "America/New_York"),
            ("America/Los_Angeles (US Westen / PST)", "America/Los_Angeles"),
            ("Asia/Tokyo (Japan / JST)", "Asia/Tokyo"),
        ]
        tz_labels = [opt[0] for opt in tz_options]
        tz_model = Gtk.StringList.new(tz_labels)
        tz_row.set_model(tz_model)

        curr_tz = timedate.get("timezone", "Europe/Berlin")
        selected_idx = 0
        for i, opt in enumerate(tz_options):
            if opt[1] == curr_tz:
                selected_idx = i
                break
        tz_row.set_selected(selected_idx)

        active_tz = [curr_tz]

        def on_tz_changed(r, _):
            idx = r.get_selected()
            if idx < len(tz_options):
                chosen_tz = tz_options[idx][1]
                if chosen_tz == active_tz[0]:
                    return
                ok, msg = self.config.set_timezone(chosen_tz)
                if ok:
                    active_tz[0] = chosen_tz
                    fresh = self.config.get_timedate_info()
                    status_row.set_subtitle(f"{fresh.get('local_time', '')} ({fresh.get('timezone', '')})")
                else:
                    self._show_info("Zeitzonen-Fehler", msg)
        tz_row.connect("notify::selected", on_tz_changed)
        sys_group.add(tz_row)

        manual_row = Adw.EntryRow(title="Manuelle Zeit setzen (Format: HH:MM:SS)")
        set_time_btn = Gtk.Button(label="Uhrzeit setzen", valign=Gtk.Align.CENTER)
        set_time_btn.add_css_class("suggested-action")
        def on_set_manual_time(_):
            val = manual_row.get_text().strip()
            if not val:
                self._show_info("Eingabefehler", "Bitte eine Uhrzeit im Format HH:MM:SS angeben.")
                return
            ok, msg = self.config.set_system_time(val)
            if ok:
                ntp_row.set_active(False)
                fresh = self.config.get_timedate_info()
                status_row.set_subtitle(f"{fresh.get('local_time', '')} ({fresh.get('timezone', '')})")
                self._show_info("Uhrzeit aktualisiert", f"Systemzeit erfolgreich auf {val} gesetzt.")
            else:
                self._show_info("Fehler", msg)
        set_time_btn.connect("clicked", on_set_manual_time)
        manual_row.add_suffix(set_time_btn)
        sys_group.add(manual_row)

        rtc_row = Adw.SwitchRow(
            title="Hardware-Uhr (RTC) auf lokale Zeit stellen",
            subtitle="Empfohlen bei Windows Dual-Boot gegen Zeitversatz",
        )
        rtc_row.set_active(timedate.get("rtc_local", False))
        def on_rtc_toggled(r, _):
            ok, msg = self.config.set_rtc_mode(r.get_active())
            if not ok:
                self._show_info("RTC-Fehler", msg)
        rtc_row.connect("notify::active", on_rtc_toggled)
        sys_group.add(rtc_row)

        box.append(sys_group)

        # ── 2. Anzeige in der Waybar ─────────────────────────────
        clock = self.settings.get("clock", {})
        group = Adw.PreferencesGroup(title="Anzeige in der Waybar", description="Format der Uhr in der Statusleiste")

        fmt_row = Adw.SwitchRow(title="24-Stunden-Format")
        fmt_row.set_active(clock.get("format_24h", True))
        fmt_row.connect("notify::active", lambda r, _: self._update_setting("clock", "format_24h", r.get_active()))
        group.add(fmt_row)

        date_row = Adw.SwitchRow(title="Datum anzeigen")
        date_row.set_active(clock.get("show_date", False))
        date_row.connect("notify::active", lambda r, _: self._update_setting("clock", "show_date", r.get_active()))
        group.add(date_row)

        datefmt_row = Adw.ComboRow(title="Datumsformat")
        formats = Gtk.StringList.new(["%d.%m.%Y", "%d/%m/%Y", "%Y-%m-%d", "%d. %B %Y"])
        datefmt_row.set_model(formats)
        current_fmt = clock.get("date_format", "%d.%m.%Y")
        fmt_list = ["%d.%m.%Y", "%d/%m/%Y", "%Y-%m-%d", "%d. %B %Y"]
        datefmt_row.set_selected(fmt_list.index(current_fmt) if current_fmt in fmt_list else 0)
        datefmt_row.connect("notify::selected", lambda r, _: self._update_setting(
            "clock", "date_format", fmt_list[r.get_selected()] if r.get_selected() < len(fmt_list) else fmt_list[0]))
        group.add(datefmt_row)

        sec_row = Adw.SwitchRow(title="Sekunden anzeigen")
        sec_row.set_active(clock.get("show_seconds", False))
        sec_row.connect("notify::active", lambda r, _: self._update_setting("clock", "show_seconds", r.get_active()))
        group.add(sec_row)

        tz_disp_row = Adw.SwitchRow(title="Zeitzone anzeigen")
        tz_disp_row.set_active(clock.get("show_timezone", False))
        tz_disp_row.connect("notify::active", lambda r, _: self._update_setting("clock", "show_timezone", r.get_active()))
        group.add(tz_disp_row)

        tip_row = Adw.SwitchRow(title="Tooltip aktivieren")
        tip_row.set_active(clock.get("tooltip_enabled", True))
        tip_row.connect("notify::active", lambda r, _: self._update_setting("clock", "tooltip_enabled", r.get_active()))
        group.add(tip_row)

        box.append(group)

        apply_btn = Gtk.Button(label="Anwenden und Waybar neu starten")
        apply_btn.add_css_class("suggested-action")
        apply_btn.set_margin_start(16)
        apply_btn.set_margin_end(16)
        apply_btn.connect("clicked", self._apply_waybar_settings)
        box.append(apply_btn)

        return box

    def _page_input(self) -> Gtk.Widget:
        """Eingabegeräte – Tastaturlayout, Maus und Touchpad."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        inp = self.config.load_input_settings()

        # Tastatur
        kb_group = Adw.PreferencesGroup(title="Tastatur", description="Tastaturlayout und Eingabesprache")
        layout_row = Adw.ComboRow(title="Tastaturlayout", subtitle="Sofort aktiv für alle neuen Fenster")
        kb_options = [
            ("Deutsch (QWERTZ) - Standard", "de", ""),
            ("Deutsch (ohne Akzenttasten / nodeadkeys)", "de", "nodeadkeys"),
            ("Englisch / US (QWERTY)", "us", ""),
            ("Schweiz (Deutsch/Französisch)", "ch", ""),
            ("UK (Großbritannien)", "gb", ""),
        ]
        layout_row.set_model(Gtk.StringList.new([opt[0] for opt in kb_options]))
        cur_layout = inp.get("kb_layout", "de")
        cur_variant = inp.get("kb_variant", "")
        selected_idx = 0
        for i, opt in enumerate(kb_options):
            if opt[1] == cur_layout and opt[2] == cur_variant:
                selected_idx = i
                break
        layout_row.set_selected(selected_idx)

        def on_layout_changed(r, _):
            idx = r.get_selected()
            if idx < len(kb_options):
                inp["kb_layout"] = kb_options[idx][1]
                inp["kb_variant"] = kb_options[idx][2]
                self.config.save_input_settings(inp)
        layout_row.connect("notify::selected", on_layout_changed)
        kb_group.add(layout_row)
        box.append(kb_group)

        # Maus
        mouse_group = Adw.PreferencesGroup(title="Maus", description="Zeigergeschwindigkeit und Beschleunigung")
        sens_row = Adw.SpinRow.new_with_range(-1.0, 1.0, 0.05)
        sens_row.set_title("Mausempfindlichkeit (-1.0 bis +1.0)")
        sens_row.set_subtitle("0.0 = Standard, höhere Werte = schneller")
        sens_row.set_value(float(inp.get("sensitivity", 0.0)))
        def on_sens_changed(r, _):
            inp["sensitivity"] = float(r.get_value())
            self.config.save_input_settings(inp)
        sens_row.connect("notify::value", on_sens_changed)
        mouse_group.add(sens_row)
        box.append(mouse_group)

        # Touchpad
        touch_group = Adw.PreferencesGroup(title="Touchpad", description="Gesten und Verhalten für Laptops")
        nat_row = Adw.SwitchRow(
            title="Natürliches Scrollen (Natural Scroll)",
            subtitle="Inhalt bewegt sich in Fingerrichtung wie auf Smartphones",
        )
        nat_row.set_active(inp.get("natural_scroll", True))
        def on_nat_toggled(r, _):
            inp["natural_scroll"] = r.get_active()
            self.config.save_input_settings(inp)
        nat_row.connect("notify::active", on_nat_toggled)
        touch_group.add(nat_row)

        tap_row = Adw.SwitchRow(
            title="Tippen zum Klicken (Tap-to-Click)",
            subtitle="Leichtes Antippen der Touchpad-Oberfläche als Klick werten",
        )
        tap_row.set_active(inp.get("tap_to_click", True))
        def on_tap_toggled(r, _):
            inp["tap_to_click"] = r.get_active()
            self.config.save_input_settings(inp)
        tap_row.connect("notify::active", on_tap_toggled)
        touch_group.add(tap_row)

        type_row = Adw.SwitchRow(
            title="Während des Tippens deaktivieren",
            subtitle="Verhindert versehentliche Zeigersprünge beim Schreiben",
        )
        type_row.set_active(inp.get("disable_while_typing", True))
        def on_type_toggled(r, _):
            inp["disable_while_typing"] = r.get_active()
            self.config.save_input_settings(inp)
        type_row.connect("notify::active", on_type_toggled)
        touch_group.add(type_row)
        box.append(touch_group)

        save_btn = Gtk.Button(label="Eingabeeinstellungen speichern & anwenden")
        save_btn.add_css_class("suggested-action")
        save_btn.set_margin_start(16)
        save_btn.set_margin_end(16)
        save_btn.connect("clicked", lambda _: (self.config.save_input_settings(inp), self._show_info("Eingabegeräte", "Tastatur- und Mauseinstellungen erfolgreich angewendet!")))
        box.append(save_btn)

        return box

    def _page_monitors(self) -> Gtk.Widget:
        """Monitore & Bildschirme – Erkennung, Auflösung, Hz (inkl. Maximum), Skalierung und Anordnung."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        cm = self.config
        monitors = cm.get_monitors()

        def clean(text) -> str:
            """Markup-kritische Zeichen aus Anzeigenamen entfernen."""
            return str(text).replace("&", "+").replace("<", "").replace(">", "")

        if not monitors:
            empty_group = Adw.PreferencesGroup(title="Erkannte Monitore", description="Aktuell an das System angeschlossene Displays")
            empty_group.add(Adw.ActionRow(title="Keine Monitordaten", subtitle="Hyprland läuft nicht oder kein Display erkannt"))
            box.append(empty_group)
            return box

        names = [m.get("name", f"Display-{i}") for i, m in enumerate(monitors)]
        anchors = cm.infer_anchors(monitors)
        multi = len(monitors) > 1

        # ── Erkannte Monitore (Überblick inkl. Maximalwerte) ──
        mon_group = Adw.PreferencesGroup(
            title="Erkannte Monitore",
            description=f"{len(monitors)} Display(s) erkannt – Auflösung, Bildwiederholrate und Maximum",
        )
        for m in monitors:
            name = m.get("name", "Display")
            w, h = int(m.get("width", 0) or 0), int(m.get("height", 0) or 0)
            cur_hz = float(m.get("refreshRate", 60) or 60)
            scale = float(m.get("scale", 1.0) or 1.0)
            max_hz = cm.get_max_refresh(m)
            model_name = " ".join(str(x) for x in (m.get("make", ""), m.get("model", "")) if x).strip()
            title = f"{name}" + (f" – {model_name}" if model_name else "")
            mon_group.add(Adw.ActionRow(
                title=clean(title),
                subtitle=f"Aktuell: {w}x{h} @ {cm.format_hz(cur_hz)} Hz  |  Maximum: {cm.format_hz(max_hz)} Hz  |  Skalierung: {scale:.2f}x",
            ))
        box.append(mon_group)

        # ── Zustand pro Monitor ──
        rows: dict = {}
        # Versatz entlang der berührten Kante pro Monitor (durch Ziehen gesetzt)
        offsets: dict = {n: int((anchors.get(n) or {}).get("offset", 0) or 0) for n in names}
        state = {"suppress": False}
        # Drag & Drop Zustand der Vorschau
        drag: dict = {"name": None, "grab": (0.0, 0.0), "desired": None, "snap": None,
                      "positions": {}, "sizes": {}, "visible": []}
        # Umrechnung logisch → Bildschirm (während des Ziehens eingefroren)
        view = {"factor": 1.0, "bx": 0.0, "by": 0.0, "ox": 0.0, "oy": 0.0}
        scale_base = [1.0, 1.25, 1.5, 1.75, 2.0]
        preview = Gtk.DrawingArea()

        def redraw(*_):
            preview.queue_draw()

        def pos_options_for(name: str) -> list:
            opts = []
            for other in names:
                if other == name:
                    continue
                opts.append((f"Rechts von {other}", {"ref": other, "side": "right"}))
                opts.append((f"Links von {other}", {"ref": other, "side": "left"}))
                opts.append((f"Über {other}", {"ref": other, "side": "above"}))
                opts.append((f"Unter {other}", {"ref": other, "side": "below"}))
                opts.append((f"Spiegeln von {other}", {"ref": other, "side": "mirror"}))
            return opts

        main_row = None
        if multi:
            main_row = Adw.ComboRow(title="Hauptmonitor", subtitle="Liegt bei Position 0x0 – alle anderen werden relativ dazu angeordnet")
            main_row.set_model(Gtk.StringList.new([clean(n) for n in names]))
            main_idx = next((i for i, n in enumerate(names) if anchors.get(n) is None), 0)
            main_row.set_selected(main_idx)

        def make_monitor_group(m: dict, index: int):
            name = names[index]
            modes = cm.parse_monitor_modes(m)
            cur_res = (int(m.get("width", 0) or 0), int(m.get("height", 0) or 0))
            cur_hz = float(m.get("refreshRate", 60) or 60)
            if cur_res not in modes and cur_res[0] > 0:
                modes[cur_res] = [round(cur_hz, 2)]
            res_list = list(modes.keys())
            max_total = cm.get_max_refresh(m)

            model_name = " ".join(str(x) for x in (m.get("make", ""), m.get("model", "")) if x).strip()
            group = Adw.PreferencesGroup(
                title=clean(name),
                description=clean(model_name or m.get("description", "")) + (f"  •  Maximum: {cm.format_hz(max_total)} Hz" if max_total else ""),
            )

            res_row = Adw.ComboRow(title="Auflösung", subtitle="Vom Monitor unterstützte Auflösungen (höchste Hz in Klammern)")
            res_row.set_model(Gtk.StringList.new([
                f"{w} x {h}  (bis {cm.format_hz(max(modes[(w, h)]))} Hz)" for (w, h) in res_list
            ]))
            res_row.set_selected(res_list.index(cur_res) if cur_res in res_list else 0)
            group.add(res_row)

            hz_row = Adw.ComboRow(title="Bildwiederholrate (Hz)")
            group.add(hz_row)

            def fill_hz(keep_current: bool):
                idx = res_row.get_selected()
                res = res_list[idx] if idx < len(res_list) else res_list[0]
                rates = modes.get(res, [0.0])
                hz_row.set_model(Gtk.StringList.new([
                    f"{cm.format_hz(r)} Hz" + ("  – Maximum" if i == 0 else "") for i, r in enumerate(rates)
                ]))
                sel = 0
                if keep_current and res == cur_res:
                    sel = min(range(len(rates)), key=lambda i: abs(rates[i] - cur_hz))
                hz_row.set_selected(sel)
                hz_row.set_subtitle(f"Maximum für {res[0]}x{res[1]}: {cm.format_hz(rates[0])} Hz")

            fill_hz(True)

            scale_vals = list(scale_base)
            cur_scale = float(m.get("scale", 1.0) or 1.0)
            if not any(abs(cur_scale - s) < 0.005 for s in scale_vals):
                scale_vals.append(round(cur_scale, 2))
                scale_vals.sort()
            scale_row = Adw.ComboRow(title="Skalierung (UI-Größe)", subtitle="Vergrößert Schrift und Fenster auf hochauflösenden Displays")
            scale_row.set_model(Gtk.StringList.new([f"{int(round(s * 100))}%  ({s:g}x)" for s in scale_vals]))
            scale_row.set_selected(min(range(len(scale_vals)), key=lambda i: abs(scale_vals[i] - cur_scale)))
            group.add(scale_row)

            pos_row = None
            pos_opts = pos_options_for(name)
            if multi:
                pos_row = Adw.ComboRow(title="Anordnung", subtitle="Position relativ zu einem anderen Monitor (oder in der Vorschau ziehen)")
                pos_row.set_model(Gtk.StringList.new([clean(label) for label, _ in pos_opts]))
                anchor = anchors.get(name)
                sel = 0
                if anchor:
                    for i, (_, opt) in enumerate(pos_opts):
                        if opt["ref"] == anchor["ref"] and opt["side"] == anchor["side"]:
                            sel = i
                            break
                pos_row.set_selected(sel)
                group.add(pos_row)

            def on_res_changed(*_):
                fill_hz(False)
                redraw()

            def on_pos_changed(*_):
                # Manuelle Auswahl im Dropdown setzt den Versatz zurück
                if not state["suppress"]:
                    offsets[name] = 0
                redraw()

            res_row.connect("notify::selected", on_res_changed)
            hz_row.connect("notify::selected", redraw)
            scale_row.connect("notify::selected", redraw)
            if pos_row is not None:
                pos_row.connect("notify::selected", on_pos_changed)

            rows[name] = {
                "monitor": m, "modes": modes, "res_list": res_list,
                "res_row": res_row, "hz_row": hz_row, "scale_row": scale_row,
                "scale_vals": scale_vals, "pos_row": pos_row, "pos_opts": pos_opts,
                "cur_res": cur_res,
            }
            return group

        # ── Anordnung: Hauptmonitor + Vorschau ──
        if multi:
            arr_group = Adw.PreferencesGroup(
                title="Monitor-Anordnung",
                description="Ziehe die Monitore in der Vorschau an die gewünschte Position – sie rasten an den Kanten ein",
            )
            arr_group.add(main_row)
            arr_group.add(preview)
            box.append(arr_group)
        else:
            prev_group = Adw.PreferencesGroup(title="Vorschau")
            prev_group.add(preview)
            box.append(prev_group)

        preview.set_content_height(300 if multi else 190)
        preview.set_hexpand(True)
        preview.set_margin_top(8)
        preview.set_margin_bottom(8)
        if multi:
            preview.set_cursor_from_name("grab")

        # ── Einzelne Monitor-Einstellungen ──
        group_widgets = [make_monitor_group(m, i) for i, m in enumerate(monitors)]

        def selected_resolution(name: str) -> tuple:
            r = rows[name]
            idx = r["res_row"].get_selected()
            return r["res_list"][idx] if idx < len(r["res_list"]) else r["cur_res"]

        def selected_hz(name: str) -> float:
            r = rows[name]
            rates = r["modes"].get(selected_resolution(name), [0.0])
            idx = r["hz_row"].get_selected()
            return rates[idx] if idx < len(rates) else rates[0]

        def selected_scale(name: str) -> float:
            r = rows[name]
            idx = r["scale_row"].get_selected()
            return r["scale_vals"][idx] if idx < len(r["scale_vals"]) else 1.0

        def main_name() -> str:
            if main_row is None:
                return names[0]
            idx = main_row.get_selected()
            return names[idx] if idx < len(names) else names[0]

        def collect_entries() -> list:
            main = main_name()
            entries = []
            for name in names:
                r = rows[name]
                anchor = None
                if multi and name != main and r["pos_row"] is not None:
                    idx = r["pos_row"].get_selected()
                    if idx < len(r["pos_opts"]):
                        anchor = dict(r["pos_opts"][idx][1])
                        if anchor["side"] != "mirror" and offsets.get(name):
                            anchor["offset"] = offsets[name]
                w, h = selected_resolution(name)
                entries.append({
                    "name": name,
                    "width": w, "height": h,
                    "hz": selected_hz(name),
                    "scale": selected_scale(name),
                    "transform": r["monitor"].get("transform", 0),
                    "size": (w, h),
                    "anchor": anchor,
                })
            # Hauptmonitor muss zuerst stehen (Wurzel der Anordnung)
            entries.sort(key=lambda e: e["name"] != main)
            return entries

        def update_main_sensitivity(*_):
            main = main_name()
            for name, r in rows.items():
                if r["pos_row"] is not None:
                    r["pos_row"].set_sensitive(name != main)
            redraw()

        if main_row is not None:
            main_row.connect("notify::selected", update_main_sensitivity)
            update_main_sensitivity()

        # ── Vorschau zeichnen ──
        def hex_rgb(value: str):
            return tuple(int(value[i:i + 2], 16) / 255 for i in (1, 3, 5))

        def layout_info():
            """Aktuelle Anordnung: Einträge, Positionen, Größen, sichtbare/gespiegelte Monitore."""
            entries = collect_entries()
            positions = cm.compute_monitor_positions(entries)
            sizes = {e["name"]: cm._logical_size(e) for e in entries}
            by_name = {e["name"]: e for e in entries}
            main = main_name()

            def final_ref(name: str) -> str:
                seen = set()
                while name not in seen:
                    seen.add(name)
                    anchor = by_name[name].get("anchor")
                    if anchor and anchor.get("side") == "mirror" and anchor.get("ref") in by_name and name != main:
                        name = anchor["ref"]
                    else:
                        break
                return name

            mirrors: dict = {}
            visible = []
            for e in entries:
                target = final_ref(e["name"])
                if target == e["name"]:
                    visible.append(e)
                else:
                    mirrors.setdefault(target, []).append(e["name"])
            return entries, positions, sizes, visible, mirrors, main

        def to_screen(x: float, y: float) -> tuple:
            return (view["ox"] + (x - view["bx"]) * view["factor"],
                    view["oy"] + (y - view["by"]) * view["factor"])

        def to_logical(sx: float, sy: float) -> tuple:
            return ((sx - view["ox"]) / view["factor"] + view["bx"],
                    (sy - view["oy"]) / view["factor"] + view["by"])

        def update_view(width, height, positions, sizes, visible):
            """Skalierung so wählen, dass alle Monitore samt Spielraum zum Ziehen passen."""
            names_v = [e["name"] for e in visible]
            min_x = min(positions[n][0] for n in names_v)
            min_y = min(positions[n][1] for n in names_v)
            max_x = max(positions[n][0] + sizes[n][0] for n in names_v)
            max_y = max(positions[n][1] + sizes[n][1] for n in names_v)
            if multi:
                margin_x = 0.5 * max(sizes[n][0] for n in names_v)
                margin_y = 0.5 * max(sizes[n][1] for n in names_v)
            else:
                margin_x = margin_y = 0
            bx, by = min_x - margin_x, min_y - margin_y
            total_w = max(max_x - min_x + 2 * margin_x, 1)
            total_h = max(max_y - min_y + 2 * margin_y, 1)
            pad = 14
            factor = min((width - 2 * pad) / total_w, (height - 2 * pad) / total_h)
            view.update(
                factor=factor, bx=bx, by=by,
                ox=(width - total_w * factor) / 2,
                oy=(height - total_h * factor) / 2,
            )

        def draw_monitor(cr, e, x, y, w, h, is_main, mirrors, alpha=1.0, accent=None):
            """Zeichnet einen Monitor (logische Koordinaten x, y, w, h)."""
            sx, sy = to_screen(x, y)
            rx, ry = sx + 1.5, sy + 1.5
            rw, rh = max(w * view["factor"] - 3, 4), max(h * view["factor"] - 3, 4)
            name = e["name"]
            cr.rectangle(rx, ry, rw, rh)
            fill = hex_rgb("#2f3549" if is_main else "#24283b")
            cr.set_source_rgba(*fill, alpha)
            cr.fill_preserve()
            cr.set_source_rgba(*hex_rgb(accent or ("#7aa2f7" if is_main else "#bb9af7")), alpha)
            cr.set_line_width(2)
            cr.stroke()

            title = name + (" ★" if is_main else "")
            if mirrors.get(name):
                title += "  ⧉ " + ", ".join(mirrors[name])
            detail = f"{e['width']}x{e['height']} @ {cm.format_hz(e['hz'])} Hz"
            cr.set_source_rgba(*hex_rgb("#c0caf5"), alpha)
            cr.set_font_size(max(9, min(15, rh / 5)))
            ext = cr.text_extents(title)
            cr.move_to(rx + (rw - ext.width) / 2, ry + rh / 2 - 2)
            cr.show_text(title)
            cr.set_source_rgba(*hex_rgb("#9aa5ce"), alpha)
            cr.set_font_size(max(8, min(12, rh / 7)))
            ext = cr.text_extents(detail)
            cr.move_to(rx + (rw - ext.width) / 2, ry + rh / 2 + max(12, min(18, rh / 5)))
            cr.show_text(detail)

        def draw_preview(area, cr, width, height, *_):
            if len(rows) != len(names):
                return
            entries, positions, sizes, visible, mirrors, main = layout_info()
            if not visible:
                return
            dragging = drag["name"]
            if dragging is None:
                update_view(width, height, positions, sizes, visible)

            cr.set_source_rgb(*hex_rgb("#1a1b26"))
            cr.paint()
            cr.select_font_face("Sans")

            for e in visible:
                name = e["name"]
                if name == dragging:
                    continue
                x, y = positions[name]
                w, h = sizes[name]
                draw_monitor(cr, e, x, y, w, h, name == main, mirrors)

            if dragging is not None:
                e = next((v for v in visible if v["name"] == dragging), None)
                if e is not None:
                    w, h = sizes[dragging]
                    snap = drag["snap"]
                    if snap is not None:
                        # Zielposition (rastet beim Loslassen dort ein)
                        sx, sy = to_screen(*snap)
                        cr.rectangle(sx + 1.5, sy + 1.5, max(w * view["factor"] - 3, 4), max(h * view["factor"] - 3, 4))
                        cr.set_source_rgba(*hex_rgb("#9ece6a"), 0.18)
                        cr.fill_preserve()
                        cr.set_source_rgba(*hex_rgb("#9ece6a"), 0.9)
                        cr.set_line_width(2)
                        cr.set_dash([6.0, 4.0])
                        cr.stroke()
                        cr.set_dash([])
                    dx, dy = drag["desired"] or positions[dragging]
                    draw_monitor(cr, e, dx, dy, w, h, dragging == main, mirrors, alpha=0.8, accent="#e0af68")

        preview.set_draw_func(draw_preview)

        # ── Drag & Drop in der Vorschau ──
        def apply_anchors(new_anchors: dict):
            """Neu berechnete Anker in die Dropdowns und Versätze übernehmen."""
            state["suppress"] = True
            try:
                for name, anchor in new_anchors.items():
                    r = rows.get(name)
                    if not anchor or r is None or r["pos_row"] is None:
                        continue
                    for i, (_, opt) in enumerate(r["pos_opts"]):
                        if opt["ref"] == anchor["ref"] and opt["side"] == anchor["side"]:
                            r["pos_row"].set_selected(i)
                            break
                    offsets[name] = 0 if anchor["side"] == "mirror" else int(anchor.get("offset", 0) or 0)
            finally:
                state["suppress"] = False

        def on_drag_begin(gesture, start_x, start_y):
            _, positions, sizes, visible, _, _ = layout_info()
            px, py = to_logical(start_x, start_y)
            hit = None
            for e in reversed(visible):
                n = e["name"]
                x, y = positions[n]
                w, h = sizes[n]
                if x <= px <= x + w and y <= py <= y + h:
                    hit = n
                    break
            if hit is None:
                gesture.set_state(Gtk.EventSequenceState.DENIED)
                return
            gesture.set_state(Gtk.EventSequenceState.CLAIMED)
            drag.update(
                name=hit, grab=(px - positions[hit][0], py - positions[hit][1]),
                desired=positions[hit], snap=None,
                positions=dict(positions), sizes=dict(sizes),
                visible=[e["name"] for e in visible],
            )
            preview.set_cursor_from_name("grabbing")
            redraw()

        def on_drag_update(gesture, off_x, off_y):
            name = drag["name"]
            if name is None:
                return
            ok, start_x, start_y = gesture.get_start_point()
            if not ok:
                return
            px, py = to_logical(start_x + off_x, start_y + off_y)
            desired = (px - drag["grab"][0], py - drag["grab"][1])
            drag["desired"] = desired
            drag["snap"] = cm.snap_position(
                drag["sizes"], drag["positions"], name, desired,
                [n for n in drag["visible"] if n != name],
            )
            redraw()

        def on_drag_end(gesture, off_x, off_y):
            name = drag["name"]
            if name is None:
                return
            snap = drag["snap"]
            drag.update(name=None, desired=None, snap=None)
            preview.set_cursor_from_name("grab")
            if snap is not None:
                entries = collect_entries()
                positions = dict(cm.compute_monitor_positions(entries))
                positions[name] = snap
                apply_anchors(cm.relayout_anchors(entries, positions))
            redraw()

        if multi:
            drag_gesture = Gtk.GestureDrag()
            drag_gesture.set_button(1)
            drag_gesture.connect("drag-begin", on_drag_begin)
            drag_gesture.connect("drag-update", on_drag_update)
            drag_gesture.connect("drag-end", on_drag_end)
            preview.add_controller(drag_gesture)

        # ── Schnellaktionen ──
        quick_group = Adw.PreferencesGroup(title="Schnellaktionen", description="Maximale Werte aller Monitore auf einmal wählen")
        quick_row = Adw.ActionRow(
            title="Maximum auswählen",
            subtitle="Setzt die höchste Bildwiederholrate (oder zusätzlich die höchste Auflösung) für alle Monitore",
        )

        def set_all_max_hz(_):
            for r in rows.values():
                r["hz_row"].set_selected(0)
            redraw()

        def set_all_max_res(_):
            for r in rows.values():
                r["res_row"].set_selected(0)  # Triggert Hz-Neuaufbau mit Maximum
                r["hz_row"].set_selected(0)
            redraw()

        hz_btn = Gtk.Button(label="Max. Hz")
        hz_btn.set_valign(Gtk.Align.CENTER)
        hz_btn.connect("clicked", set_all_max_hz)
        res_btn = Gtk.Button(label="Max. Auflösung + Hz")
        res_btn.set_valign(Gtk.Align.CENTER)
        res_btn.connect("clicked", set_all_max_res)
        quick_row.add_suffix(hz_btn)
        quick_row.add_suffix(res_btn)
        quick_group.add(quick_row)
        box.append(quick_group)

        for widget in group_widgets:
            box.append(widget)

        apply_btn = Gtk.Button(label="Monitoreinstellungen speichern & anwenden")
        apply_btn.add_css_class("suggested-action")
        apply_btn.set_margin_start(16)
        apply_btn.set_margin_end(16)

        def on_apply_monitor(_):
            ok = cm.save_monitors_config(collect_entries())
            if ok:
                self._show_info("Monitore", "Bildschirmeinstellungen in monitors.lua gespeichert und Hyprland neu geladen!\nEin Backup der alten Datei wurde angelegt.")
            else:
                self._show_info("Fehler", "Monitoreinstellungen konnten nicht angewendet werden.")

        apply_btn.connect("clicked", on_apply_monitor)
        box.append(apply_btn)

        return box

    def _page_performance(self) -> Gtk.Widget:
        """Leistungs-Einstellungen."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        perf = self.settings.get("performance", {})

        group = Adw.PreferencesGroup(title="Leistungsanzeige", description="Systemmetriken in der Leiste")

        for key, label in [
            ("show_cpu", "CPU-Auslastung anzeigen"),
            ("show_ram", "RAM-Auslastung anzeigen"),
            ("show_gpu", "GPU-Auslastung anzeigen"),
            ("show_temperature", "Temperaturen anzeigen"),
            ("show_network_speed", "Netzwerkgeschwindigkeit anzeigen"),
        ]:
            row = Adw.SwitchRow(title=label)
            row.set_active(perf.get(key, key != "show_gpu"))
            row.connect("notify::active", lambda r, _, k=key: self._update_setting("performance", k, r.get_active()))
            group.add(row)

        # Aktualisierungsintervall
        interval_row = Adw.SpinRow.new_with_range(1, 30, 1)
        interval_row.set_title("Aktualisierungsintervall (Sekunden)")
        interval_row.set_value(perf.get("update_interval", 5))
        interval_row.connect("notify::value", lambda r, _: self._update_setting(
            "performance", "update_interval", int(r.get_value())))
        group.add(interval_row)

        # Kompaktmodus
        compact_row = Adw.SwitchRow(title="Kompaktes Format")
        compact_row.set_active(perf.get("compact_mode", False))
        compact_row.connect("notify::active", lambda r, _: self._update_setting(
            "performance", "compact_mode", r.get_active()))
        group.add(compact_row)

        box.append(group)

        # Schwellenwerte
        thresholds = Adw.PreferencesGroup(title="Warnschwellen", description="Ab diesen Werten wird Rot angezeigt")

        for key, label, default in [
            ("warning_cpu_threshold", "CPU-Warnschwelle (%)", 80),
            ("warning_ram_threshold", "RAM-Warnschwelle (%)", 85),
            ("warning_temp_threshold", "Temperatur-Warnschwelle (°C)", 85),
        ]:
            row = Adw.SpinRow.new_with_range(50, 100, 5)
            row.set_title(label)
            row.set_value(perf.get(key, default))
            row.connect("notify::value", lambda r, _, k=key: self._update_setting("performance", k, int(r.get_value())))
            thresholds.add(row)

        box.append(thresholds)

        apply_btn = Gtk.Button(label="Anwenden und Waybar neu starten")
        apply_btn.add_css_class("suggested-action")
        apply_btn.set_margin_start(16)
        apply_btn.set_margin_end(16)
        apply_btn.connect("clicked", self._apply_waybar_settings)
        box.append(apply_btn)

        return box

    def _page_network(self) -> Gtk.Widget:
        """Netzwerk- und Bluetooth-Einstellungen mit Live-Steuerung."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        net_status = self.config.get_network_status()
        bt_status = self.config.get_bluetooth_status()

        # ── 1. Netzwerkverbindung & WLAN ──────────────────────
        conn_group = Adw.PreferencesGroup(
            title="Netzwerk & WLAN",
            description="Aktive Verbindung und Drahtlosnetzwerk-Steuerung"
        )

        conn_title = net_status.get("connection_name", "Keine Verbindung")
        conn_sub = f"Typ: {net_status.get('connection_type', 'Unbekannt')} • IP: {net_status.get('ip_address', 'Nicht verbunden')}"
        status_row = Adw.ActionRow(title=conn_title, subtitle=conn_sub)
        status_badge = Gtk.Label(label="Verbunden" if net_status.get("connected") else "Getrennt")
        status_badge.add_css_class("hero-badge")
        status_row.add_suffix(status_badge)
        conn_group.add(status_row)

        wifi_switch = Adw.SwitchRow(
            title="WLAN-Adapter (Wi-Fi)",
            subtitle="Drahtlosnetzwerk über NetworkManager (nmcli radio wifi) aktivieren"
        )
        wifi_switch.set_active(net_status.get("wifi_enabled", False))
        def on_wifi_toggled(r, _):
            val = r.get_active()
            ok, msg = self.config.set_wifi_enabled(val)
            if not ok:
                self._show_info("WLAN-Fehler", msg)
        wifi_switch.connect("notify::active", on_wifi_toggled)
        conn_group.add(wifi_switch)

        nm_row = Adw.ActionRow(
            title="Netzwerk-Manager öffnen",
            subtitle="Drahtlosnetzwerke scannen, Passwörter verwalten und VPNs einrichten"
        )
        nm_btn = Gtk.Button(label="Verbindungen verwalten", valign=Gtk.Align.CENTER)
        nm_btn.add_css_class("suggested-action")
        nm_btn.connect("clicked", lambda _: os.system("nm-connection-editor 2>/dev/null || kitty --title 'Netzwerk (nmtui)' bash -c 'nmtui' &"))
        nm_row.add_suffix(nm_btn)
        nm_row.set_activatable_widget(nm_btn)
        conn_group.add(nm_row)

        box.append(conn_group)

        # ── 2. Bluetooth-Verwaltung ───────────────────────────
        bt_group = Adw.PreferencesGroup(
            title="Bluetooth",
            description="Drahtlose Geräte und Adaptersteuerung"
        )

        bt_avail = bt_status.get("available", False)
        bt_powered = bt_status.get("powered", False)
        connected_devs = bt_status.get("connected_devices", [])

        bt_sub = "Keine Geräte verbunden"
        if connected_devs:
            bt_sub = f"Verbunden: {', '.join(connected_devs)}"
        elif not bt_avail:
            bt_sub = "Kein Bluetooth-Adapter oder bluetoothctl nicht gefunden"

        bt_status_row = Adw.ActionRow(
            title="Bluetooth-Adapter",
            subtitle=bt_sub
        )
        bt_badge = Gtk.Label(label="Aktiv" if bt_powered else ("Inaktiv" if bt_avail else "Fehlt"))
        bt_badge.add_css_class("hero-badge")
        bt_status_row.add_suffix(bt_badge)
        bt_group.add(bt_status_row)

        bt_switch = Adw.SwitchRow(
            title="Bluetooth aktivieren",
            subtitle="Adapter über bluetoothctl / rfkill ein- oder ausschalten"
        )
        bt_switch.set_active(bt_powered)
        bt_switch.set_sensitive(bt_avail)
        def on_bt_toggled(r, _):
            val = r.get_active()
            ok, msg = self.config.set_bluetooth_enabled(val)
            if not ok:
                self._show_info("Bluetooth-Fehler", msg)
        bt_switch.connect("notify::active", on_bt_toggled)
        bt_group.add(bt_switch)

        blueman_row = Adw.ActionRow(
            title="Bluetooth-Geräte verwalten",
            subtitle="Kopplung, Audio-Profile und Verbindungen mit Blueman oder Bluetoothctl"
        )
        blueman_btn = Gtk.Button(label="Geräte koppeln", valign=Gtk.Align.CENTER)
        blueman_btn.add_css_class("suggested-action")
        blueman_btn.connect("clicked", lambda _: os.system("blueman-manager 2>/dev/null || kitty --title 'Bluetooth Manager' bash -c 'bluetoothctl' &"))
        blueman_row.add_suffix(blueman_btn)
        blueman_row.set_activatable_widget(blueman_btn)
        bt_group.add(blueman_row)

        box.append(bt_group)

        # ── 3. Waybar Leisten-Anzeige ─────────────────────────
        waybar_group = Adw.PreferencesGroup(
            title="Waybar-Leistenanzeige",
            description="Netzwerkmetriken in der Statusleiste"
        )
        net_cfg = self.settings.get("network", {})

        speed_row = Adw.SwitchRow(title="Geschwindigkeit anzeigen")
        speed_row.set_active(net_cfg.get("show_speed", True))
        speed_row.connect("notify::active", lambda r, _: self._update_setting("network", "show_speed", r.get_active()))
        waybar_group.add(speed_row)

        ip_row = Adw.SwitchRow(title="IP-Adresse anzeigen")
        ip_row.set_active(net_cfg.get("show_ip", False))
        ip_row.connect("notify::active", lambda r, _: self._update_setting("network", "show_ip", r.get_active()))
        waybar_group.add(ip_row)

        apply_btn = Gtk.Button(label="Anwenden und Waybar neu starten")
        apply_btn.add_css_class("suggested-action")
        apply_btn.connect("clicked", self._apply_waybar_settings)
        waybar_group.add(apply_btn)

        box.append(waybar_group)
        return box

    def _page_audio(self) -> Gtk.Widget:
        """Audio-Einstellungen."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        audio = self.settings.get("audio", {})
        group = Adw.PreferencesGroup(title="Audio", description="Lautstärke und Mikrofon")

        vol_row = Adw.SwitchRow(title="Lautstärke anzeigen")
        vol_row.set_active(audio.get("show_volume", True))
        vol_row.connect("notify::active", lambda r, _: self._update_setting("audio", "show_volume", r.get_active()))
        group.add(vol_row)

        mic_row = Adw.SwitchRow(title="Mikrofon anzeigen")
        mic_row.set_active(audio.get("show_microphone", True))
        mic_row.connect("notify::active", lambda r, _: self._update_setting("audio", "show_microphone", r.get_active()))
        group.add(mic_row)

        step_row = Adw.SpinRow.new_with_range(1, 15, 1)
        step_row.set_title("Lautstärke-Schrittgröße (%)")
        step_row.set_value(audio.get("step_size", 5))
        step_row.connect("notify::value", lambda r, _: self._update_setting("audio", "step_size", int(r.get_value())))
        group.add(step_row)

        box.append(group)
        return box

    def _page_appearance(self) -> Gtk.Widget:
        """Fenster und Animationen."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        app = self.settings.get("appearance", {})

        group = Adw.PreferencesGroup(title="Fenster", description="Abstände und Rahmen")

        gaps_in = Adw.SpinRow.new_with_range(0, 20, 1)
        gaps_in.set_title("Innere Abstände (gaps_in)")
        gaps_in.set_value(app.get("gaps_in", 4))
        gaps_in.connect("notify::value", lambda r, _: self._update_setting("appearance", "gaps_in", int(r.get_value())))
        group.add(gaps_in)

        gaps_out = Adw.SpinRow.new_with_range(0, 40, 2)
        gaps_out.set_title("Äußere Abstände (gaps_out)")
        gaps_out.set_value(app.get("gaps_out", 8))
        gaps_out.connect("notify::value", lambda r, _: self._update_setting("appearance", "gaps_out", int(r.get_value())))
        group.add(gaps_out)

        border_row = Adw.SpinRow.new_with_range(0, 6, 1)
        border_row.set_title("Rahmenstärke")
        border_row.set_value(app.get("border_size", 2))
        border_row.connect("notify::value", lambda r, _: self._update_setting("appearance", "border_size", int(r.get_value())))
        group.add(border_row)

        round_row = Adw.SpinRow.new_with_range(0, 20, 1)
        round_row.set_title("Eckenrundung")
        round_row.set_value(app.get("rounding", 8))
        round_row.connect("notify::value", lambda r, _: self._update_setting("appearance", "rounding", int(r.get_value())))
        group.add(round_row)

        box.append(group)

        # Animationen
        anim_group = Adw.PreferencesGroup(title="Animationen")

        anim_row = Adw.SwitchRow(title="Animationen aktivieren")
        anim_row.set_active(app.get("animations_enabled", True))
        anim_row.connect("notify::active", lambda r, _: self._update_setting("appearance", "animations_enabled", r.get_active()))
        anim_group.add(anim_row)

        box.append(anim_group)

        # Blur
        blur_group = Adw.PreferencesGroup(title="Unschärfe (Blur)")

        blur_row = Adw.SwitchRow(title="Blur aktivieren")
        blur_row.set_active(app.get("blur_enabled", True))
        blur_row.connect("notify::active", lambda r, _: self._update_setting("appearance", "blur_enabled", r.get_active()))
        blur_group.add(blur_row)

        box.append(blur_group)

        # Schatten
        shadow_group = Adw.PreferencesGroup(title="Schatten")

        shadow_row = Adw.SwitchRow(title="Schatten aktivieren")
        shadow_row.set_active(app.get("shadow_enabled", True))
        shadow_row.connect("notify::active", lambda r, _: self._update_setting("appearance", "shadow_enabled", r.get_active()))
        shadow_group.add(shadow_row)

        box.append(shadow_group)

        apply_btn = Gtk.Button(label="Einstellungen anwenden (erfordert Reload)")
        apply_btn.add_css_class("suggested-action")
        apply_btn.set_margin_start(16)
        apply_btn.set_margin_end(16)
        apply_btn.connect("clicked", lambda _: self._apply_and_save())
        box.append(apply_btn)

        return box

    def _page_colors(self) -> Gtk.Widget:
        """Farben, Tokyo Night Akzente und Transparenz."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        # ── 1. Tokyo Night Farbschemata ────────────────────────
        palettes = getattr(self.config, "THEME_PALETTES", {})
        theme_group = Adw.PreferencesGroup(
            title="Tokyo Night Farbschemata & Akzente",
            description="Passe die Primär- und Rahmen-Akzentfarben des gesamten Desktops an",
        )

        theme_row = Adw.ComboRow(title="Akzentfarb-Schema", subtitle="Ändert Fensterrahmen-Gradienten, Waybar- und Systemfarben")
        theme_keys = list(palettes.keys()) if palettes else ["classic"]
        theme_labels = [palettes[k]["name"] for k in theme_keys] if palettes else ["Tokyo Night Classic"]
        theme_row.set_model(Gtk.StringList.new(theme_labels))

        cur_variant = self.settings.get("theme", {}).get("variant", "classic")
        selected_idx = theme_keys.index(cur_variant) if cur_variant in theme_keys else 0
        theme_row.set_selected(selected_idx)
        theme_group.add(theme_row)

        apply_theme_btn = Gtk.Button(label="Farbschema sofort anwenden")
        apply_theme_btn.add_css_class("suggested-action")
        apply_theme_btn.set_margin_start(16)
        apply_theme_btn.set_margin_end(16)

        def on_theme_clicked(_):
            idx = theme_row.get_selected()
            if idx < len(theme_keys):
                k = theme_keys[idx]
                if self.config.apply_color_theme(k):
                    self._show_info("Farbschema gewechselt", f"Akzentfarben erfolgreich auf '{palettes[k]['name']}' umgestellt!")
                else:
                    self._show_info("Fehler", "Farbschema konnte nicht angewendet werden.")

        apply_theme_btn.connect("clicked", on_theme_clicked)
        theme_group.add(apply_theme_btn)
        box.append(theme_group)

        # ── 2. Transparenz ────────────────────────────────────
        app = self.settings.get("appearance", {})
        group = Adw.PreferencesGroup(title="Transparenz", description="Fenster-Durchsichtigkeit")

        # Aktive Fenster-Transparenz (als Prozent)
        active_row = Adw.SpinRow.new_with_range(50, 100, 5)
        active_row.set_title("Aktives Fenster (%)")
        active_row.set_value(int(app.get("active_opacity", 1.0) * 100))
        active_row.connect("notify::value", lambda r, _: self._update_setting(
            "appearance", "active_opacity", r.get_value() / 100.0))
        group.add(active_row)

        inactive_row = Adw.SpinRow.new_with_range(50, 100, 5)
        inactive_row.set_title("Inaktives Fenster (%)")
        inactive_row.set_value(int(app.get("inactive_opacity", 0.92) * 100))
        inactive_row.connect("notify::value", lambda r, _: self._update_setting(
            "appearance", "inactive_opacity", r.get_value() / 100.0))
        group.add(inactive_row)

        box.append(group)

        # Waybar-Transparenz (Regler + Prozentfeld, wirkt live)
        wb_group, _ = self._build_waybar_transparency_group()
        box.append(wb_group)

        # ── 3. App-Suche Transparenz (Rofi) ───────────────────
        rofi_group = Adw.PreferencesGroup(
            title="App-Suche Transparenz (Rofi)",
            description="Steuert die Durchsichtigkeit und den Frosted-Glass-Effekt des App-Launchers (SUPER + D)",
        )
        rofi_transp = Adw.SpinRow.new_with_range(20, 100, 5)
        rofi_transp.set_title("App-Suche Deckkraft (%)")
        rofi_transp.set_subtitle("Geringerer Wert = transparenter mit Unschärfe-Hintergrund")
        rofi_transp.set_value(int(app.get("rofi_opacity", 0.72) * 100))

        def on_rofi_opacity_changed(r, _):
            val = r.get_value() / 100.0
            self._update_setting("appearance", "rofi_opacity", val)
            self.config.apply_rofi_opacity(val)

        rofi_transp.connect("notify::value", on_rofi_opacity_changed)
        rofi_group.add(rofi_transp)

        test_row = Adw.ActionRow(
            title="App-Suche Vorschau",
            subtitle="Öffnet den Rofi-Launcher sofort, um die Transparenz live zu begutachten",
        )
        test_btn = Gtk.Button(label="Launcher testen", valign=Gtk.Align.CENTER)
        test_btn.add_css_class("suggested-action")
        test_btn.connect("clicked", lambda _: os.system("rofi -show drun -theme ~/.config/rofi/config.rasi &"))
        test_row.add_suffix(test_btn)
        rofi_group.add(test_row)

        box.append(rofi_group)
        return box

    def _page_wallpaper(self) -> Gtk.Widget:
        """Hintergrundbilder und JaKooLit Wallpaper-Bank."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        # Aktions-Gruppe
        action_group = Adw.PreferencesGroup(
            title="Wallpaper-Verwaltung",
            description="Verwalte Desktop-Hintergründe oder lade neue aus der JaKooLit Wallpaper-Bank"
        )

        # Sync-Row
        sync_row = Adw.ActionRow(
            title="JaKooLit Wallpaper-Bank",
            subtitle="Kostenlose Wallpaper-Sammlung von GitHub herunterladen oder aktualisieren"
        )
        sync_btn = Gtk.Button(label="Synchronisieren")
        sync_btn.add_css_class("suggested-action")
        sync_btn.set_valign(Gtk.Align.CENTER)

        def on_sync_clicked(_):
            sync_btn.set_sensitive(False)
            sync_btn.set_label("Lade...")

            def run_sync():
                ok, msg = self.config.sync_wallpaper_bank()

                def update_ui():
                    sync_btn.set_sensitive(True)
                    sync_btn.set_label("Synchronisieren")
                    self._show_info("Wallpaper-Bank", msg)
                    self._refresh_content()

                if GLib and hasattr(GLib, "idle_add"):
                    GLib.idle_add(update_ui)
                else:
                    update_ui()

            import threading
            threading.Thread(target=run_sync, daemon=True).start()

        sync_btn.connect("clicked", on_sync_clicked)
        sync_row.add_suffix(sync_btn)
        action_group.add(sync_row)

        # Zufälliges Wallpaper
        rand_row = Adw.ActionRow(
            title="Zufälliges Wallpaper",
            subtitle="Wählt ein zufälliges Bild (Tastenkürzel: SUPER + ALT + W)"
        )
        rand_btn = Gtk.Button(label="Würfeln")
        rand_btn.set_valign(Gtk.Align.CENTER)

        def on_rand_clicked(_):
            import subprocess
            subprocess.Popen(["bash", os.path.expanduser("~/.config/hypr/scripts/wallpaper.sh"), "--random"])
            self._refresh_content()

        rand_btn.connect("clicked", on_rand_clicked)
        rand_row.add_suffix(rand_btn)
        action_group.add(rand_row)

        # Rofi-Kachelauswahl öffnen
        rofi_row = Adw.ActionRow(
            title="Visueller Kachelwähler (Rofi)",
            subtitle="Öffnet die Rasterauswahl (Tastenkürzel: SUPER + W)"
        )
        rofi_btn = Gtk.Button(label="Öffnen")
        rofi_btn.set_valign(Gtk.Align.CENTER)

        def on_rofi_clicked(_):
            import subprocess
            subprocess.Popen(["bash", os.path.expanduser("~/.config/hypr/scripts/wallpaper.sh")])

        rofi_btn.connect("clicked", on_rofi_clicked)
        rofi_row.add_suffix(rofi_btn)
        action_group.add(rofi_row)

        # Wallpaper-Ordner im Dateimanager
        folder_row = Adw.ActionRow(
            title="Wallpaper-Ordner öffnen",
            subtitle="Bilder nach ~/.config/hypr/wallpapers kopieren"
        )
        folder_btn = Gtk.Button(label="Ordner öffnen")
        folder_btn.set_valign(Gtk.Align.CENTER)

        def on_folder_clicked(_):
            import subprocess
            path = os.path.expanduser("~/.config/hypr/wallpapers")
            subprocess.Popen(["xdg-open", path])

        folder_btn.connect("clicked", on_folder_clicked)
        folder_row.add_suffix(folder_btn)
        action_group.add(folder_row)

        box.append(action_group)

        # Galerie aller Wallpaper
        gallery_group = Adw.PreferencesGroup(
            title="Verfügbare Hintergründe",
            description="Klicke auf 'Aktivieren', um das Hintergrundbild sofort zu übernehmen"
        )

        wallpapers = self.config.get_wallpapers()
        if not wallpapers:
            empty_row = Adw.ActionRow(
                title="Keine Hintergründe gefunden",
                subtitle="Klicke oben auf 'Synchronisieren', um die JaKooLit Wallpaper-Bank zu laden"
            )
            gallery_group.add(empty_row)
        else:
            for wp in wallpapers:
                row = Adw.ActionRow(title=wp["name"])
                subtitle = "JaKooLit Wallpaper-Bank" if wp.get("is_bank") else f"Ordner: {wp.get('folder', 'Lokal')}"
                if wp.get("is_current"):
                    subtitle += " • [AKTIV]"
                row.set_subtitle(subtitle)

                apply_btn = Gtk.Button(label="Aktiv" if wp.get("is_current") else "Aktivieren")
                if wp.get("is_current"):
                    apply_btn.add_css_class("suggested-action")
                    apply_btn.set_sensitive(False)
                apply_btn.set_valign(Gtk.Align.CENTER)

                def on_apply_clicked(_, p=wp["path"], name=wp["name"]):
                    self.config.set_wallpaper(p)
                    self._refresh_content()

                apply_btn.connect("clicked", on_apply_clicked)
                row.add_suffix(apply_btn)
                gallery_group.add(row)

        box.append(gallery_group)
        return box

    def _page_keybinds(self) -> Gtk.Widget:
        """Tastenkürzel-Seite (Verweis auf Hotkey-Manager)."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_margin_top(24)
        box.set_margin_bottom(16)
        box.set_margin_start(16)
        box.set_margin_end(16)

        group = Adw.PreferencesGroup(
            title="Tastenkürzel",
            description="Verwende den Hotkey-Manager für die vollständige Tastenkürzel-Verwaltung"
        )

        open_row = Adw.ActionRow(title="Hotkey-Manager öffnen", subtitle="Tastenkürzel anzeigen und bearbeiten")
        open_btn = Gtk.Button(label="Öffnen", valign=Gtk.Align.CENTER)
        open_btn.add_css_class("suggested-action")
        open_btn.connect("clicked", lambda _: self._open_hotkey_manager())
        open_row.add_suffix(open_btn)
        open_row.set_activatable_widget(open_btn)
        group.add(open_row)

        box.append(group)

        # Kurzinfo
        info_group = Adw.PreferencesGroup(title="Wichtige Tastenkürzel")
        shortcuts = [
            ("SUPER + Return", "Terminal öffnen"),
            ("SUPER + D", "App-Launcher"),
            ("SUPER + Q", "Fenster schließen"),
            ("SUPER + E", "Dateimanager"),
            ("SUPER + V", "Fenster schwebend"),
            ("SUPER + F", "Fenster maximieren"),
            ("SUPER + SHIFT + S", "Screenshot (Bereich)"),
            ("SUPER + ALT + S", "Tokyo Shot (Screenshot-Hub)"),
            ("SUPER + SHIFT + X", "Bildschirm sperren"),
            ("SUPER + SHIFT + E", "Power-Menü"),
            ("SUPER + I", "Einstellungen"),
        ]
        for combo, desc in shortcuts:
            row = Adw.ActionRow(title=desc, subtitle=combo)
            info_group.add(row)

        box.append(info_group)
        return box

    def _page_autostart(self) -> Gtk.Widget:
        """Autostart-Programme."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        group = Adw.PreferencesGroup(
            title="Autostart",
            description="Programme, die mit Hyprland gestartet werden.\nBearbeite ~/.config/hypr/autostart.lua für Änderungen."
        )

        programs = [
            ("Hyprpaper", "Hintergrundbilder", True),
            ("Waybar", "Statusleiste", True),
            ("Mako", "Benachrichtigungen", True),
            ("Hyprpolkitagent", "Polkit-Agent", True),
            ("Clipboard-Daemon", "wl-paste + cliphist", True),
        ]

        for name, desc, active in programs:
            row = Adw.ActionRow(title=name, subtitle=desc)
            status = Gtk.Label(label="Aktiv" if active else "Inaktiv")
            status.add_css_class("status-ok" if active else "status-warn")
            row.add_suffix(status)
            group.add(row)

        box.append(group)

        info_label = Gtk.Label(label="Hinweis: Autostart-Änderungen erfordern eine Bearbeitung von autostart.lua")
        info_label.set_margin_start(16)
        info_label.set_halign(Gtk.Align.START)
        info_label.add_css_class("dim-label")
        box.append(info_label)

        return box

    def _page_backup(self) -> Gtk.Widget:
        """Backup und Wiederherstellung."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        group = Adw.PreferencesGroup(title="Backup", description="Konfigurationen sichern und wiederherstellen")

        # Backup erstellen
        backup_row = Adw.ActionRow(title="Backup erstellen", subtitle="Alle Konfigurationen sichern")
        backup_btn = Gtk.Button(label="Backup", valign=Gtk.Align.CENTER)
        backup_btn.add_css_class("suggested-action")
        backup_btn.connect("clicked", self._do_backup)
        backup_row.add_suffix(backup_btn)
        backup_row.set_activatable_widget(backup_btn)
        group.add(backup_row)

        # Wiederherstellen
        restore_row = Adw.ActionRow(
            title="Wiederherstellen",
            subtitle="Starte restore-backup.sh im Terminal"
        )
        restore_btn = Gtk.Button(label="Terminal öffnen", valign=Gtk.Align.CENTER)
        restore_btn.connect("clicked", lambda _: os.system("kitty --title 'Backup' bash -c '~/.config/hypr/scripts/../../../tokyo-hypr-dots/restore-backup.sh; read -p \"Drücke Enter...\"' &"))
        restore_row.add_suffix(restore_btn)
        group.add(restore_row)

        box.append(group)

        # Vorhandene Backups
        backup_base = os.path.expanduser("~/.config/tokyo-hypr-backup")
        if os.path.isdir(backup_base):
            backups_group = Adw.PreferencesGroup(title="Vorhandene Backups")
            try:
                entries = sorted(os.listdir(backup_base), reverse=True)
                for entry in entries[:10]:  # Maximal 10 anzeigen
                    if os.path.isdir(os.path.join(backup_base, entry)):
                        row = Adw.ActionRow(title=entry)
                        backups_group.add(row)
            except OSError:
                pass
            box.append(backups_group)

        return box

    def _page_hardware(self) -> Gtk.Widget:
        """Hardware- und Treiber-Zentrum mit automatischer Erkennung und Aktionen."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        hw = self.config.get_hardware_info()

        # ── 1. Prozessor & Microcode ──────────────────────────
        cpu_group = Adw.PreferencesGroup(
            title="Prozessor (CPU)",
            description="Erkannte CPU-Architektur und Microcode-Treiber"
        )

        cpu_title = hw.get("cpu_model", "Unbekannt")
        cores = hw.get("cpu_cores", 0)
        core_str = f" • {cores} physische Kerne" if cores > 0 else ""
        cpu_sub = f"Hersteller: {hw.get('cpu_vendor', 'Unbekannt')}{core_str}"
        cpu_row = Adw.ActionRow(title=cpu_title, subtitle=cpu_sub)
        cpu_badge = Gtk.Label(label=hw.get("cpu_vendor", "CPU"))
        cpu_badge.add_css_class("hero-badge")
        cpu_row.add_suffix(cpu_badge)
        cpu_group.add(cpu_row)

        ucode_row = Adw.ActionRow(
            title="Microcode-Treiber",
            subtitle=hw.get("microcode", "Nicht geprüft")
        )
        ucode_badge = Gtk.Label(
            label="Optimal" if "Aktiv" in hw.get("microcode", "") else "Prüfen"
        )
        ucode_badge.add_css_class("hero-badge")
        ucode_row.add_suffix(ucode_badge)
        cpu_group.add(ucode_row)

        box.append(cpu_group)

        # ── 2. Grafikkarte & Hyprland-Treiber ─────────────────
        gpu_group = Adw.PreferencesGroup(
            title="Grafikkarte & Treiber (GPU)",
            description="Erkannte PCI-Grafikchips und Wayland-Treiber"
        )

        for gpu in hw.get("gpus", []):
            gpu_row = Adw.ActionRow(title=gpu)
            gpu_group.add(gpu_row)

        nvidia_conf = Path.home() / ".config" / "hypr" / "nvidia.conf"
        has_nvidia_cfg = nvidia_conf.exists()
        nv_row = Adw.ActionRow(
            title="Hyprland NVIDIA Wayland-Konfiguration",
            subtitle="Spezifische GBM/EGL-Wayland-Flags in ~/.config/hypr/nvidia.conf"
                     if has_nvidia_cfg else "Keine spezifischen NVIDIA-Flags aktiv (Open-Source / Intel / AMD Modus)"
        )
        nv_badge = Gtk.Label(label="Aktiv" if has_nvidia_cfg else "Standard")
        nv_badge.add_css_class("hero-badge")
        nv_row.add_suffix(nv_badge)
        gpu_group.add(nv_row)

        box.append(gpu_group)

        # ── 3. Systemtyp & Energie ────────────────────────────
        sys_group = Adw.PreferencesGroup(
            title="System & Energie",
            description="Geräteklasse, Akku-Status und Linux-Kernel"
        )

        sys_type = "Laptop" if hw.get("is_laptop") else "Desktop-PC"
        type_row = Adw.ActionRow(
            title=f"Gerätetyp: {sys_type}",
            subtitle=f"Akku: {hw.get('battery_status', 'Kein Akku')} • RAM: {hw.get('ram_total', 'Unbekannt')}"
        )
        sys_badge = Gtk.Label(label=sys_type)
        sys_badge.add_css_class("hero-badge")
        type_row.add_suffix(sys_badge)
        sys_group.add(type_row)

        kernel_row = Adw.ActionRow(
            title=f"Linux Kernel {hw.get('kernel', 'Unbekannt')}",
            subtitle="Arch Linux rolling release"
        )
        sys_group.add(kernel_row)

        box.append(sys_group)

        # ── 4. Aktionen & Wartungs-Tools ──────────────────────
        actions_group = Adw.PreferencesGroup(
            title="Hardware- & System-Aktionen",
            description="Automatisierte Wartung, Treiberprüfung und Software"
        )

        hw_action = Adw.ActionRow(
            title="Hardware- & Treiber-Check ausführen",
            subtitle="Scannt CPU, GPU, NVIDIA-Treiber, Wayland-Variablen und Laptop-Akku"
        )
        hw_btn = Gtk.Button(label="Check starten", valign=Gtk.Align.CENTER)
        hw_btn.add_css_class("suggested-action")
        hw_btn.connect("clicked", lambda _: os.system(
            "kitty --title 'Hardware- & Treiber-Check' bash -c '"
            "if [[ -x ~/.config/hypr/scripts/hardware-check.sh ]]; then ~/.config/hypr/scripts/hardware-check.sh; "
            "else bash \"$(dirname \"$0\")/../scripts/hardware-check.sh\"; fi; echo; read -p \"Drücke Enter zum Schließen...\"' &"
        ))
        hw_action.add_suffix(hw_btn)
        hw_action.set_activatable_widget(hw_btn)
        actions_group.add(hw_action)

        clean_action = Adw.ActionRow(
            title="System-Cleaner starten",
            subtitle="Bereinigt Pacman- und AUR-Caches, verwaiste Pakete und System-Logs"
        )
        clean_btn = Gtk.Button(label="Bereinigen", valign=Gtk.Align.CENTER)
        clean_btn.connect("clicked", lambda _: os.system(
            "kitty --title 'System-Cleaner' bash -c '"
            "if [[ -x ~/.config/hypr/scripts/clean-system.sh ]]; then ~/.config/hypr/scripts/clean-system.sh; "
            "else bash \"$(dirname \"$0\")/../scripts/clean-system.sh\"; fi; echo; read -p \"Drücke Enter zum Schließen...\"' &"
        ))
        clean_action.add_suffix(clean_btn)
        clean_action.set_activatable_widget(clean_btn)
        actions_group.add(clean_action)

        app_action = Adw.ActionRow(
            title="TUI App-Installer öffnen",
            subtitle="Installiert Chrome, VS Code, Spotify, Spicetify oder Steam"
        )
        app_btn = Gtk.Button(label="Installer starten", valign=Gtk.Align.CENTER)
        app_btn.connect("clicked", lambda _: os.system(
            "kitty --title 'App-Installer' bash -c '"
            "for p in ~/.config/hypr/scripts/app-installer.sh ~/Desktop/hyprland/tokyo-hypr-dots/scripts/app-installer.sh ~/arch-hyprland/scripts/app-installer.sh ~/tokyo-hypr-dots/scripts/app-installer.sh; do "
            "if [[ -f \"$p\" ]]; then bash \"$p\"; exit 0; fi; done; "
            "echo \"App-Installer Skript nicht gefunden.\"; echo; read -p \"Drücke Enter zum Schließen...\"' &"
        ))
        app_action.add_suffix(app_btn)
        app_action.set_activatable_widget(app_btn)
        actions_group.add(app_action)

        box.append(actions_group)
        return box

    def _page_diagnostics(self) -> Gtk.Widget:
        """Diagnostik und Wartung."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        group = Adw.PreferencesGroup(title="Diagnostik & Prüfungen", description="Systemprüfung, Treiberstatus und Fehlersuche")

        # Hardware-Check ausführen
        hw_row = Adw.ActionRow(title="Hardware- & Treiber-Check", subtitle="Automatische Prüfung für CPU-Microcode, GPU (Nvidia/Mesa) und Laptop-Akku")
        hw_btn = Gtk.Button(label="Starten", valign=Gtk.Align.CENTER)
        hw_btn.add_css_class("suggested-action")
        hw_btn.connect("clicked", lambda _: os.system(
            "kitty --title 'Hardware- & Treiber-Check' bash -c '"
            "if [[ -x ~/.config/hypr/scripts/hardware-check.sh ]]; then ~/.config/hypr/scripts/hardware-check.sh; "
            "else bash \"$(dirname \"$0\")/../scripts/hardware-check.sh\"; fi; echo; read -p \"Drücke Enter zum Schließen...\"' &"
        ))
        hw_row.add_suffix(hw_btn)
        hw_row.set_activatable_widget(hw_btn)
        group.add(hw_row)

        # Diagnose ausführen
        diag_row = Adw.ActionRow(title="System-Diagnose ausführen (Doctor)", subtitle="Prüft Systempakete, Wayland-Portals, Audio und Konfigurationen")
        diag_btn = Gtk.Button(label="Starten", valign=Gtk.Align.CENTER)
        diag_btn.connect("clicked", lambda _: os.system("kitty --title 'Diagnose' bash -c '~/.config/hypr/scripts/diagnostics.sh 2>/dev/null || ./doctor.sh; echo; read -p \"Drücke Enter...\"' &"))
        diag_row.add_suffix(diag_btn)
        diag_row.set_activatable_widget(diag_btn)
        group.add(diag_row)

        # System Cleaner
        clean_row = Adw.ActionRow(title="Arch System-Cleaner", subtitle="Bereinigt Pacman/yay Caches, verwaiste Pakete und Systemd-Logs")
        clean_btn = Gtk.Button(label="Starten", valign=Gtk.Align.CENTER)
        clean_btn.connect("clicked", lambda _: os.system("kitty --title 'System-Cleaner' bash -c '~/.config/hypr/scripts/clean-system.sh; echo; read -p \"Drücke Enter...\"' &"))
        clean_row.add_suffix(clean_btn)
        clean_row.set_activatable_widget(clean_btn)
        group.add(clean_row)

        box.append(group)
        return box

    def _page_version_update(self) -> Gtk.Widget:
        """Seite für Version, Update-Prüfung und System-Synchronisation."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        cur_ver = self.config.get_version()

        # ── Hero Banner ──
        hero_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        hero_box.add_css_class("hero-banner")

        hero_text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        title_lbl = Gtk.Label(label=f"Tokyo Night Hyprland v{cur_ver}")
        title_lbl.add_css_class("hero-title")

        status_badge = Gtk.Label(label=f"v{cur_ver}")
        status_badge.add_css_class("hero-badge")
        title_box.append(title_lbl)
        title_box.append(status_badge)

        sub_lbl = Gtk.Label(label="Automatische Update-Prüfung via GitHub & One-Click System-Synchronisation")
        sub_lbl.add_css_class("hero-subtitle")
        sub_lbl.set_halign(Gtk.Align.START)

        hero_text.append(title_box)
        hero_text.append(sub_lbl)
        hero_box.append(hero_text)
        box.append(hero_box)

        # ── Update-Status Karte ──
        status_group = Adw.PreferencesGroup(
            title="Versions- & Update-Status",
            description="Überprüfe den aktuellen Stand mit dem offiziellen GitHub-Repository",
        )

        ver_row = Adw.ActionRow(
            title=f"Installierte Version: v{cur_ver}",
            subtitle="Startet bei 1.0 und erhöht sich nach jedem erfolgreichen Update automatisch um 0.1",
        )
        ver_badge = Gtk.Label(label=f"v{cur_ver}")
        ver_badge.add_css_class("hero-badge")
        ver_row.add_suffix(ver_badge)
        status_group.add(ver_row)

        repo_row = Adw.ActionRow(
            title="GitHub Repository",
            subtitle="https://github.com/venox21/arch-hyprland (origin/main)",
        )
        repo_badge = Gtk.Label(label="origin/main")
        repo_badge.add_css_class("hero-badge")
        repo_row.add_suffix(repo_badge)
        status_group.add(repo_row)

        check_row = Adw.ActionRow(
            title="Update-Prüfung",
            subtitle="Klicke auf 'Auf Updates prüfen', um nach neuen Versionen zu suchen",
        )
        spinner = Gtk.Spinner()
        spinner.set_spinning(False)
        spinner.set_visible(False)
        spinner.set_valign(Gtk.Align.CENTER)
        spinner.set_margin_end(8)
        check_row.add_suffix(spinner)

        check_badge = Gtk.Label(label="Bereit zur Prüfung")
        check_badge.add_css_class("hero-badge")
        check_row.add_suffix(check_badge)
        status_group.add(check_row)

        # Changelog-Container (anfänglich unsichtbar)
        changelog_row = Adw.ActionRow(
            title="Verfügbare Aktualisierungen auf GitHub",
            subtitle="Neue Änderungen in origin/main",
        )
        changelog_row.set_visible(False)
        status_group.add(changelog_row)

        box.append(status_group)

        # ── Aktionen Gruppe ──
        actions_group = Adw.PreferencesGroup(
            title="Update-Aktionen",
            description="Prüfe online auf Neuerungen oder führe das System-Update aus",
        )

        check_action = Adw.ActionRow(
            title="Auf Updates prüfen",
            subtitle="Vergleicht lokale Commits mit GitHub origin/main",
        )
        check_btn = Gtk.Button(label="Jetzt prüfen", valign=Gtk.Align.CENTER)
        check_action.add_suffix(check_btn)
        check_action.set_activatable_widget(check_btn)
        actions_group.add(check_action)

        update_action = Adw.ActionRow(
            title="System aktualisieren & synchronisieren",
            subtitle="Führt update.sh im Terminal aus und erhöht die Versionsnummer um 0.1",
        )
        update_btn = Gtk.Button(label="Update ausführen", valign=Gtk.Align.CENTER)
        update_btn.add_css_class("suggested-action")
        update_action.add_suffix(update_btn)
        update_action.set_activatable_widget(update_btn)
        actions_group.add(update_action)

        box.append(actions_group)

        # Callback für Update-Prüfung im Hintergrund-Thread
        def on_check_clicked(_):
            check_btn.set_sensitive(False)
            spinner.set_visible(True)
            spinner.set_spinning(True)
            check_row.set_subtitle("Verbindung zu GitHub wird geprüft...")
            check_badge.set_label("Prüfe...")

            def worker():
                res = self.config.check_for_updates()

                def update_ui():
                    spinner.set_spinning(False)
                    spinner.set_visible(False)
                    check_btn.set_sensitive(True)

                    msg = res.get("message", "")
                    last_checked = res.get("last_checked", "")
                    check_row.set_subtitle(f"{msg} (Geprüft: {last_checked})")

                    if res.get("update_available"):
                        check_badge.set_label("Update verfügbar!")
                        check_badge.remove_css_class("hero-badge")
                        check_badge.add_css_class("status-warn")
                        status_badge.set_label("Update verfügbar")
                        status_badge.remove_css_class("hero-badge")
                        status_badge.add_css_class("status-warn")

                        changes = res.get("changelog", [])
                        if changes:
                            changelog_row.set_subtitle("\n".join(f"• {c}" for c in changes[:5]))
                            changelog_row.set_visible(True)

                        update_btn.add_css_class("suggested-action")
                    elif res.get("success"):
                        check_badge.set_label("Aktuell")
                        check_badge.remove_css_class("hero-badge")
                        check_badge.add_css_class("status-ok")
                        changelog_row.set_visible(False)
                    else:
                        check_badge.set_label("Offline / Fehler")
                        check_badge.remove_css_class("hero-badge")
                        check_badge.add_css_class("status-error")
                    return False

                GLib.idle_add(update_ui)

            threading.Thread(target=worker, daemon=True).start()

        check_btn.connect("clicked", on_check_clicked)

        # Update ausführen Callback
        def on_update_clicked(_):
            repo = self.config.get_repo_path()
            repo_str = str(repo) if repo else "${HOME}/Desktop/hyprland/tokyo-hypr-dots"
            os.system(
                "kitty --class tokyo-update --title 'Tokyo Night – System-Update' bash -c '"
                f"for d in \"{repo_str}\" ~/.config/hypr/scripts/../../.. ~/Desktop/hyprland/tokyo-hypr-dots ~/arch-hyprland ~/tokyo-hypr-dots; do "
                "if [[ -f \"$d/update.sh\" ]]; then cd \"$d\" && bash ./update.sh; echo; read -p \"Drücke Enter zum Schließen...\"; exit 0; fi; done; "
                "if [[ -f ~/.config/hypr/scripts/update.sh ]]; then bash ~/.config/hypr/scripts/update.sh; echo; read -p \"Drücke Enter...\"; exit 0; fi; "
                "echo \"update.sh nicht gefunden.\"; echo; read -p \"Drücke Enter zum Schließen...\"' &"
            )

        update_btn.connect("clicked", on_update_clicked)

        return box

    # ══════════════════════════════════════════════════════════
    # ██ Hilfsfunktionen
    # ══════════════════════════════════════════════════════════

    def _update_setting(self, section: str, key: str, value):
        """Einstellung aktualisieren und speichern."""
        if section not in self.settings:
            self.settings[section] = {}
        self.settings[section][key] = value
        self.config.save_settings(self.settings)

    def _update_waybar_setting(self, key: str, value):
        """Waybar-Einstellung aktualisieren."""
        self._update_setting("waybar", key, value)

    def _build_waybar_transparency_group(self):
        """Baut die Transparenz-Gruppe (Regler + Prozentfeld) für die Waybar.

        Gibt (Gruppe, refresh) zurück. refresh(layout_id) gleicht den Regler
        nach einem Layout-Wechsel an das neue Layout an.
        """
        group = Adw.PreferencesGroup(
            title="Waybar-Transparenz",
            description="Gilt für den Leistenhintergrund des aktiven Layouts "
                        "(Unschärfe liefert Hyprland)",
        )
        row = Adw.ActionRow(
            title="Transparenz (%)",
            subtitle="0 % = deckend, 100 % = komplett durchsichtig",
        )

        def transparency_for(layout_id: str) -> float:
            return round((1.0 - self.config.get_waybar_opacity(layout_id)) * 100.0)

        def has_bar_background(layout_id: str) -> bool:
            meta = self.config.get_waybar_layouts().get(layout_id, {})
            return bool(meta.get("bar_background", True))

        current = [self.config.get_active_waybar_layout()]
        # Gemeinsame Adjustment: Slider und Zahlenfeld bleiben automatisch synchron
        adj = Gtk.Adjustment(
            value=transparency_for(current[0]),
            lower=0, upper=100, step_increment=1, page_increment=10,
        )
        scale = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=adj)
        scale.set_draw_value(False)
        scale.set_size_request(240, -1)
        scale.set_valign(Gtk.Align.CENTER)
        for mark in (0, 25, 50, 75, 100):
            scale.add_mark(mark, Gtk.PositionType.BOTTOM, None)
        spin = Gtk.SpinButton(adjustment=adj, digits=0)
        spin.set_valign(Gtk.Align.CENTER)
        row.add_suffix(scale)
        row.add_suffix(spin)
        group.add(row)

        state = {"timer": 0, "silent": False}

        def commit():
            state["timer"] = 0
            opacity = 1.0 - adj.get_value() / 100.0
            self.config.apply_waybar_opacity(opacity, current[0])
            return False  # Timer nur einmal auslösen

        def on_changed(_adj):
            if state["silent"]:
                return
            # Entprellen: erst anwenden, wenn der Regler kurz still steht
            if state["timer"]:
                GLib.source_remove(state["timer"])
            state["timer"] = GLib.timeout_add(250, commit)

        adj.connect("value-changed", on_changed)

        def refresh(layout_id: str):
            current[0] = layout_id
            state["silent"] = True
            adj.set_value(transparency_for(layout_id))
            state["silent"] = False
            usable = has_bar_background(layout_id)
            row.set_sensitive(usable)
            row.set_subtitle(
                "0 % = deckend, 100 % = komplett durchsichtig" if usable
                else "Dieses Layout hat keinen Leistenhintergrund – Regler ohne Wirkung"
            )

        refresh(current[0])
        return group, refresh

    def _apply_waybar_settings(self, _button=None):
        """Waybar-Einstellungen anwenden und Waybar neu starten."""
        self.config.save_settings(self.settings)

        # Waybar-Konfiguration aktualisieren basierend auf gespeicherten Einstellungen
        wb_config = self.config.load_waybar_config()
        if wb_config:
            wb = self.settings.get("waybar", {})
            wb_config["position"] = wb.get("position", "top")
            wb_config["height"] = wb.get("height", 36)
            self.config.save_waybar_config(wb_config)

        self.config.restart_waybar()

    def _apply_and_save(self):
        """Einstellungen speichern und Hyprland neu laden."""
        self.config.save_settings(self.settings)
        self.config.reload_hyprland()

    def _do_backup(self, _button):
        """Backup erstellen und Ergebnis anzeigen."""
        path = self.config.create_backup("manual")
        if path:
            dialog = Adw.AlertDialog(
                heading="Backup erstellt",
                body=f"Gespeichert in:\n{path}",
            )
            dialog.add_response("ok", "OK")
            dialog.present(self)

    def _refresh_content(self):
        """Aktualisiert die aktuell ausgewählte Seite."""
        row = self.nav_list.get_selected_row()
        if row:
            self._on_nav_selected(self.nav_list, row)

    def _show_info(self, heading: str, body: str):
        """Zeigt einen libadwaita Hinweisdialog an."""
        dialog = Adw.AlertDialog(heading=heading, body=body)
        dialog.add_response("ok", "OK")
        dialog.present(self)


def main():
    app = TokyoSettingsApp()
    app.run(sys.argv)


if __name__ == "__main__":
    main()
