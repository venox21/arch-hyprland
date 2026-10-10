#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Wallpaper-Manager für Hyprland (Tokyo Night)                ║
# ║  Visuelle Auswahl, JaKooLit Wallpaper-Bank Sync & Zufall     ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

WALLPAPER_DIR="${HOME}/.config/hypr/wallpapers"
PICTURES_DIR="${HOME}/Pictures/wallpapers"
CURRENT_LINK="${WALLPAPER_DIR}/current.jpg"
THUMB_DIR="${HOME}/.cache/wallpaper-thumbs"
ROFI_THEME="${HOME}/.config/rofi/wallpaper.rasi"
REPO_URL="https://github.com/JaKooLit/Wallpaper-Bank.git"
BANK_DIR="${WALLPAPER_DIR}/Wallpaper-Bank"

mkdir -p "${WALLPAPER_DIR}" "${THUMB_DIR}"

# ── Benachrichtigungs-Helfer ──────────────────────────────────
notify() {
    local title="$1"
    local body="$2"
    local icon="${3:-preferences-desktop-wallpaper}"
    notify-send -a "Wallpaper" "${title}" "${body}" -i "${icon}" -t 3500 2>/dev/null || true
}

# ── Thumbnail generieren ──────────────────────────────────────
get_thumbnail() {
    local img="$1"
    local hash
    hash="$(printf '%s' "${img}" | md5sum | cut -d' ' -f1)"
    local thumb="${THUMB_DIR}/${hash}.png"

    if [[ ! -f "${thumb}" || "${img}" -nt "${thumb}" ]]; then
        if command -v magick &>/dev/null; then
            magick "${img}" -thumbnail 240x135^ -gravity center -extent 240x135 "${thumb}" 2>/dev/null || cp -f "${img}" "${thumb}" 2>/dev/null || true
        elif command -v convert &>/dev/null; then
            convert "${img}" -thumbnail 240x135^ -gravity center -extent 240x135 "${thumb}" 2>/dev/null || cp -f "${img}" "${thumb}" 2>/dev/null || true
        elif command -v ffmpeg &>/dev/null; then
            ffmpeg -y -i "${img}" -vf "scale=240:135:force_original_aspect_ratio=increase,crop=240:135" "${thumb}" -v quiet 2>/dev/null || cp -f "${img}" "${thumb}" 2>/dev/null || true
        else
            thumb="${img}"
        fi
    fi
    printf '%s' "${thumb}"
}

# ── Wallpaper anwenden ────────────────────────────────────────
apply_wallpaper() {
    local target="$1"

    if [[ ! -f "${target}" ]]; then
        notify "Fehler" "Datei nicht gefunden: ${target}" "dialog-error"
        exit 1
    fi

    # Aktuelles Bild kopieren (hyprpaper benötigt echte Datei)
    cp -f "${target}" "${CURRENT_LINK}"

    # Hyprpaper aktualisieren
    if pgrep -x hyprpaper &>/dev/null; then
        hyprctl hyprpaper unload all 2>/dev/null || true
        hyprctl hyprpaper preload "${CURRENT_LINK}" 2>/dev/null || true
        hyprctl hyprpaper wallpaper ", ${CURRENT_LINK}" 2>/dev/null || true
    fi

    # SWWW aktualisieren (falls im Einsatz)
    if pgrep -x swww-daemon &>/dev/null; then
        swww img "${CURRENT_LINK}" --transition-type wipe --transition-angle 30 --transition-duration 1 2>/dev/null || true
    fi

    local name
    name="$(basename "${target}")"
    local thumb
    thumb="$(get_thumbnail "${target}")"
    notify "Hintergrundbild gewechselt" "${name}" "${thumb}"
}

# ── JaKooLit Wallpaper-Bank synchronisieren ───────────────────
sync_wallpaper_bank() {
    notify "Wallpaper-Bank" "Synchronisierung gestartet (JaKooLit)..." "emblem-downloads"

    if [[ ! -d "${BANK_DIR}/.git" ]]; then
        if git clone --depth 1 "${REPO_URL}" "${BANK_DIR}" 2>/dev/null; then
            notify "Wallpaper-Bank" "Erfolgreich heruntergeladen!" "emblem-default"
        else
            notify "Fehler" "Konnte JaKooLit Wallpaper-Bank nicht klonen." "dialog-error"
            return 1
        fi
    else
        if git -C "${BANK_DIR}" pull --ff-only 2>/dev/null; then
            notify "Wallpaper-Bank" "Erfolgreich aktualisiert!" "emblem-default"
        else
            notify "Hinweis" "Keine Updates oder Git-Fehler beim Aktualisieren." "dialog-warning"
        fi
    fi
}

# ── Alle Wallpaper-Dateien sammeln ───────────────────────────
collect_wallpapers() {
    local dirs=("${WALLPAPER_DIR}")
    [[ -d "${PICTURES_DIR}" ]] && dirs+=("${PICTURES_DIR}")

    find -L "${dirs[@]}" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        ! -name 'current.jpg' \
        2>/dev/null | sort -u
}

# ── Zufälliges Wallpaper auswählen ───────────────────────────
random_wallpaper() {
    mapfile -t ALL_WP < <(collect_wallpapers)
    if [[ ${#ALL_WP[@]} -eq 0 ]]; then
        notify "Wallpaper" "Keine Bilder gefunden. Lade die Wallpaper-Bank herunter." "dialog-warning"
        exit 0
    fi
    local rand_idx=$(( RANDOM % ${#ALL_WP[@]} ))
    apply_wallpaper "${ALL_WP[${rand_idx}]}"
}

# ── CLI Argumente behandeln ───────────────────────────────────
case "${1:-}" in
    --random|-r)
        random_wallpaper
        exit 0
        ;;
    --sync|-s|--download|-d)
        sync_wallpaper_bank
        exit 0
        ;;
    --set)
        if [[ -n "${2:-}" ]]; then
            apply_wallpaper "$2"
            exit 0
        fi
        ;;
    --help|-h)
        echo "Nutzung: $0 [OPTION]"
        echo "Optionen:"
        echo "  (keine)       Öffnet die visuelle Rofi-Kachelauswahl"
        echo "  -r, --random  Wählt ein zufälliges Hintergrundbild aus"
        echo "  -s, --sync    Lädt/synchronisiert die JaKooLit Wallpaper-Bank"
        echo "  --set DATEI   Aktiviert das angegebene Hintergrundbild"
        exit 0
        ;;
esac

# ── Interaktive Rofi-Auswahl mit Kacheln ───────────────────────
mapfile -t FILES < <(collect_wallpapers)

# Falls keine Wallpaper vorhanden sind: Sofort Download anbieten
if [[ ${#FILES[@]} -eq 0 ]]; then
    CHOICE="$(printf "📥 JaKooLit Wallpaper-Bank jetzt herunterladen\nAbbrechen" | rofi -dmenu -i -p "  Wallpaper" -theme "${ROFI_THEME}" 2>/dev/null || true)"
    if [[ "${CHOICE}" =~ "herunterladen" ]]; then
        sync_wallpaper_bank
        mapfile -t FILES < <(collect_wallpapers)
    else
        exit 0
    fi
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
    notify "Wallpaper" "Keine Bilder in ${WALLPAPER_DIR} vorhanden." "dialog-warning"
    exit 0
fi

# Auswahl-Liste mit Bild-Icons aufbauen
ENTRY_LIST=""
# Sonderaktionen an den Anfang
ENTRY_LIST+="🎲 Zufälliges Wallpaper\0icon\x1fpreferences-desktop-wallpaper\n"
ENTRY_LIST+="📥 Wallpaper-Bank synchronisieren\0icon\x1fsystem-software-update\n"

for f in "${FILES[@]}"; do
    filename="$(basename "${f}")"
    # Kürzel oder Kategorie bei Wallpaper-Bank
    display_name="${filename%.*}"
    thumb="$(get_thumbnail "${f}")"
    ENTRY_LIST+="${display_name}\0icon\x1f${thumb}\n"
done

# Rofi starten
CHOSEN="$(printf '%b' "${ENTRY_LIST}" | rofi -dmenu \
    -i \
    -p "  Wallpaper" \
    -theme "${ROFI_THEME}" \
    -show-icons \
    2>/dev/null || true)"

[[ -z "${CHOSEN}" ]] && exit 0

case "${CHOSEN}" in
    "🎲 Zufälliges Wallpaper")
        random_wallpaper
        ;;
    "📥 Wallpaper-Bank synchronisieren")
        sync_wallpaper_bank
        ;;
    *)
        # Ausgewählte Datei finden
        for f in "${FILES[@]}"; do
            filename="$(basename "${f}")"
            display_name="${filename%.*}"
            if [[ "${CHOSEN}" == "${display_name}" || "${CHOSEN}" == "${filename}" ]]; then
                apply_wallpaper "${f}"
                exit 0
            fi
        done
        # Fallback falls exakter Pfad übergeben
        if [[ -f "${CHOSEN}" ]]; then
            apply_wallpaper "${CHOSEN}"
        fi
        ;;
esac
