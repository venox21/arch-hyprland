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
        @classmethod
        def new_with_range(cls, *a, **kw): return cls()
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
        SelectionMode = type("SelectionMode", (), {"SINGLE": 0})
        Orientation = type("Orientation", (), {"VERTICAL": 0, "HORIZONTAL": 1})
        Align = type("Align", (), {"CENTER": 0, "START": 1, "END": 2})
        ScrolledWindow = _MockBase
        Label = _MockBase
        Image = _MockBase
        FlowBox = _MockBase
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
        self.set_default_size(900, 650)
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
            ("Waybar", [
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
            ("Netzwerk", [
                "network-wireless-symbolic",
                "network-wireless-signal-excellent-symbolic",
                "network-workgroup-symbolic",
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
            ("Diagnostik", [
                "dialog-information-symbolic",
                "help-browser-symbolic",
                "utilities-terminal-symbolic",
            ], self._page_diagnostics),
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
        """Tokyo Night CSS anwenden."""
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
        @define-color headerbar_border_color rgba(51, 70, 124, 0.45);

        @define-color card_bg_color #24283b;
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
            border-bottom: 1px solid rgba(51, 70, 124, 0.45);
            box-shadow: none;
            padding: 6px 12px;
        }

        headerbar windowhandle {
            background: transparent;
        }

        headerbar .title {
            color: #7aa2f7;
            font-weight: 700;
        }

        headerbar .subtitle {
            color: #a9b1d6;
            font-size: 11px;
        }

        /* Sidebar Navigation */
        .navigation-sidebar {
            background-color: #16161e;
            border-right: 1px solid rgba(41, 46, 66, 0.85);
            padding: 10px 8px;
        }

        .navigation-sidebar row {
            padding: 9px 12px;
            margin: 3px 6px;
            border-radius: 9px;
            color: #a9b1d6;
            background-color: transparent;
            transition: all 120ms ease;
        }

        .navigation-sidebar row:hover {
            background-color: rgba(122, 162, 247, 0.12);
            color: #c0caf5;
        }

        .navigation-sidebar row:selected {
            background-color: rgba(122, 162, 247, 0.22);
            color: #7aa2f7;
            font-weight: bold;
            border-left: 3px solid #7aa2f7;
        }

        .navigation-sidebar row image {
            margin-right: 6px;
            color: #7aa2f7;
        }

        /* Content-Bereich & Cards */
        scrolledwindow, viewport {
            background-color: #1a1b26;
        }

        preferencesgroup > box {
            margin-bottom: 14px;
        }

        preferencesgroup > box > label {
            color: #7aa2f7;
            font-weight: 700;
            font-size: 13px;
            letter-spacing: 0.3px;
            margin-bottom: 6px;
        }

        .card, preferencesgroup list {
            background-color: #24283b;
            border: 1px solid rgba(122, 162, 247, 0.16);
            border-radius: 12px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
            color: #c0caf5;
        }

        preferencesgroup list > row {
            padding: 12px 16px;
            border-bottom: 1px solid rgba(41, 46, 66, 0.6);
            color: #c0caf5;
            background-color: transparent;
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
            color: #9aa5ce;
            font-size: 11px;
            margin-top: 2px;
        }

        /* Buttons */
        button {
            background-color: #292e42;
            color: #c0caf5;
            border: 1px solid #33467c;
            border-radius: 8px;
            padding: 7px 16px;
            font-weight: 600;
            font-size: 12px;
            transition: all 120ms ease;
        }

        button:hover {
            background-color: #33467c;
            color: #ffffff;
            border-color: #7aa2f7;
            box-shadow: 0 0 8px rgba(122, 162, 247, 0.25);
        }

        button:active {
            background-color: #414868;
        }

        button.suggested-action {
            background-color: #7aa2f7;
            color: #1a1b26;
            border: none;
            font-weight: 700;
        }

        button.suggested-action:hover {
            background-color: #89b4fa;
            color: #16161e;
            box-shadow: 0 0 12px rgba(122, 162, 247, 0.4);
        }

        button.destructive-action {
            background-color: #f7768e;
            color: #1a1b26;
            border: none;
            font-weight: 700;
        }

        button.destructive-action:hover {
            background-color: #ff8b9e;
            box-shadow: 0 0 12px rgba(247, 118, 142, 0.4);
        }

        /* Switches */
        switch {
            background-color: #1f2335;
            border: 1px solid #33467c;
            border-radius: 14px;
            min-width: 44px;
            min-height: 24px;
        }

        switch:checked {
            background-color: #7aa2f7;
            border-color: #7aa2f7;
        }

        switch slider {
            background-color: #c0caf5;
            border-radius: 12px;
            min-width: 18px;
            min-height: 18px;
            margin: 2px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }

        switch:checked slider {
            background-color: #1a1b26;
        }

        /* Eingabefelder */
        entry, spinbutton {
            background-color: #1f2335;
            color: #c0caf5;
            border: 1px solid #33467c;
            border-radius: 8px;
            padding: 7px 12px;
        }

        entry:focus, spinbutton:focus {
            border-color: #7aa2f7;
            box-shadow: 0 0 0 1px #7aa2f7;
        }

        /* Dropdowns */
        popover, popover.background, popover contents {
            background-color: #1f2335;
            border: 1px solid #33467c;
            border-radius: 10px;
            color: #c0caf5;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5);
        }

        popover listview row {
            padding: 8px 12px;
            color: #c0caf5;
        }

        popover listview row:hover {
            background-color: rgba(122, 162, 247, 0.15);
        }

        popover listview row:selected {
            background-color: rgba(122, 162, 247, 0.25);
            color: #7aa2f7;
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
        }

        scrollbar slider:hover {
            background-color: rgba(122, 162, 247, 0.5);
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

    # ══════════════════════════════════════════════════════════
    # ██ Seiten
    # ══════════════════════════════════════════════════════════

    def _page_general(self) -> Gtk.Widget:
        """Allgemeine Informationen."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        # Systeminformationen
        group = Adw.PreferencesGroup(title="System", description="Allgemeine Informationen")

        version_row = Adw.ActionRow(title="Hyprland-Version")
        version_row.set_subtitle(self.config.get_hyprland_version())
        group.add(version_row)

        monitors = self.config.get_monitors()
        mon_row = Adw.ActionRow(title="Monitore")
        mon_row.set_subtitle(f"{len(monitors)} erkannt" if monitors else "Keine Daten (Hyprland läuft nicht?)")
        group.add(mon_row)

        box.append(group)

        # Aktionen
        actions = Adw.PreferencesGroup(title="Aktionen")

        reload_row = Adw.ActionRow(title="Konfiguration neu laden", subtitle="Hyprland und Waybar")
        reload_btn = Gtk.Button(label="Neu laden", valign=Gtk.Align.CENTER)
        reload_btn.add_css_class("suggested-action")
        reload_btn.connect("clicked", lambda _: (self.config.reload_hyprland(), self.config.restart_waybar()))
        reload_row.add_suffix(reload_btn)
        reload_row.set_activatable_widget(reload_btn)
        actions.add(reload_row)

        box.append(actions)
        return box

    def _page_waybar(self) -> Gtk.Widget:
        """Waybar-Einstellungen."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        wb = self.settings.get("waybar", {})

        group = Adw.PreferencesGroup(title="Waybar", description="Leisteneinstellungen")

        # Position
        pos_row = Adw.ComboRow(title="Position")
        pos_model = Gtk.StringList.new(["Oben", "Unten"])
        pos_row.set_model(pos_model)
        pos_row.set_selected(0 if wb.get("position", "top") == "top" else 1)
        pos_row.connect("notify::selected", lambda r, _: self._update_waybar_setting(
            "position", "top" if r.get_selected() == 0 else "bottom"))
        group.add(pos_row)

        # Höhe
        height_row = Adw.SpinRow.new_with_range(24, 60, 2)
        height_row.set_title("Leistenhöhe")
        height_row.set_value(wb.get("height", 36))
        height_row.connect("notify::value", lambda r, _: self._update_waybar_setting(
            "height", int(r.get_value())))
        group.add(height_row)

        # Schriftgröße
        font_row = Adw.SpinRow.new_with_range(9, 18, 1)
        font_row.set_title("Schriftgröße")
        font_row.set_value(wb.get("font_size", 13))
        font_row.connect("notify::value", lambda r, _: self._update_waybar_setting(
            "font_size", int(r.get_value())))
        group.add(font_row)

        # Tray
        tray_row = Adw.SwitchRow(title="System-Tray anzeigen")
        tray_row.set_active(wb.get("show_tray", True))
        tray_row.connect("notify::active", lambda r, _: self._update_waybar_setting(
            "show_tray", r.get_active()))
        group.add(tray_row)

        box.append(group)

        # Speichern & Anwenden
        apply_btn = Gtk.Button(label="Anwenden und Waybar neu starten")
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

        def on_tz_changed(r, _):
            idx = r.get_selected()
            if idx < len(tz_options):
                chosen_tz = tz_options[idx][1]
                ok, msg = self.config.set_timezone(chosen_tz)
                if ok:
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
        """Monitore & Bildschirme – Auflösung, Hz und Skalierung."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        # Aktuelle Monitore
        mon_group = Adw.PreferencesGroup(title="Erkannte Monitore", description="Aktuell an das System angeschlossene Displays")
        monitors = self.config.get_monitors()
        primary_name = ""
        if monitors and isinstance(monitors, list):
            for m in monitors:
                name = m.get("name", "Display")
                if not primary_name:
                    primary_name = name
                w = m.get("width", 1920)
                h = m.get("height", 1080)
                hz = m.get("refreshRate", 60)
                scale = m.get("scale", 1.0)
                row = Adw.ActionRow(
                    title=f"Monitor: {name}",
                    subtitle=f"Auflösung: {w}x{h} @ {hz:.0f} Hz  |  Skalierung: {scale:.2f}x",
                )
                mon_group.add(row)
        else:
            mon_group.add(Adw.ActionRow(title="Keine Monitordaten", subtitle="Hyprland läuft nicht oder kein Display erkannt"))
        box.append(mon_group)

        # Bildschirmeinstellungen
        cfg_group = Adw.PreferencesGroup(title="Bildschirm-Einstellungen", description="Auflösung, Bildwiederholrate (Hz) und Skalierung festlegen")

        hz_row = Adw.ComboRow(title="Bildwiederholfrequenz (Hz)", subtitle="Höhere Hz-Werte sorgen für flüssigere Bewegungen")
        hz_options = [
            ("Automatisch (Standard)", 0),
            ("60 Hz (Standard)", 60),
            ("75 Hz", 75),
            ("120 Hz", 120),
            ("144 Hz (Gaming)", 144),
            ("165 Hz (Gaming)", 165),
            ("240 Hz (High Refresh)", 240),
        ]
        hz_row.set_model(Gtk.StringList.new([opt[0] for opt in hz_options]))
        hz_row.set_selected(0)
        cfg_group.add(hz_row)

        res_row = Adw.ComboRow(title="Auflösung", subtitle="Native Pixelauflösung des Bildschirms")
        res_options = [
            ("Automatisch / Bevorzugt", 0, 0),
            ("1920 x 1080 (Full HD 1080p)", 1920, 1080),
            ("2560 x 1440 (2K / WQHD 1440p)", 2560, 1440),
            ("3840 x 2160 (4K / UHD)", 3840, 2160),
            ("1366 x 768 (Laptop HD)", 1366, 768),
        ]
        res_row.set_model(Gtk.StringList.new([opt[0] for opt in res_options]))
        res_row.set_selected(0)
        cfg_group.add(res_row)

        scale_row = Adw.ComboRow(title="Skalierung (UI-Größe)", subtitle="Vergrößert Schrift und Fenster auf hochauflösenden Displays")
        scale_options = [
            ("100% (1.0x - Normal)", 1.0),
            ("125% (1.25x)", 1.25),
            ("150% (1.5x)", 1.5),
            ("175% (1.75x)", 1.75),
            ("200% (2.0x - HiDPI)", 2.0),
        ]
        scale_row.set_model(Gtk.StringList.new([opt[0] for opt in scale_options]))
        scale_row.set_selected(0)
        cfg_group.add(scale_row)
        box.append(cfg_group)

        apply_btn = Gtk.Button(label="Monitoreinstellungen speichern & anwenden")
        apply_btn.add_css_class("suggested-action")
        apply_btn.set_margin_start(16)
        apply_btn.set_margin_end(16)

        def on_apply_monitor(_):
            hz_idx = hz_row.get_selected()
            res_idx = res_row.get_selected()
            sc_idx = scale_row.get_selected()

            hz_val = hz_options[hz_idx][1] if hz_idx < len(hz_options) else 0
            w_val = res_options[res_idx][1] if res_idx < len(res_options) else 0
            h_val = res_options[res_idx][2] if res_idx < len(res_options) else 0
            sc_val = scale_options[sc_idx][1] if sc_idx < len(scale_options) else 1.0

            ok = self.config.save_monitor_config(primary_name, w_val, h_val, hz_val, sc_val)
            if ok:
                self._show_info("Monitore", "Bildschirmeinstellungen erfolgreich in monitors.lua gespeichert und angewendet!")
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
        """Netzwerk-Einstellungen."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        net = self.settings.get("network", {})
        group = Adw.PreferencesGroup(title="Netzwerk", description="Netzwerkanzeige in der Leiste")

        speed_row = Adw.SwitchRow(title="Geschwindigkeit anzeigen")
        speed_row.set_active(net.get("show_speed", True))
        speed_row.connect("notify::active", lambda r, _: self._update_setting("network", "show_speed", r.get_active()))
        group.add(speed_row)

        ip_row = Adw.SwitchRow(title="IP-Adresse anzeigen")
        ip_row.set_active(net.get("show_ip", False))
        ip_row.connect("notify::active", lambda r, _: self._update_setting("network", "show_ip", r.get_active()))
        group.add(ip_row)

        box.append(group)
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

        # Waybar-Transparenz
        wb_group = Adw.PreferencesGroup(title="Waybar-Transparenz")
        wb_transp = Adw.SpinRow.new_with_range(50, 100, 5)
        wb_transp.set_title("Waybar-Transparenz (%)")
        wb_transp.set_value(int(self.settings.get("waybar", {}).get("transparency", 0.85) * 100))
        wb_transp.connect("notify::value", lambda r, _: self._update_waybar_setting(
            "transparency", r.get_value() / 100.0))
        wb_group.add(wb_transp)

        box.append(wb_group)
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

    def _page_diagnostics(self) -> Gtk.Widget:
        """Diagnostik und Updates."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        group = Adw.PreferencesGroup(title="Diagnostik", description="Systemprüfung und Fehlersuche")

        # Diagnose ausführen
        diag_row = Adw.ActionRow(title="Diagnose ausführen", subtitle="Prüft System, Pakete und Konfigurationen")
        diag_btn = Gtk.Button(label="Starten", valign=Gtk.Align.CENTER)
        diag_btn.add_css_class("suggested-action")
        diag_btn.connect("clicked", lambda _: os.system("kitty --title 'Diagnose' bash -c '~/.config/hypr/scripts/diagnostics.sh; echo; read -p \"Drücke Enter...\"' &"))
        diag_row.add_suffix(diag_btn)
        diag_row.set_activatable_widget(diag_btn)
        group.add(diag_row)

        box.append(group)
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
