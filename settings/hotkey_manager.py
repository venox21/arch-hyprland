#!/usr/bin/env python3
# pyrefly: ignore-all-errors  -- gi/GTK4 nur auf Arch Linux (python-gobject) verfügbar
"""
╔══════════════════════════════════════════════════════════════╗
║  Tokyo Night Hyprland – Hotkey-Manager                       ║
║  GTK4 GUI zum Anzeigen, Suchen, Bearbeiten und Verwalten     ║
║  aller Tastenkürzel aus keybinds.lua                         ║
╚══════════════════════════════════════════════════════════════╝
"""

import sys
import os
import re
import shutil
from datetime import datetime
from pathlib import Path
from typing import Optional

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import gi  # pyrefly: ignore[missing-import]
    gi.require_version("Gtk", "4.0")
    gi.require_version("Adw", "1")
    from gi.repository import Gtk, Adw, Gio, GLib, Pango  # pyrefly: ignore[missing-import]
except ImportError:
    class _MockBase:
        def __init__(self, *args, **kwargs):
            pass
    class _MockAdw:
        Application = _MockBase
        ApplicationWindow = _MockBase
    class _MockGtk:
        Box = _MockBase
        Button = _MockBase
    class _MockGio:
        class ApplicationFlags:
            FLAGS_NONE = 0
    Adw = _MockAdw()
    Gtk = _MockGtk()
    Gio = _MockGio()
    GLib = None
    Pango = None


class Keybinding:
    """Repräsentiert eine einzelne Tastenbelegung."""

    def __init__(self, keys: str, action: str, category: str = "Sonstiges",
                 description: str = "", line_number: int = 0, raw_line: str = ""):
        self.keys = keys
        self.action = action
        self.category = category
        self.description = description
        self.line_number = line_number
        self.raw_line = raw_line


class KeybindParser:
    """Parser für Hyprland keybinds.lua – liest die tatsächlichen Bindings."""

    BIND_PATTERN = re.compile(
        r'hl\.bind\(\s*"([^"]+)"\s*,\s*(.+?)\s*(?:,\s*\{[^}]*\})?\s*\)',
        re.DOTALL
    )

    COMMENT_PATTERN = re.compile(r'^--\s*(.*)')

    CATEGORY_MARKERS = {
        "Anwendungen":   re.compile(r'██\s*Anwendungen'),
        "Fenster":       re.compile(r'██\s*Fenster'),
        "Fokus":         re.compile(r'██\s*Fokus'),
        "Verschieben":   re.compile(r'██\s*Fenster verschieben'),
        "Größe ändern":  re.compile(r'██\s*Fenstergröße'),
        "Workspaces":    re.compile(r'██\s*Workspaces'),
        "Maus":          re.compile(r'██\s*Maus'),
        "Audio":         re.compile(r'██\s*Audio'),
        "Helligkeit":    re.compile(r'██\s*Helligkeit'),
        "Screenshots":   re.compile(r'██\s*Screenshots'),
        "Zwischenablage": re.compile(r'██\s*Zwischenablage'),
        "System":        re.compile(r'██\s*(Bildschirmsperre|Sonstiges)'),
    }

    def __init__(self, filepath: str):
        self.filepath = Path(filepath)

    def parse(self) -> list[Keybinding]:
        """Parst alle Keybindings aus der Lua-Datei."""
        if not self.filepath.exists():
            return []

        bindings = []
        current_category = "Sonstiges"
        last_comment = ""

        try:
            content = self.filepath.read_text(encoding="utf-8")
            lines = content.split("\n")
        except OSError:
            return []

        for line_num, line in enumerate(lines, 1):
            stripped = line.strip()

            # Kategorie-Erkennung
            for cat_name, pattern in self.CATEGORY_MARKERS.items():
                if pattern.search(stripped):
                    current_category = cat_name
                    break

            # Kommentar als Beschreibung merken
            comment_match = self.COMMENT_PATTERN.match(stripped)
            if comment_match and not stripped.startswith("-- ══"):
                last_comment = comment_match.group(1).strip()
                continue

            # Binding erkennen
            bind_match = self.BIND_PATTERN.search(line)
            if bind_match:
                keys = bind_match.group(1).strip()
                action_raw = bind_match.group(2).strip()

                # Action-String vereinfachen
                action = self._simplify_action(action_raw)
                desc = last_comment if last_comment else action

                bindings.append(Keybinding(
                    keys=keys,
                    action=action,
                    category=current_category,
                    description=desc,
                    line_number=line_num,
                    raw_line=line.strip(),
                ))
                last_comment = ""

            # Schleifenbindings erkennen (for i = 1, 9 do ...)
            if "for i = 1" in stripped and "hl.bind" not in stripped:
                # Die nächsten Zeilen enthalten die eigentlichen Bindings
                continue

        return bindings

    def _simplify_action(self, action: str) -> str:
        """Vereinfacht die Action-Darstellung."""
        # hl.dsp.exec_cmd("...") → den Befehl extrahieren
        exec_match = re.search(r'hl\.dsp\.exec_cmd\(\s*["\'](.+?)["\']\s*\)', action)
        if exec_match:
            return exec_match.group(1)

        # hl.dsp.window.close() → window.close
        dsp_match = re.search(r'hl\.dsp\.(.+?)(?:\(|$)', action)
        if dsp_match:
            return dsp_match.group(1).rstrip("()")

        # hl.dsp.workspace.go(X) → workspace X
        ws_match = re.search(r'hl\.dsp\.workspace\.go\((.+?)\)', action)
        if ws_match:
            return f"Workspace {ws_match.group(1)}"

        return action

    def update_binding(self, old_keys: str, new_keys: str) -> bool:
        """Ändert eine Tastenbelegung in der Datei."""
        if not self.filepath.exists():
            return False

        try:
            content = self.filepath.read_text(encoding="utf-8")
            # Escapen für Regex
            old_escaped = re.escape(old_keys)
            # Ersetze nur die Tastenkombination, nicht die Action
            new_content = re.sub(
                rf'(hl\.bind\(\s*"){old_escaped}(")',
                rf'\g<1>{new_keys}\g<2>',
                content,
                count=1
            )

            if content == new_content:
                return False

            self._backup()
            self.filepath.write_text(new_content, encoding="utf-8")
            return True

        except OSError:
            return False

    def add_binding(self, keys: str, action: str, category: str = "Sonstiges") -> bool:
        """Fügt eine neue Tastenbelegung hinzu."""
        if not self.filepath.exists():
            return False

        try:
            content = self.filepath.read_text(encoding="utf-8")
            new_line = f'\nhl.bind("{keys}",{" " * max(1, 25 - len(keys))}hl.dsp.exec_cmd("{action}"))\n'

            self._backup()
            content += new_line
            self.filepath.write_text(content, encoding="utf-8")
            return True

        except OSError:
            return False

    def remove_binding(self, keys: str) -> bool:
        """Entfernt eine Tastenbelegung."""
        if not self.filepath.exists():
            return False

        try:
            content = self.filepath.read_text(encoding="utf-8")
            lines = content.split("\n")
            new_lines = []
            removed = False

            for line in lines:
                if f'hl.bind("{keys}"' in line and not removed:
                    removed = True
                    continue  # Zeile überspringen
                new_lines.append(line)

            if not removed:
                return False

            self._backup()
            self.filepath.write_text("\n".join(new_lines), encoding="utf-8")
            return True

        except OSError:
            return False

    def find_conflicts(self, keys: str, exclude_keys: str = "") -> list[Keybinding]:
        """Findet Konflikte für eine Tastenkombination."""
        bindings = self.parse()
        return [b for b in bindings if b.keys == keys and b.keys != exclude_keys]

    def _backup(self):
        """Erstellt ein Backup vor Änderungen."""
        if self.filepath.exists():
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_dir = self.filepath.parent / "backups"
            backup_dir.mkdir(exist_ok=True)
            shutil.copy2(self.filepath, backup_dir / f"keybinds_{timestamp}.lua")

    def restore_default(self) -> bool:
        """Stellt die Standard-Keybindings wieder her."""
        backup_dir = self.filepath.parent / "backups"
        if not backup_dir.exists():
            return False

        backups = sorted(backup_dir.glob("keybinds_*.lua"))
        if not backups:
            return False

        # Ältestes Backup = Original
        try:
            shutil.copy2(backups[0], self.filepath)
            return True
        except OSError:
            return False


class HotkeyManagerApp(Adw.Application):
    """GTK4 Hotkey-Manager-Anwendung."""

    def __init__(self):
        super().__init__(
            application_id="de.tokyo-hypr.hotkeys",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        keybinds_path = os.path.expanduser("~/.config/hypr/keybinds.lua")
        self.parser = KeybindParser(keybinds_path)

    def do_activate(self):
        win = HotkeyManagerWindow(application=self, parser=self.parser)
        win.present()


class HotkeyManagerWindow(Adw.ApplicationWindow):
    """Hauptfenster des Hotkey-Managers."""

    def __init__(self, parser: KeybindParser, **kwargs):
        super().__init__(**kwargs)
        self.parser = parser
        self.bindings: list[Keybinding] = []

        self.set_title("Tokyo Night – Tastenkürzel")
        self.set_default_size(800, 600)

        # ── Haupt-Layout ──────────────────────────────────────
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.set_content(main_box)

        # Header
        header = Adw.HeaderBar()
        header.set_title_widget(Adw.WindowTitle(
            title="Tastenkürzel",
            subtitle="Hotkey-Manager"
        ))

        # Toolbar-Buttons
        reload_btn = Gtk.Button(icon_name="view-refresh-symbolic", tooltip_text="Neu laden")
        reload_btn.connect("clicked", lambda _: self._load_bindings())
        header.pack_start(reload_btn)

        add_btn = Gtk.Button(icon_name="list-add-symbolic", tooltip_text="Neue Tastenkombination")
        add_btn.add_css_class("suggested-action")
        add_btn.connect("clicked", self._on_add_binding)
        header.pack_end(add_btn)

        restore_btn = Gtk.Button(icon_name="edit-undo-symbolic", tooltip_text="Standard wiederherstellen")
        restore_btn.connect("clicked", self._on_restore_defaults)
        header.pack_end(restore_btn)

        main_box.append(header)

        # Suchleiste
        search_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        search_bar.set_margin_start(12)
        search_bar.set_margin_end(12)
        search_bar.set_margin_top(8)
        search_bar.set_margin_bottom(8)

        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_placeholder_text("Suchen (Funktion oder Taste)...")
        self.search_entry.set_hexpand(True)
        self.search_entry.connect("search-changed", self._on_search_changed)
        search_bar.append(self.search_entry)

        # Kategorie-Filter
        self.category_dropdown = Gtk.DropDown()
        self.category_dropdown.connect("notify::selected", lambda *_: self._filter_bindings())
        search_bar.append(self.category_dropdown)

        main_box.append(search_bar)

        # Trennlinie
        main_box.append(Gtk.Separator())

        # Scrollbare Liste
        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)

        self.list_box = Gtk.ListBox()
        self.list_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self.list_box.add_css_class("boxed-list")
        self.list_box.set_margin_start(12)
        self.list_box.set_margin_end(12)
        self.list_box.set_margin_top(8)
        self.list_box.set_margin_bottom(12)
        scroll.set_child(self.list_box)

        main_box.append(scroll)

        # Statusleiste
        self.status_bar = Gtk.Label(halign=Gtk.Align.START)
        self.status_bar.set_margin_start(12)
        self.status_bar.set_margin_bottom(8)
        self.status_bar.add_css_class("dim-label")
        main_box.append(self.status_bar)

        # CSS
        self._apply_css()

        # Bindings laden
        self._load_bindings()

    def _apply_css(self):
        css = b"""
        .keybind-keys {
            font-family: "JetBrainsMono Nerd Font", monospace;
            font-weight: bold;
            font-size: 12px;
            padding: 4px 8px;
            border-radius: 4px;
            background: alpha(#7aa2f7, 0.15);
            color: #7aa2f7;
        }
        .keybind-category {
            font-size: 11px;
            color: #bb9af7;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    def _load_bindings(self):
        """Bindings aus der Lua-Datei laden."""
        self.bindings = self.parser.parse()

        # Kategorien für Dropdown
        categories = ["Alle"] + sorted(set(b.category for b in self.bindings))
        model = Gtk.StringList.new(categories)
        self.category_dropdown.set_model(model)
        self.category_dropdown.set_selected(0)

        self._filter_bindings()
        self.status_bar.set_text(f"{len(self.bindings)} Tastenkürzel geladen")

    def _filter_bindings(self):
        """Bindings nach Suche und Kategorie filtern."""
        search_text = self.search_entry.get_text().lower()
        selected_idx = self.category_dropdown.get_selected()
        model = self.category_dropdown.get_model()
        selected_cat = model.get_string(selected_idx) if model and selected_idx < model.get_n_items() else "Alle"

        # Liste leeren
        while True:
            row = self.list_box.get_row_at_index(0)
            if row is None:
                break
            self.list_box.remove(row)

        # Gefilterte Bindings einfügen
        current_cat = ""
        count = 0

        for binding in self.bindings:
            # Kategorie-Filter
            if selected_cat != "Alle" and binding.category != selected_cat:
                continue

            # Suchfilter
            if search_text:
                if (search_text not in binding.keys.lower() and
                    search_text not in binding.description.lower() and
                    search_text not in binding.action.lower() and
                    search_text not in binding.category.lower()):
                    continue

            # Kategorie-Header
            if binding.category != current_cat and selected_cat == "Alle":
                current_cat = binding.category
                header_label = Gtk.Label(label=current_cat)
                header_label.set_halign(Gtk.Align.START)
                header_label.add_css_class("heading")
                header_label.set_margin_top(12)
                header_label.set_margin_start(8)
                self.list_box.append(header_label)

            # Binding-Zeile
            row = self._create_binding_row(binding)
            self.list_box.append(row)
            count += 1

        self.status_bar.set_text(f"{count} von {len(self.bindings)} Tastenkürzeln angezeigt")

    def _create_binding_row(self, binding: Keybinding) -> Adw.ActionRow:
        """Erstellt eine Zeile für ein Keybinding."""
        row = Adw.ActionRow(title=binding.description)
        row.set_subtitle(binding.action)

        # Tastenkombination als Badge
        keys_label = Gtk.Label(label=binding.keys)
        keys_label.add_css_class("keybind-keys")
        keys_label.set_valign(Gtk.Align.CENTER)
        row.add_suffix(keys_label)

        # Bearbeiten-Button
        edit_btn = Gtk.Button(icon_name="document-edit-symbolic", tooltip_text="Bearbeiten")
        edit_btn.set_valign(Gtk.Align.CENTER)
        edit_btn.connect("clicked", lambda _, b=binding: self._on_edit_binding(b))
        row.add_suffix(edit_btn)

        # Löschen-Button
        del_btn = Gtk.Button(icon_name="user-trash-symbolic", tooltip_text="Löschen")
        del_btn.set_valign(Gtk.Align.CENTER)
        del_btn.add_css_class("destructive-action")
        del_btn.connect("clicked", lambda _, b=binding: self._on_delete_binding(b))
        row.add_suffix(del_btn)

        return row

    def _on_search_changed(self, entry):
        """Suchfeld geändert."""
        self._filter_bindings()

    def _on_edit_binding(self, binding: Keybinding):
        """Dialog zum Bearbeiten einer Tastenbelegung."""
        dialog = Adw.AlertDialog(
            heading="Tastenkürzel bearbeiten",
            body=f"Aktuelle Belegung: {binding.keys}\nFunktion: {binding.description}",
        )

        # Eingabefeld für neue Tastenkombination
        entry = Gtk.Entry()
        entry.set_text(binding.keys)
        entry.set_margin_start(16)
        entry.set_margin_end(16)
        dialog.set_extra_child(entry)

        dialog.add_response("cancel", "Abbrechen")
        dialog.add_response("save", "Speichern")
        dialog.set_response_appearance("save", Adw.ResponseAppearance.SUGGESTED)

        dialog.connect("response", lambda d, resp, b=binding, e=entry: self._do_edit_binding(d, resp, b, e))
        dialog.present(self)

    def _do_edit_binding(self, dialog, response: str, binding: Keybinding, entry: Gtk.Entry):
        """Binding tatsächlich ändern."""
        if response != "save":
            return

        new_keys = entry.get_text().strip()
        if not new_keys:
            return

        # Validierung
        if not self._validate_keys(new_keys):
            self._show_error("Ungültige Tastenkombination", f"'{new_keys}' ist keine gültige Tastenfolge.")
            return

        # Konfliktprüfung
        conflicts = self.parser.find_conflicts(new_keys, binding.keys)
        if conflicts:
            conflict_desc = ", ".join(c.description for c in conflicts)
            self._show_error("Konflikt erkannt", f"'{new_keys}' wird bereits verwendet für: {conflict_desc}")
            return

        if self.parser.update_binding(binding.keys, new_keys):
            self._load_bindings()
            self._reload_hyprland()
            self.status_bar.set_text(f"Geändert: {binding.keys} → {new_keys}")
        else:
            self._show_error("Fehler", "Die Tastenbelegung konnte nicht geändert werden.")

    def _on_add_binding(self, button):
        """Dialog zum Hinzufügen einer neuen Tastenbelegung."""
        dialog = Adw.AlertDialog(
            heading="Neue Tastenkombination",
            body="Gib die Tastenkombination und den auszuführenden Befehl ein.",
        )

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_start(16)
        box.set_margin_end(16)

        keys_entry = Gtk.Entry()
        keys_entry.set_placeholder_text("z.B. SUPER + SHIFT + T")
        box.append(keys_entry)

        action_entry = Gtk.Entry()
        action_entry.set_placeholder_text("z.B. kitty --title htop htop")
        box.append(action_entry)

        dialog.set_extra_child(box)

        dialog.add_response("cancel", "Abbrechen")
        dialog.add_response("add", "Hinzufügen")
        dialog.set_response_appearance("add", Adw.ResponseAppearance.SUGGESTED)

        dialog.connect("response", lambda d, resp: self._do_add_binding(d, resp, keys_entry, action_entry))
        dialog.present(self)

    def _do_add_binding(self, dialog, response: str, keys_entry: Gtk.Entry, action_entry: Gtk.Entry):
        """Binding tatsächlich hinzufügen."""
        if response != "add":
            return

        keys = keys_entry.get_text().strip()
        action = action_entry.get_text().strip()

        if not keys or not action:
            self._show_error("Fehler", "Tastenkombination und Befehl müssen ausgefüllt sein.")
            return

        if not self._validate_keys(keys):
            self._show_error("Fehler", f"'{keys}' ist keine gültige Tastenfolge.")
            return

        conflicts = self.parser.find_conflicts(keys)
        if conflicts:
            self._show_error("Konflikt", f"'{keys}' wird bereits verwendet.")
            return

        if self.parser.add_binding(keys, action):
            self._load_bindings()
            self._reload_hyprland()
            self.status_bar.set_text(f"Hinzugefügt: {keys}")
        else:
            self._show_error("Fehler", "Tastenkürzel konnte nicht hinzugefügt werden.")

    def _on_delete_binding(self, binding: Keybinding):
        """Bestätigung vor dem Löschen."""
        dialog = Adw.AlertDialog(
            heading="Tastenkürzel löschen?",
            body=f"Tastenkombination: {binding.keys}\nFunktion: {binding.description}",
        )

        dialog.add_response("cancel", "Abbrechen")
        dialog.add_response("delete", "Löschen")
        dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE)

        dialog.connect("response", lambda d, resp, b=binding: self._do_delete_binding(resp, b))
        dialog.present(self)

    def _do_delete_binding(self, response: str, binding: Keybinding):
        """Binding tatsächlich löschen."""
        if response != "delete":
            return

        if self.parser.remove_binding(binding.keys):
            self._load_bindings()
            self._reload_hyprland()
            self.status_bar.set_text(f"Gelöscht: {binding.keys}")
        else:
            self._show_error("Fehler", "Tastenkürzel konnte nicht gelöscht werden.")

    def _on_restore_defaults(self, button):
        """Standard-Tastenkürzel wiederherstellen."""
        dialog = Adw.AlertDialog(
            heading="Standard wiederherstellen?",
            body="Alle Änderungen an den Tastenkürzeln werden rückgängig gemacht.\nEin Backup wird automatisch erstellt.",
        )
        dialog.add_response("cancel", "Abbrechen")
        dialog.add_response("restore", "Wiederherstellen")
        dialog.set_response_appearance("restore", Adw.ResponseAppearance.DESTRUCTIVE)

        dialog.connect("response", self._do_restore_defaults)
        dialog.present(self)

    def _do_restore_defaults(self, dialog, response: str):
        if response != "restore":
            return

        self.parser._backup()  # Sicherung vor Wiederherstellung
        if self.parser.restore_default():
            self._load_bindings()
            self._reload_hyprland()
            self.status_bar.set_text("Standard-Tastenkürzel wiederhergestellt")
        else:
            self._show_error("Fehler", "Keine ursprüngliche Sicherung gefunden.")

    def _validate_keys(self, keys: str) -> bool:
        """Prüft ob eine Tastenkombination gültig ist."""
        keys = keys.strip()
        if not keys:
            return False

        # Hyprland erlaubt Bindings ohne Modifiers mit führendem Komma, z.B. ", Print"
        if keys.startswith(","):
            keys = keys.lstrip(",").strip()
            if not keys:
                return False

        valid_modifiers = {"SUPER", "SHIFT", "CTRL", "ALT", "MOD2", "MOD3", "MOD5"}
        valid_special = {"Return", "Space", "Tab", "Escape", "BackSpace", "Delete",
                         "Home", "End", "Print", "Insert",
                         "Left", "Right", "Up", "Down",
                         "F1", "F2", "F3", "F4", "F5", "F6",
                         "F7", "F8", "F9", "F10", "F11", "F12",
                         "mouse_down", "mouse_up", "mouse:272", "mouse:273",
                         "XF86AudioRaiseVolume", "XF86AudioLowerVolume", "XF86AudioMute",
                         "XF86AudioMicMute", "XF86AudioPlay", "XF86AudioNext", "XF86AudioPrev",
                         "XF86MonBrightnessUp", "XF86MonBrightnessDown"}

        parts = [p.strip() for p in keys.split("+")]
        if not parts:
            return False

        # Der letzte Teil muss ein Key sein
        key = parts[-1]
        mods = parts[:-1]

        # Modifier prüfen
        for mod in mods:
            if mod and mod not in valid_modifiers:
                return False

        # Key prüfen (einzelner Buchstabe, Zahl, oder spezieller Key)
        if len(key) == 1:
            return True
        if key in valid_special:
            return True
        if key.startswith("XF86"):
            return True

        return False

    def _reload_hyprland(self):
        """Hyprland-Konfiguration neu laden."""
        try:
            import subprocess
            subprocess.run(["hyprctl", "reload"], capture_output=True, timeout=5)
        except (OSError, subprocess.TimeoutExpired):
            pass

    def _show_error(self, heading: str, body: str):
        """Fehlermeldung anzeigen."""
        dialog = Adw.AlertDialog(heading=heading, body=body)
        dialog.add_response("ok", "OK")
        dialog.present(self)


def main():
    app = HotkeyManagerApp()
    app.run(sys.argv)


if __name__ == "__main__":
    main()
