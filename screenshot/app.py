#!/usr/bin/env python3
# pyrefly: ignore-all-errors
"""
╔══════════════════════════════════════════════════════════════╗
║  Tokyo Shot – Moderner Hyprland Screenshot-Manager & Editor   ║
║  GTK4 + libadwaita mit Tokyo Night Ästhetik                  ║
╚══════════════════════════════════════════════════════════════╝
"""

import sys
import os
import math
import shutil
import subprocess
import argparse

# Pfad zur Kernlogik
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, CURRENT_DIR)

import shot_core

# GTK4 / libadwaita sicher importieren (mit Fallback für Headless/Tests)
HAS_GTK = False
try:
    import gi
    gi.require_version("Gtk", "4.0")
    gi.require_version("Adw", "1")
    from gi.repository import Gtk, Adw, Gio, GLib, Gdk, GdkPixbuf
    HAS_GTK = True
except (ImportError, ValueError):
    HAS_GTK = False

# Cairo importieren
HAS_CAIRO = False
try:
    import cairo
    HAS_CAIRO = True
except ImportError:
    HAS_CAIRO = False


# ── Tokyo Night Farbpalette ──────────────────────────────────
TOKYO_COLORS = {
    "bg_dark":  "#1a1b26",
    "bg":       "#24283b",
    "bg_light": "#292e42",
    "fg":       "#c0caf5",
    "fg_muted": "#7982a9",
    "blue":     "#7aa2f7",
    "red":      "#f7768e",
    "green":    "#9ece6a",
    "yellow":   "#e0af68",
    "magenta":  "#bb9af7",
    "teal":     "#73daca",
    "white":    "#ffffff",
}

ANNOTATION_PALETTE = [
    ("#f7768e", "Rot"),
    ("#7aa2f7", "Blau"),
    ("#9ece6a", "Grün"),
    ("#e0af68", "Gelb"),
    ("#bb9af7", "Lila"),
    ("#73daca", "Türkis"),
    ("#ffffff", "Weiß"),
    ("#1a1b26", "Dunkel"),
]

APP_CSS = """
/* Tokyo Shot Theme */
window.tokyo-shot {
    background-color: #1a1b26;
    color: #c0caf5;
}

.shot-card {
    background-color: rgba(36, 40, 59, 0.7);
    border-radius: 12px;
    border: 1px solid rgba(122, 162, 247, 0.2);
    padding: 12px;
}

.mode-btn {
    border-radius: 10px;
    padding: 14px 18px;
    font-weight: bold;
    font-size: 14px;
    transition: all 180ms ease;
}

.mode-btn:hover {
    background-color: rgba(122, 162, 247, 0.15);
}

.color-dot {
    border-radius: 9999px;
    min-width: 24px;
    min-height: 24px;
    border: 2px solid rgba(255, 255, 255, 0.2);
}

.color-dot.active {
    border-color: #ffffff;
    box-shadow: 0 0 6px rgba(122, 162, 247, 0.8);
}
"""


def hex_to_rgba(hex_code, alpha=1.0):
    hex_code = hex_code.lstrip("#")
    if len(hex_code) == 6:
        r = int(hex_code[0:2], 16) / 255.0
        g = int(hex_code[2:4], 16) / 255.0
        b = int(hex_code[4:6], 16) / 255.0
        return (r, g, b, alpha)
    return (1.0, 1.0, 1.0, alpha)


if HAS_GTK:
    class AnnotationEditor(Adw.Window):
        """Voller Bild-Editor für Screenshots mit Zeichen-, Pfeil- und Zensurfunktionen."""

        def __init__(self, file_path, on_closed_cb=None):
            super().__init__()
            self.set_title("Tokyo Shot – Editor")
            self.set_default_size(1024, 680)
            self.add_css_class("tokyo-shot")

            self.file_path = file_path
            self.on_closed_cb = on_closed_cb
            self.original_pixbuf = None
            self.current_surface = None

            # Zeichen-Status
            self.tool = "brush"  # brush, arrow, rect, blur, text
            self.current_color = "#f7768e"
            self.line_width = 4
            self.history = []
            self.redo_stack = []

            # Maus-Interaktion
            self.start_point = None
            self.current_point = None
            self.current_stroke = []

            self._load_image()
            self._setup_ui()
            self._setup_shortcuts()

        def _load_image(self):
            try:
                self.original_pixbuf = GdkPixbuf.Pixbuf.new_from_file(self.file_path)
                w = self.original_pixbuf.get_width()
                h = self.original_pixbuf.get_height()
                
                # Cairo Image Surface erzeugen
                self.img_surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
                cr = cairo.Context(self.img_surface)
                Gdk.cairo_set_source_pixbuf(cr, self.original_pixbuf, 0, 0)
                cr.paint()

                # History mit Ausgangszustand initialisieren
                self._push_history()
            except Exception as e:
                shot_core.notify(f"Fehler beim Laden: {e}", title="Tokyo Shot", critical=True)

        def _push_history(self):
            w = self.img_surface.get_width()
            h = self.img_surface.get_height()
            copy_surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
            cr = cairo.Context(copy_surf)
            cr.set_source_surface(self.img_surface, 0, 0)
            cr.paint()
            self.history.append(copy_surf)
            # Begrenze History auf 25 Schritte
            if len(self.history) > 25:
                self.history.pop(0)
            self.redo_stack.clear()
            self._update_undo_buttons()

        def _setup_ui(self):
            main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
            self.set_content(main_box)

            # ── Headerbar ────────────────────────────────────
            header = Adw.HeaderBar()
            main_box.append(header)

            # Werkzeugleiste links
            tool_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
            tool_box.set_margin_start(6)

            tools = [
                ("brush",  "✏", "Freihand-Stift"),
                ("arrow",  "➔", "Pfeil zeichnen"),
                ("rect",   "▭", "Rechteck-Rahmen"),
                ("blur",   "⬛", "Zensieren / Unkenntlich machen"),
            ]

            self.tool_buttons = {}
            for t_id, icon, tip in tools:
                btn = Gtk.ToggleButton(label=icon)
                btn.set_tooltip_text(tip)
                btn.connect("toggled", self._on_tool_toggled, t_id)
                tool_box.append(btn)
                self.tool_buttons[t_id] = btn

            self.tool_buttons["brush"].set_active(True)
            header.pack_start(tool_box)

            # Farbpalette
            color_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
            color_box.set_margin_start(12)
            self.color_buttons = []
            for hex_val, tip in ANNOTATION_PALETTE:
                c_btn = Gtk.Button()
                c_btn.set_tooltip_text(tip)
                c_btn.add_css_class("color-dot")
                
                # Punkt mit Farbe füllen
                provider = Gtk.CssProvider()
                css = f"button {{ background-color: {hex_val}; border-radius: 9999px; min-width: 20px; min-height: 20px; }}"
                provider.load_from_data(css.encode())
                c_btn.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
                
                c_btn.connect("clicked", self._on_color_selected, hex_val)
                color_box.append(c_btn)
                self.color_buttons.append((c_btn, hex_val))

            header.pack_start(color_box)

            # Aktionen rechts im Header
            act_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            act_box.set_margin_end(6)

            # Undo / Redo
            self.undo_btn = Gtk.Button(label="↩")
            self.undo_btn.set_tooltip_text("Rückgängig (Strg+Z)")
            self.undo_btn.connect("clicked", lambda b: self.undo())
            act_box.append(self.undo_btn)

            self.redo_btn = Gtk.Button(label="↪")
            self.redo_btn.set_tooltip_text("Wiederholen (Strg+Y)")
            self.redo_btn.connect("clicked", lambda b: self.redo())
            act_box.append(self.redo_btn)

            # Kopieren
            copy_btn = Gtk.Button(label="📋 Kopieren")
            copy_btn.add_css_class("suggested-action")
            copy_btn.set_tooltip_text("In Zwischenablage kopieren")
            copy_btn.connect("clicked", self._on_copy_clicked)
            act_box.append(copy_btn)

            # Speichern unter
            save_btn = Gtk.Button(label="💾 Speichern")
            save_btn.set_tooltip_text("Änderungen speichern")
            save_btn.connect("clicked", self._on_save_clicked)
            act_box.append(save_btn)

            # Pin / Bild-im-Bild
            pin_btn = Gtk.Button(label="📌")
            pin_btn.set_tooltip_text("Als schwebendes Bild-im-Bild anheften")
            pin_btn.connect("clicked", self._on_pin_clicked)
            act_box.append(pin_btn)

            header.pack_end(act_box)

            # ── Zeichenbereich (Scrollbar & Canvas) ────────────
            self.scroller = Gtk.ScrolledWindow()
            self.scroller.set_hexpand(True)
            self.scroller.set_vexpand(True)
            main_box.append(self.scroller)

            self.drawing_area = Gtk.DrawingArea()
            w = self.img_surface.get_width() if self.img_surface else 400
            h = self.img_surface.get_height() if self.img_surface else 300
            self.drawing_area.set_content_width(w)
            self.drawing_area.set_content_height(h)
            self.drawing_area.set_draw_func(self._draw_func)

            # Gesten für Mausklicks und Ziehen
            drag = Gtk.GestureDrag()
            drag.connect("drag-begin", self._on_drag_begin)
            drag.connect("drag-update", self._on_drag_update)
            drag.connect("drag-end", self._on_drag_end)
            self.drawing_area.add_controller(drag)

            self.scroller.set_child(self.drawing_area)

        def _setup_shortcuts(self):
            key_ctrl = Gtk.EventControllerKey()
            key_ctrl.connect("key-pressed", self._on_key_pressed)
            self.add_controller(key_ctrl)

        def _on_key_pressed(self, controller, keyval, keycode, state):
            is_ctrl = bool(state & Gdk.ModifierType.CONTROL_MASK)
            # Strg+Z -> Undo
            if is_ctrl and keyval in (Gdk.KEY_z, Gdk.KEY_Z):
                if state & Gdk.ModifierType.SHIFT_MASK:
                    self.redo()
                else:
                    self.undo()
                return True
            # Strg+Y -> Redo
            if is_ctrl and keyval in (Gdk.KEY_y, Gdk.KEY_Y):
                self.redo()
                return True
            # Strg+C -> Kopieren
            if is_ctrl and keyval in (Gdk.KEY_c, Gdk.KEY_C):
                self._on_copy_clicked(None)
                return True
            # Strg+S -> Speichern
            if is_ctrl and keyval in (Gdk.KEY_s, Gdk.KEY_S):
                self._on_save_clicked(None)
                return True
            # Escape -> Schließen
            if keyval == Gdk.KEY_Escape:
                self.close()
                return True
            return False

        def _on_tool_toggled(self, button, tool_id):
            if button.get_active():
                self.tool = tool_id
                for tid, btn in self.tool_buttons.items():
                    if tid != tool_id:
                        btn.set_active(False)

        def _on_color_selected(self, button, hex_val):
            self.current_color = hex_val

        def _update_undo_buttons(self):
            self.undo_btn.set_sensitive(len(self.history) > 1)
            self.redo_btn.set_sensitive(len(self.redo_stack) > 0)

        def undo(self):
            if len(self.history) > 1:
                last = self.history.pop()
                self.redo_stack.append(last)
                target = self.history[-1]
                
                # Auf Surface übertragen
                cr = cairo.Context(self.img_surface)
                cr.set_operator(cairo.OPERATOR_SOURCE)
                cr.set_source_surface(target, 0, 0)
                cr.paint()
                
                self.drawing_area.queue_draw()
                self._update_undo_buttons()

        def redo(self):
            if self.redo_stack:
                target = self.redo_stack.pop()
                self.history.append(target)
                
                cr = cairo.Context(self.img_surface)
                cr.set_operator(cairo.OPERATOR_SOURCE)
                cr.set_source_surface(target, 0, 0)
                cr.paint()
                
                self.drawing_area.queue_draw()
                self._update_undo_buttons()

        # ── Zeichen-Gesten ───────────────────────────────────
        def _on_drag_begin(self, gesture, start_x, start_y):
            self.start_point = (start_x, start_y)
            self.current_point = (start_x, start_y)
            self.current_stroke = [(start_x, start_y)]
            self.drawing_area.queue_draw()

        def _on_drag_update(self, gesture, offset_x, offset_y):
            if not self.start_point:
                return
            curr_x = self.start_point[0] + offset_x
            curr_y = self.start_point[1] + offset_y
            self.current_point = (curr_x, curr_y)
            if self.tool == "brush":
                self.current_stroke.append((curr_x, curr_y))
            self.drawing_area.queue_draw()

        def _on_drag_end(self, gesture, offset_x, offset_y):
            if not self.start_point or not self.img_surface:
                return
            end_x = self.start_point[0] + offset_x
            end_y = self.start_point[1] + offset_y
            
            # Dauerhaft in img_surface rendern
            cr = cairo.Context(self.img_surface)
            self._render_shape(cr, self.start_point, (end_x, end_y), self.current_stroke, is_permanent=True)
            
            self._push_history()
            self.start_point = None
            self.current_point = None
            self.current_stroke = []
            self.drawing_area.queue_draw()

        def _render_shape(self, cr, p1, p2, stroke, is_permanent=False):
            rgba = hex_to_rgba(self.current_color)

            if self.tool == "brush":
                if len(stroke) < 2:
                    return
                cr.set_source_rgba(*rgba)
                cr.set_line_width(self.line_width)
                cr.set_line_cap(cairo.LINE_CAP_ROUND)
                cr.set_line_join(cairo.LINE_JOIN_ROUND)
                cr.move_to(stroke[0][0], stroke[0][1])
                for pt in stroke[1:]:
                    cr.line_to(pt[0], pt[1])
                cr.stroke()

            elif self.tool == "rect":
                x = min(p1[0], p2[0])
                y = min(p1[1], p2[1])
                w = abs(p2[0] - p1[0])
                h = abs(p2[1] - p1[1])
                cr.set_source_rgba(*rgba)
                cr.set_line_width(self.line_width)
                cr.rectangle(x, y, w, h)
                cr.stroke()

            elif self.tool == "arrow":
                cr.set_source_rgba(*rgba)
                cr.set_line_width(self.line_width)
                cr.set_line_cap(cairo.LINE_CAP_ROUND)
                # Linie
                cr.move_to(p1[0], p1[1])
                cr.line_to(p2[0], p2[1])
                cr.stroke()
                
                # Pfeilspitze
                angle = math.atan2(p2[1] - p1[1], p2[0] - p1[0])
                arrow_len = 16
                arrow_angle = math.pi / 6
                
                x1 = p2[0] - arrow_len * math.cos(angle - arrow_angle)
                y1 = p2[1] - arrow_len * math.sin(angle - arrow_angle)
                x2 = p2[0] - arrow_len * math.cos(angle + arrow_angle)
                y2 = p2[1] - arrow_len * math.sin(angle + arrow_angle)
                
                cr.move_to(p2[0], p2[1])
                cr.line_to(x1, y1)
                cr.line_to(x2, y2)
                cr.close_path()
                cr.fill()

            elif self.tool == "blur":
                # Zensur-Balken / Zensur-Rechteck
                x = min(p1[0], p2[0])
                y = min(p1[1], p2[1])
                w = abs(p2[0] - p1[0])
                h = abs(p2[1] - p1[1])
                
                # Schwarzer/Dunkler Tokyo Night Balken mit leichtem Rand
                cr.set_source_rgba(0.1, 0.11, 0.15, 0.98)
                cr.rectangle(x, y, w, h)
                cr.fill()
                cr.set_source_rgba(0.48, 0.64, 0.97, 0.6)
                cr.set_line_width(1.5)
                cr.rectangle(x, y, w, h)
                cr.stroke()

        def _draw_func(self, area, cr, width, height):
            if not self.img_surface:
                return

            # Hauptbild rendern
            cr.set_source_surface(self.img_surface, 0, 0)
            cr.paint()

            # Live-Vorschau der aktuellen Geste
            if self.start_point and self.current_point:
                self._render_shape(cr, self.start_point, self.current_point, self.current_stroke, is_permanent=False)

        def _save_surface(self, target_path):
            if not self.img_surface:
                return False
            try:
                self.img_surface.write_to_png(target_path)
                return True
            except Exception as e:
                shot_core.notify(f"Speichern fehlgeschlagen: {e}", critical=True)
                return False

        def _on_save_clicked(self, button):
            if self._save_surface(self.file_path):
                shot_core.notify(f"Gespeichert:\n{self.file_path}", title="Tokyo Shot")

        def _on_copy_clicked(self, button):
            # Speichere aktuellen Stand und kopiere in Zwischenablage
            if self._save_surface(self.file_path):
                shot_core.copy_file_to_clipboard(self.file_path)
                shot_core.notify("Screenshot in die Zwischenablage kopiert!", title="Tokyo Shot")

        def _on_pin_clicked(self, button):
            """Screenshot als kleines, schwebendes Bild-im-Bild Fenster anheften."""
            self._save_surface(self.file_path)
            pin_win = PinWindow(self.file_path)
            pin_win.present()


    class PinWindow(Gtk.Window):
        """Schwebendes Always-on-Top Fenster für Referenzbilder."""

        def __init__(self, file_path):
            super().__init__()
            self.set_title("Tokyo Shot – Pin")
            self.add_css_class("tokyo-shot-pin")
            self.set_default_size(360, 240)

            pic = Gtk.Picture.new_for_filename(file_path)
            pic.set_can_shrink(True)
            self.set_child(pic)


    class TokyoShotApp(Adw.Application):
        """Haupt-Applikation: Bietet Aufnahmemodi, Verzögerung, Einstellungen & Schnellgalerie."""

        def __init__(self, start_mode=None, target_file=None):
            super().__init__(application_id="org.tokyo.shot", flags=Gio.ApplicationFlags.FLAGS_NONE)
            self.start_mode = start_mode
            self.target_file = target_file
            self.cfg = shot_core.load_config()

        def do_startup(self):
            Adw.Application.do_startup(self)
            # Custom CSS laden
            provider = Gtk.CssProvider()
            provider.load_from_data(APP_CSS.encode())
            Gtk.StyleProvider.add_provider_for_display(
                Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

        def do_activate(self):
            # Falls direkt eine Datei editiert werden soll
            if self.target_file and os.path.exists(self.target_file):
                editor = AnnotationEditor(self.target_file)
                self.add_window(editor)
                editor.present()
                return

            # Falls ein Aufnahmemodus direkt per CLI angefordert wurde
            if self.start_mode:
                self._execute_capture(self.start_mode)
                return

            # Hauptfenster (Interactive Screenshot Hub)
            win = self.props.active_window
            if not win:
                win = MainWindow(self)
                self.add_window(win)
            win.present()

        def _execute_capture(self, mode, delay=0):
            try:
                # Fenster minimieren/verstecken vor Aufnahme, damit es nicht im Bild ist
                for w in self.get_windows():
                    w.set_visible(False)
                GLib.timeout_add(150, lambda: self._do_capture_delayed(mode, delay))
            except Exception as e:
                shot_core.notify(f"Fehler: {e}", critical=True)

        def _do_capture_delayed(self, mode, delay):
            try:
                saved_path = shot_core.capture(mode, self.cfg, delay=delay)
                if saved_path:
                    shot_core.notify_saved(saved_path)
                    if self.cfg.get("edit_after_capture", True) and HAS_CAIRO:
                        editor = AnnotationEditor(saved_path)
                        self.add_window(editor)
                        editor.present()
                    else:
                        self.quit()
                else:
                    # Abbruch
                    self.quit()
            except Exception as e:
                shot_core.notify(f"Aufnahme fehlgeschlagen: {e}", critical=True)
                self.quit()
            return False


    class MainWindow(Adw.ApplicationWindow):
        """Kompaktes, modernes Aufnahme-Dashboard mit Kacheln und Galerie."""

        def __init__(self, app):
            super().__init__(application=app)
            self.app = app
            self.set_title("Tokyo Shot")
            self.set_default_size(540, 520)
            self.add_css_class("tokyo-shot")

            main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
            main_box.set_margin_top(16)
            main_box.set_margin_bottom(16)
            main_box.set_margin_start(20)
            main_box.set_margin_end(20)
            self.set_content(main_box)

            # Headerbar
            header = Adw.HeaderBar()
            main_box.append(header)

            # Titel & Beschreibung
            title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            title_lbl = Gtk.Label(label="Tokyo Shot")
            title_lbl.add_css_class("title-1")
            sub_lbl = Gtk.Label(label="Wähle einen Aufnahmemodus")
            sub_lbl.add_css_class("dim-label")
            title_box.append(title_lbl)
            title_box.append(sub_lbl)
            main_box.append(title_box)

            # ── 4 Große Aufnahmekacheln ──────────────────────────
            grid = Gtk.Grid()
            grid.set_column_spacing(12)
            grid.set_row_spacing(12)
            grid.set_hexpand(True)
            grid.set_halign(Gtk.Align.CENTER)

            modes = [
                ("area",    "⛶ Bereich",      "Auswahl mit der Maus aufziehen", 0, 0),
                ("window",  "🗔 Fenster",      "Aktives oder gewähltes Fenster",  1, 0),
                ("monitor", "🖥 Monitor",      "Aktuellen Bildschirm aufnehmen", 0, 1),
                ("full",    "🖼 Vollbild",     "Gesamte Anzeigefläche",          1, 1),
            ]

            for m_id, label, tip, col, row in modes:
                card = Gtk.Button()
                card.add_css_class("mode-btn")
                card.add_css_class("shot-card")
                card.set_tooltip_text(tip)
                
                box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
                box.set_margin_top(8)
                box.set_margin_bottom(8)
                box.set_margin_start(16)
                box.set_margin_end(16)

                lbl_main = Gtk.Label(label=label)
                lbl_main.add_css_class("heading")
                lbl_sub = Gtk.Label(label=tip)
                lbl_sub.add_css_class("caption")
                lbl_sub.add_css_class("dim-label")

                box.append(lbl_main)
                box.append(lbl_sub)
                card.set_child(box)

                card.connect("clicked", self._on_mode_clicked, m_id)
                grid.attach(card, col, row, 1, 1)

            main_box.append(grid)

            # ── Einstellungen & Optionen ─────────────────────────
            opt_group = Adw.PreferencesGroup(title="Aufnahmeoptionen")
            
            # Timer / Verzögerung
            delay_row = Adw.ActionRow(title="Verzögerungstimer")
            self.delay_combo = Gtk.DropDown.new_from_strings(["Sofort (0s)", "3 Sekunden", "5 Sekunden", "10 Sekunden"])
            delay_row.add_suffix(self.delay_combo)
            opt_group.add(delay_row)

            # Schalter: Nach Aufnahme editieren
            self.edit_switch = Adw.SwitchRow(title="Im Editor öffnen")
            self.edit_switch.set_subtitle("Screenshot direkt nach Aufnahme beschriften oder zuschneiden")
            self.edit_switch.set_active(self.app.cfg.get("edit_after_capture", True))
            self.edit_switch.connect("notify::active", self._on_opt_changed, "edit_after_capture")
            opt_group.add(self.edit_switch)

            # Schalter: In Zwischenablage kopieren
            self.clip_switch = Adw.SwitchRow(title="Automatisch in Zwischenablage")
            self.clip_switch.set_subtitle("Bild nach der Aufnahme sofort kopieren")
            self.clip_switch.set_active(self.app.cfg.get("copy_to_clipboard", True))
            self.clip_switch.connect("notify::active", self._on_opt_changed, "copy_to_clipboard")
            opt_group.add(self.clip_switch)

            # Schalter: Mauszeiger
            self.pointer_switch = Adw.SwitchRow(title="Mauszeiger aufnehmen")
            self.pointer_switch.set_active(self.app.cfg.get("pointer", False))
            self.pointer_switch.connect("notify::active", self._on_opt_changed, "pointer")
            opt_group.add(self.pointer_switch)

            main_box.append(opt_group)

            # ── Galerie der letzten Screenshots ──────────────────
            recent = shot_core.list_screenshots(self.app.cfg)
            if recent:
                recent_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
                recent_lbl = Gtk.Label(label=f"📁 {len(recent)} Screenshots in {shot_core.screenshot_dir(self.app.cfg)}")
                recent_lbl.add_css_class("dim-label")
                recent_box.append(recent_lbl)

                open_dir_btn = Gtk.Button(label="Ordner öffnen")
                open_dir_btn.connect("clicked", lambda b: subprocess.Popen(["thunar", shot_core.screenshot_dir(self.app.cfg)]))
                recent_box.append(open_dir_btn)

                # Letzten Screenshot editieren
                latest_edit_btn = Gtk.Button(label="Letzten bearbeiten")
                latest_edit_btn.connect("clicked", lambda b: self._open_in_editor(recent[0]))
                recent_box.append(latest_edit_btn)

                main_box.append(recent_box)

        def _on_opt_changed(self, switch, gparam, key):
            self.app.cfg[key] = switch.get_active()
            shot_core.save_config(self.app.cfg)

        def _get_selected_delay(self):
            idx = self.delay_combo.get_selected()
            return [0, 3, 5, 10][idx] if idx < 4 else 0

        def _on_mode_clicked(self, button, mode):
            delay = self._get_selected_delay()
            self.app._execute_capture(mode, delay=delay)

        def _open_in_editor(self, path):
            if HAS_CAIRO:
                editor = AnnotationEditor(path)
                self.app.add_window(editor)
                editor.present()


# ── CLI & Einstiegspunkt ─────────────────────────────────────

def main():
    shot_core.ensure_wayland_env()

    parser = argparse.ArgumentParser(description="Tokyo Shot – Moderner Hyprland Screenshot-Manager")
    parser.add_argument("mode", nargs="?", choices=["area", "window", "monitor", "full", "gui"], help="Aufnahmemodus")
    parser.add_argument("--area", action="store_true", help="Bereich aufnehmen")
    parser.add_argument("--window", action="store_true", help="Fenster aufnehmen")
    parser.add_argument("--monitor", action="store_true", help="Monitor aufnehmen")
    parser.add_argument("--full", action="store_true", help="Vollbild aufnehmen")
    parser.add_argument("--gui", action="store_true", help="Grafische Oberfläche / Hub öffnen")
    parser.add_argument("--edit", type=str, metavar="FILE", help="Bild im Editor öffnen")
    parser.add_argument("--delay", type=int, default=0, help="Verzögerung in Sekunden")
    parser.add_argument("--no-edit", action="store_true", help="Editor nach Aufnahme überspringen")
    parser.add_argument("--copy", action="store_true", help="Immer in Zwischenablage kopieren")

    args = parser.parse_args()

    # Modus ermitteln
    mode = None
    if args.area or args.mode == "area":
        mode = "area"
    elif args.window or args.mode == "window":
        mode = "window"
    elif args.monitor or args.mode == "monitor":
        mode = "monitor"
    elif args.full or args.mode == "full":
        mode = "full"
    elif args.gui or args.mode == "gui":
        mode = "gui"

    cfg = shot_core.load_config()
    if args.no_edit:
        cfg["edit_after_capture"] = False
    if args.copy:
        cfg["copy_to_clipboard"] = True

    # Fall 1: Datei direkt im Editor öffnen
    if args.edit:
        if not HAS_GTK:
            print("Fehler: GTK4 / libadwaita nicht verfügbar.", file=sys.stderr)
            sys.exit(1)
        app = TokyoShotApp(target_file=os.path.abspath(args.edit))
        app.run(sys.argv[:1])
        return

    # Fall 2: Kein GUI-Aufruf und kein Editor gewünscht -> Blitzschneller Headless-Modus
    if mode and mode != "gui" and not cfg.get("edit_after_capture"):
        try:
            saved = shot_core.capture(mode, cfg, delay=args.delay)
            if saved:
                shot_core.notify_saved(saved)
                print(saved)
            sys.exit(0)
        except Exception as e:
            shot_core.notify(str(e), critical=True)
            print(f"Fehler: {e}", file=sys.stderr)
            sys.exit(1)

    # Fall 3: GUI starten (Hub oder Aufnahme mit anschließendem Editor)
    if HAS_GTK:
        app_mode = mode if mode != "gui" else None
        app = TokyoShotApp(start_mode=app_mode)
        app.run(sys.argv[:1])
    else:
        # Fallback wenn kein GTK installiert ist
        if mode and mode != "gui":
            saved = shot_core.capture(mode, cfg, delay=args.delay)
            if saved:
                shot_core.notify_saved(saved)
                print(saved)
        else:
            print("Tokyo Shot: GTK4 nicht gefunden. Starte im CLI-Modus. Verwende --area, --window oder --full.")


if __name__ == "__main__":
    main()
