#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║  Tokyo Shot – Kernlogik                                      ║
║  Aufnahme (grim + slurp), Konfiguration, Zwischenablage      ║
║  Benötigt nur die Python-Standardbibliothek                  ║
╚══════════════════════════════════════════════════════════════╝
"""

import datetime
import glob
import json
import os
import shutil
import subprocess
import time

APP_NAME = "Tokyo Shot"

CONFIG_DIR = os.path.join(
    os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "tokyo-shot"
)
CONFIG_PATH = os.path.join(CONFIG_DIR, "config.json")

DEFAULTS = {
    "directory": "",              # leer = <Bilder>/Screenshots
    "edit_after_capture": True,   # Editor nach der Aufnahme öffnen
    "copy_to_clipboard": True,    # Aufnahme automatisch kopieren
    "pointer": False,             # Mauszeiger mit aufnehmen
    "freeze": True,               # Bildschirm einfrieren (nur mit wayfreeze)
    "delay": 0,                   # Verzögerung in Sekunden
}

CAPTURE_MODES = ("area", "window", "monitor", "full")

# Tokyo-Night-Optik für die slurp-Auswahl
SLURP_STYLE = [
    "-d",
    "-b", "#1a1b2666",
    "-c", "#7aa2f7ff",
    "-s", "#7aa2f722",
    "-B", "#7aa2f744",
    "-w", "2",
]


# ── Umgebung ─────────────────────────────────────────────────

def ensure_wayland_env():
    """Wayland-/Hyprland-Umgebung ermitteln (SSH / TTY / Starter ohne Session)."""
    uid = os.getuid() if hasattr(os, "getuid") else 1000
    runtime_dir = os.environ.setdefault("XDG_RUNTIME_DIR", f"/run/user/{uid}")

    if "WAYLAND_DISPLAY" not in os.environ:
        sockets = [
            s for s in glob.glob(os.path.join(runtime_dir, "wayland-*"))
            if not s.endswith(".lock")
        ]
        if sockets:
            os.environ["WAYLAND_DISPLAY"] = os.path.basename(sorted(sockets)[0])

    if "HYPRLAND_INSTANCE_SIGNATURE" not in os.environ:
        hypr_dir = os.path.join(runtime_dir, "hypr")
        if os.path.isdir(hypr_dir):
            sigs = [f for f in os.listdir(hypr_dir) if not f.endswith(".lock")]
            if sigs:
                os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = sorted(sigs)[0]


# ── Konfiguration ────────────────────────────────────────────

def load_config():
    cfg = dict(DEFAULTS)
    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        if isinstance(data, dict):
            cfg.update({k: v for k, v in data.items() if k in DEFAULTS})
    except (OSError, ValueError):
        pass
    return cfg


def save_config(cfg):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        tmp = CONFIG_PATH + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump({k: cfg.get(k, v) for k, v in DEFAULTS.items()}, fh, indent=2)
            fh.write("\n")
        os.replace(tmp, CONFIG_PATH)
    except OSError:
        pass


def screenshot_dir(cfg):
    """Zielordner: konfigurierter Pfad, sonst <Bilder>/Screenshots."""
    custom = (cfg.get("directory") or "").strip()
    if custom:
        return os.path.expanduser(custom)

    home = os.path.expanduser("~")
    pictures = ""
    if shutil.which("xdg-user-dir"):
        try:
            out = subprocess.run(
                ["xdg-user-dir", "PICTURES"], capture_output=True, text=True, timeout=3
            ).stdout.strip()
            if out and os.path.abspath(out) != os.path.abspath(home):
                pictures = out
        except (OSError, subprocess.TimeoutExpired):
            pass

    if not pictures:
        german = os.path.join(home, "Bilder")
        english = os.path.join(home, "Pictures")
        pictures = english if os.path.isdir(english) and not os.path.isdir(german) else german

    return os.path.join(pictures, "Screenshots")


def list_screenshots(cfg):
    """Alle Screenshots, neueste zuerst."""
    files = glob.glob(os.path.join(screenshot_dir(cfg), "*.png"))
    return sorted(files, key=os.path.getmtime, reverse=True)


# ── Benachrichtigungen & Zwischenablage ──────────────────────

def notify(message, title="Screenshot", icon="camera-photo", critical=False):
    if not shutil.which("notify-send"):
        return
    cmd = ["notify-send", "-a", APP_NAME, "-i", icon, "-t", "4500"]
    if critical:
        cmd += ["-u", "critical"]
    cmd += [title, message]
    try:
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def copy_file_to_clipboard(path):
    """PNG-Datei als Bild in die Zwischenablage legen."""
    if not shutil.which("wl-copy"):
        return False
    try:
        with open(path, "rb") as fh:
            # wl-copy forkt in den Hintergrund – Ausgabe daher nicht abgreifen
            subprocess.run(
                ["wl-copy", "--type", "image/png"],
                stdin=fh,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
        return True
    except OSError:
        return False


def notify_saved(path):
    notify(f"Gespeichert:\n{path}", icon=path if os.path.exists(path) else "camera-photo")


# ── Hyprland-Helfer ──────────────────────────────────────────

def hypr_json(*args):
    if not shutil.which("hyprctl"):
        return None
    try:
        res = subprocess.run(
            ["hyprctl", *args, "-j"], capture_output=True, text=True, timeout=3
        )
        if res.returncode == 0 and res.stdout.strip():
            return json.loads(res.stdout)
    except (OSError, ValueError, subprocess.TimeoutExpired):
        pass
    return None


def visible_window_boxes():
    """Geometrien aller sichtbaren Fenster im slurp-Format 'x,y WxH'."""
    clients = hypr_json("clients") or []
    monitors = hypr_json("monitors") or []

    active = set()
    for mon in monitors:
        ws = (mon.get("activeWorkspace") or {}).get("id")
        if ws is not None:
            active.add(ws)
        special = (mon.get("specialWorkspace") or {}).get("id")
        if special:
            active.add(special)

    # Reihenfolge: gekachelt zuerst, schwebend zuletzt;
    # innerhalb davon das zuletzt fokussierte Fenster ganz zum Schluss
    ordered = sorted(
        clients,
        key=lambda c: (bool(c.get("floating")), -int(c.get("focusHistoryID", 0))),
    )

    boxes = []
    for client in ordered:
        if not client.get("mapped", True) or client.get("hidden"):
            continue
        if (client.get("workspace") or {}).get("id") not in active:
            continue
        try:
            x, y = client["at"]
            w, h = client["size"]
        except (KeyError, ValueError, TypeError):
            continue
        if w > 0 and h > 0:
            boxes.append(f"{x},{y} {w}x{h}")
    return boxes


# ── Auswahl (slurp) ──────────────────────────────────────────

def run_slurp(extra_args, stdin_text=None, cfg=None):
    """slurp ausführen. Gibt die Geometrie zurück oder None bei Abbruch."""
    if not shutil.which("slurp"):
        raise RuntimeError("slurp ist nicht installiert (sudo pacman -S slurp)")

    freezer = None
    if cfg and cfg.get("freeze") and shutil.which("wayfreeze"):
        try:
            freezer = subprocess.Popen(
                ["wayfreeze"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            time.sleep(0.2)
        except OSError:
            freezer = None

    try:
        res = subprocess.run(
            ["slurp", *SLURP_STYLE, *extra_args],
            input=stdin_text,
            capture_output=True,
            text=True,
        )
    finally:
        if freezer is not None:
            freezer.terminate()
            try:
                freezer.wait(timeout=1)
            except subprocess.TimeoutExpired:
                freezer.kill()

    if res.returncode != 0:
        return None
    geometry = res.stdout.strip()
    return geometry or None


# ── Aufnahme ─────────────────────────────────────────────────

def new_filename(cfg):
    out_dir = screenshot_dir(cfg)
    os.makedirs(out_dir, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    path = os.path.join(out_dir, f"screenshot_{stamp}.png")
    counter = 1
    while os.path.exists(path):
        path = os.path.join(out_dir, f"screenshot_{stamp}_{counter}.png")
        counter += 1
    return path


def capture(mode, cfg, delay=0):
    """
    Screenshot aufnehmen.

    mode:  area | window | monitor | full
    Gibt den Dateipfad zurück oder None, wenn die Auswahl abgebrochen wurde.
    Wirft RuntimeError bei fehlenden Werkzeugen oder Aufnahmefehlern.
    """
    if mode not in CAPTURE_MODES:
        raise RuntimeError(f"Unbekannter Modus: {mode}")
    if not shutil.which("grim"):
        raise RuntimeError("grim ist nicht installiert (sudo pacman -S grim)")

    geometry = None
    if mode == "area":
        geometry = run_slurp([], cfg=cfg)
    elif mode == "window":
        boxes = visible_window_boxes()
        if boxes:
            geometry = run_slurp(["-r"], "\n".join(boxes) + "\n", cfg=cfg)
        else:
            geometry = run_slurp([], cfg=cfg)
    elif mode == "monitor":
        geometry = run_slurp(["-o"], cfg=cfg)

    if mode != "full" and geometry is None:
        return None  # Auswahl abgebrochen

    if delay and delay > 0:
        notify(f"Aufnahme in {delay} s …", icon="appointment-soon")
        time.sleep(delay)

    path = new_filename(cfg)
    cmd = ["grim"]
    if cfg.get("pointer"):
        cmd.append("-c")
    if geometry:
        cmd += ["-g", geometry]
    cmd.append(path)

    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0 or not os.path.exists(path):
        detail = (res.stderr or "").strip() or "unbekannter Fehler"
        raise RuntimeError(f"Aufnahme fehlgeschlagen: {detail}")

    if cfg.get("copy_to_clipboard", True):
        copy_file_to_clipboard(path)
    return path
