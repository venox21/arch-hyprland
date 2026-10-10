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

# Sicherstellen, dass der Settings-Ordner im Pfad ist
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import gi  # pyrefly: ignore[missing-import]
    gi.require_version("Gtk", "4.0")
    gi.require_version("Adw", "1")
    from gi.repository import Gtk, Adw, Gio, GLib  # pyrefly: ignore[missing-import]
except ImportError:
    class _MockBase:
        def __init__(self, *args, **kwargs):
            pass
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
        ScrolledWindow = _MockBase
        Label = _MockBase
        Image = _MockBase
        FlowBox = _MockBase
    class _MockGio:
        class ApplicationFlags:
            FLAGS_NONE = 0
    Adw = _MockAdw()
    Gtk = _MockGtk()
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
        win = SettingsWindow(application=self, config=self.config)
        win.present()


class SettingsWindow(Adw.ApplicationWindow):
    """Hauptfenster mit Seitennavigation."""

    def __init__(self, config: ConfigManager, **kwargs):
        super().__init__(**kwargs)
        self.config = config
        self.settings = config.load_settings()

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

        # ── Seiten definieren ─────────────────────────────────
        self.pages = [
            ("Allgemein",              "preferences-system-symbolic",       self._page_general),
            ("Waybar",                 "view-app-grid-symbolic",            self._page_waybar),
            ("Uhr und Datum",          "preferences-system-time-symbolic",  self._page_clock),
            ("Systemleistung",         "utilities-system-monitor-symbolic", self._page_performance),
            ("Netzwerk",               "network-wireless-symbolic",         self._page_network),
            ("Audio",                  "audio-volume-high-symbolic",        self._page_audio),
            ("Fenster und Animationen","preferences-desktop-display-symbolic", self._page_appearance),
            ("Farben und Transparenz", "preferences-color-symbolic",        self._page_colors),
            ("Hintergrundbilder",      "preferences-desktop-wallpaper-symbolic", self._page_wallpaper),
            ("Tastenkürzel",           "input-keyboard-symbolic",           self._page_keybinds),
            ("Autostart",              "media-playback-start-symbolic",     self._page_autostart),
            ("Backup",                 "drive-harddisk-symbolic",           self._page_backup),
            ("Diagnostik",             "dialog-information-symbolic",       self._page_diagnostics),
        ]

        for title, icon_name, _ in self.pages:
            row = Adw.ActionRow(title=title)
            row.set_icon_name(icon_name)
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
        .navigation-sidebar row {
            padding: 4px 8px;
            margin: 1px 4px;
            border-radius: 8px;
        }
        .navigation-sidebar row:selected {
            background: alpha(#7aa2f7, 0.15);
        }
        .settings-group {
            margin: 8px 16px;
        }
        .status-ok { color: #9ece6a; }
        .status-warn { color: #e0af68; }
        .status-error { color: #f7768e; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
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

            # Scroll-Container
            scroll = Gtk.ScrolledWindow()
            scroll.set_vexpand(True)
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
        """Uhr-Einstellungen."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

        clock = self.settings.get("clock", {})
        group = Adw.PreferencesGroup(title="Uhr", description="Uhrzeit und Datumseinstellungen")

        # 24-Stunden-Format
        fmt_row = Adw.SwitchRow(title="24-Stunden-Format")
        fmt_row.set_active(clock.get("format_24h", True))
        fmt_row.connect("notify::active", lambda r, _: self._update_setting("clock", "format_24h", r.get_active()))
        group.add(fmt_row)

        # Datum anzeigen
        date_row = Adw.SwitchRow(title="Datum anzeigen")
        date_row.set_active(clock.get("show_date", False))
        date_row.connect("notify::active", lambda r, _: self._update_setting("clock", "show_date", r.get_active()))
        group.add(date_row)

        # Datumsformat
        datefmt_row = Adw.ComboRow(title="Datumsformat")
        formats = Gtk.StringList.new(["%d.%m.%Y", "%d/%m/%Y", "%Y-%m-%d", "%d. %B %Y"])
        datefmt_row.set_model(formats)
        current_fmt = clock.get("date_format", "%d.%m.%Y")
        fmt_list = ["%d.%m.%Y", "%d/%m/%Y", "%Y-%m-%d", "%d. %B %Y"]
        datefmt_row.set_selected(fmt_list.index(current_fmt) if current_fmt in fmt_list else 0)
        datefmt_row.connect("notify::selected", lambda r, _: self._update_setting(
            "clock", "date_format", fmt_list[r.get_selected()] if r.get_selected() < len(fmt_list) else fmt_list[0]))
        group.add(datefmt_row)

        # Sekunden
        sec_row = Adw.SwitchRow(title="Sekunden anzeigen")
        sec_row.set_active(clock.get("show_seconds", False))
        sec_row.connect("notify::active", lambda r, _: self._update_setting("clock", "show_seconds", r.get_active()))
        group.add(sec_row)

        # Zeitzone
        tz_row = Adw.SwitchRow(title="Zeitzone anzeigen")
        tz_row.set_active(clock.get("show_timezone", False))
        tz_row.connect("notify::active", lambda r, _: self._update_setting("clock", "show_timezone", r.get_active()))
        group.add(tz_row)

        # Tooltip
        tip_row = Adw.SwitchRow(title="Tooltip aktivieren")
        tip_row.set_active(clock.get("tooltip_enabled", True))
        tip_row.connect("notify::active", lambda r, _: self._update_setting("clock", "tooltip_enabled", r.get_active()))
        group.add(tip_row)

        box.append(group)

        # Speichern
        apply_btn = Gtk.Button(label="Anwenden und Waybar neu starten")
        apply_btn.add_css_class("suggested-action")
        apply_btn.set_margin_start(16)
        apply_btn.set_margin_end(16)
        apply_btn.connect("clicked", self._apply_waybar_settings)
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
        """Farben und Transparenz."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(16)
        box.set_margin_bottom(16)

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
