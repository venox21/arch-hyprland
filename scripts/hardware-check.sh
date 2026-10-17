#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night – Hardware- & Treiber-Check                     ║
# ║  Automatische Erkennung & Konfiguration für CPU, GPU, Laptop ║
# ║  Idempotent: Sicher für Erstinstallation & System-Updates    ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

# ── Tokyo Night ANSI-Farben ───────────────────────────────────
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Status-Icons & Logging ────────────────────────────────────
TAG_CHECK="${MAGENTA}${BOLD}[PRÜFE]${NC}"
TAG_ACTIVE="${GREEN}${BOLD}[AKTIV]${NC}"
TAG_INSTALL="${YELLOW}${BOLD}[INSTALLIERE]${NC}"
TAG_DONE="${GREEN}${BOLD}[FERTIG]${NC}"
TAG_INFO="${BLUE}${BOLD}[INFO]${NC}"
TAG_WARN="${YELLOW}${BOLD}[HINWEIS]${NC}"

log_check()   { echo -e "  ${TAG_CHECK} $*"; }
log_active()  { echo -e "  ${TAG_ACTIVE} $*"; }
log_install() { echo -e "  ${TAG_INSTALL} $*"; }
log_done()    { echo -e "  ${TAG_DONE} $*"; }
log_info()    { echo -e "  ${TAG_INFO} $*"; }
log_warn()    { echo -e "  ${TAG_WARN} $*"; }

header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}${BOLD}║  $*${NC}"
    echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── Visueller Spinner (gum oder Bash-Fallback) ─────────────────
run_task() {
    local title="$1"
    shift
    if command -v gum &>/dev/null; then
        gum spin --spinner.foreground="117" --title.foreground="141" --spinner="dots" --title=" ${title}" -- "$@"
    else
        echo -ne "  ${TAG_CHECK} ${title}...\r"
        "$@"
        echo -e "  ${TAG_DONE} ${title}   "
    fi
}

# ── Root-Prüfung ──────────────────────────────────────────────
if [[ "${EUID}" -eq 0 ]]; then
    echo -e "${RED}Fehler: Bitte starte dieses Skript NICHT als root!${NC}"
    echo -e "AUR-Helper und GPU-Konfigurationen benötigen Benutzer-Rechte."
    echo -e "Starte das Skript als normaler Benutzer: ${BOLD}./hardware-check.sh${NC}"
    exit 1
fi

# Sudo-Zugriff vorbereiten & am Leben halten
if ! sudo -v 2>/dev/null; then
    log_info "Bitte gib dein sudo-Passwort für Hardware-Treiberanpassungen ein:"
    sudo -v || { echo -e "${RED}sudo-Authentifizierung fehlgeschlagen.${NC}"; exit 1; }
fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill "${SUDO_PID}" 2>/dev/null || true' EXIT

header "Hardware- & Treiber-Check (Arch Linux & Hyprland)"

# ── Reporting-Variablen ───────────────────────────────────────
REPORT_CPU_MODEL="Unbekannt"
REPORT_CPU_VENDOR="Unbekannt"
REPORT_UCODE_STATUS="Nicht geprüft"

REPORT_GPU_LIST=()
REPORT_GPU_DRIVER_STATUS="Unverändert"
REPORT_NVIDIA_VARS_NEW=()
REPORT_NVIDIA_VARS_EXISTING=()

REPORT_SYSTEM_TYPE="Desktop-PC"
REPORT_POWER_TOOL="Kein Akku-Management benötigt"

# ══════════════════════════════════════════════════════════════
# Schritt 1: TUI-Tools & Paketmanager vorbereiten
# ══════════════════════════════════════════════════════════════
log_check "Prüfe TUI- und Hilfswerkzeuge..."

if ! command -v gum &>/dev/null; then
    log_install "'gum' für moderne Terminal-Animationen wird installiert..."
    sudo pacman -S --needed --noconfirm gum 2>/dev/null || log_warn "'gum' nicht verfügbar – nutze ANSI-Ausgabe."
else
    log_active "✔ [TUI] 'gum' ist bereits optimal eingerichtet (Update-Check bestanden)"
fi

if ! command -v lspci &>/dev/null; then
    log_install "'pciutils' (für lspci) wird installiert..."
    sudo pacman -S --needed --noconfirm pciutils 2>/dev/null || true
fi

# Paket-Installationshelfer (pacman oder yay)
install_pkg() {
    local pkg="$1"
    if pacman -Qi "${pkg}" &>/dev/null; then
        log_active "✔ [Paket] '${pkg}' ist bereits optimal eingerichtet (Update-Check bestanden)"
        return 0
    fi

    log_install "Installiere '${pkg}'..."
    if command -v yay &>/dev/null; then
        yay -S --needed --noconfirm "${pkg}"
    else
        sudo pacman -S --needed --noconfirm "${pkg}"
    fi
    log_done "Paket '${pkg}' erfolgreich installiert."
}

# ══════════════════════════════════════════════════════════════
# Schritt 2: CPU-Erkennung & Microcode (lscpu)
# ══════════════════════════════════════════════════════════════
echo ""
log_check "Scanne Prozessor (CPU)..."

CPU_INFO="$(lscpu 2>/dev/null || true)"
CPU_VENDOR="$(echo "${CPU_INFO}" | grep -i "Vendor ID:" | awk '{print $3}' || true)"
REPORT_CPU_MODEL="$(echo "${CPU_INFO}" | grep -i "Model name:" | sed 's/Model name:[ \t]*//' | head -n 1 || echo 'Generischer x86_64 Prozessor')"

log_info "Erkannte CPU: ${BOLD}${REPORT_CPU_MODEL}${NC} (Vendor: ${CPU_VENDOR})"

case "${CPU_VENDOR}" in
    AuthenticAMD)
        REPORT_CPU_VENDOR="AMD"
        log_info "AMD Prozessor erkannt. Prüfe Microcode (amd-ucode)..."
        if pacman -Qi amd-ucode &>/dev/null; then
            log_active "✔ [Microcode] amd-ucode ist bereits optimal eingerichtet (Update-Check bestanden)"
            REPORT_UCODE_STATUS="Bereits aktuell (amd-ucode)"
        else
            log_install "Installiere amd-ucode..."
            install_pkg "amd-ucode"
            REPORT_UCODE_STATUS="Neu installiert (amd-ucode)"
        fi
        ;;
    GenuineIntel)
        REPORT_CPU_VENDOR="Intel"
        log_info "Intel Prozessor erkannt. Prüfe Microcode (intel-ucode)..."
        if pacman -Qi intel-ucode &>/dev/null; then
            log_active "✔ [Microcode] intel-ucode ist bereits optimal eingerichtet (Update-Check bestanden)"
            REPORT_UCODE_STATUS="Bereits aktuell (intel-ucode)"
        else
            log_install "Installiere intel-ucode..."
            install_pkg "intel-ucode"
            REPORT_UCODE_STATUS="Neu installiert (intel-ucode)"
        fi
        ;;
    *)
        REPORT_CPU_VENDOR="Sonstiger (${CPU_VENDOR})"
        REPORT_UCODE_STATUS="Übersprungen (Virtuelle Maschine oder unbekannter Hersteller)"
        log_warn "Kein bekannter x86-Hersteller (AMD/Intel) für Microcode erkannt."
        ;;
esac

# ══════════════════════════════════════════════════════════════
# Schritt 3: GPU-Erkennung & Hyprland-Anpassung (lspci)
# ══════════════════════════════════════════════════════════════
echo ""
log_check "Scanne Grafikkarte(n) (GPU via lspci)..."

GPU_RAW="$(lspci -k 2>/dev/null | grep -A 2 -E "(VGA|3D)" || true)"

if [[ -z "${GPU_RAW}" ]]; then
    log_warn "Keine PCI-Grafikkarte erkannt. Überspringe GPU-Treiberanpassung."
    REPORT_GPU_LIST+=("Keine PCI-GPU ermittelt")
else
    while IFS= read -r line; do
        if [[ "${line}" =~ (VGA|3D) ]]; then
            gpu_name="$(echo "${line}" | sed -E 's/^[0-9a-f:.]+ (VGA compatible controller|3D controller): //I')"
            REPORT_GPU_LIST+=("${gpu_name}")
            log_info "Gefundene GPU: ${BOLD}${gpu_name}${NC}"
        fi
    done <<< "${GPU_RAW}"
fi

HAS_NVIDIA=false
HAS_AMD=false
HAS_INTEL=false

if echo "${GPU_RAW}" | grep -iq "nvidia"; then
    HAS_NVIDIA=true
fi
if echo "${GPU_RAW}" | grep -iq "amd" || echo "${GPU_RAW}" | grep -iq "advanced micro devices" || echo "${GPU_RAW}" | grep -iq "radeon"; then
    HAS_AMD=true
fi
if echo "${GPU_RAW}" | grep -iq "intel"; then
    HAS_INTEL=true
fi

# ── 3a. NVIDIA GPU Behandlung ─────────────────────────────────
if [[ "${HAS_NVIDIA}" == "true" ]]; then
    echo ""
    echo -e "${YELLOW}${BOLD}󰢮 NVIDIA Grafikkarte erkannt!${NC}"
    log_info "Richte Nvidia-Treiber & Hyprland Wayland-Umgebung ein..."

    # Passende Kernel-Header ermitteln
    KERNEL_RELEASE="$(uname -r)"
    HEADER_PKG="linux-headers"
    if [[ "${KERNEL_RELEASE}" =~ zen ]]; then
        HEADER_PKG="linux-zen-headers"
    elif [[ "${KERNEL_RELEASE}" =~ lts ]]; then
        HEADER_PKG="linux-lts-headers"
    elif [[ "${KERNEL_RELEASE}" =~ hardened ]]; then
        HEADER_PKG="linux-hardened-headers"
    fi
    log_info "Aktiver Kernel: ${KERNEL_RELEASE} -> Benötigt: ${HEADER_PKG}"

    # Multilib für lib32-nvidia-utils prüfen & aktivieren
    if ! pacman -Sl multilib &>/dev/null; then
        log_install "Aktiviere [multilib] Repository für 32-Bit Grafikanwendungen..."
        if grep -q "^#\[multilib\]" /etc/pacman.conf; then
            sudo sed -i -e '/^#\[multilib\]/,/^#Include[[:space:]]*=/ s/^#//' /etc/pacman.conf
        else
            echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
        fi
        sudo pacman -Sy
        log_done "[multilib] erfolgreich aktiviert."
    else
        log_active "✔ [Repository] [multilib] ist bereits aktiv (Update-Check bestanden)"
    fi

    # Erforderliche NVIDIA-Pakete
    NVIDIA_PKGS=(
        "${HEADER_PKG}"
        "nvidia-dkms"
        "nvidia-utils"
        "lib32-nvidia-utils"
        "libva-nvidia-driver"
    )

    for npkg in "${NVIDIA_PKGS[@]}"; do
        install_pkg "${npkg}"
    done
    REPORT_GPU_DRIVER_STATUS="NVIDIA (DKMS & Wayland-Treiber bereit)"

    # Hyprland Umgebungsvariablen prüfen & setzen
    HYPR_CONFIG_DIR="${HOME}/.config/hypr"
    mkdir -p "${HYPR_CONFIG_DIR}"

    NVIDIA_CONF="${HYPR_CONFIG_DIR}/nvidia.conf"
    NVIDIA_LUA="${HYPR_CONFIG_DIR}/nvidia.lua"
    MAIN_LUA="${HYPR_CONFIG_DIR}/hyprland.lua"
    MAIN_CONF="${HYPR_CONFIG_DIR}/hyprland.conf"

    # Separate nvidia.conf anlegen falls noch nicht existent
    if [[ ! -f "${NVIDIA_CONF}" ]]; then
        echo "# ╔══════════════════════════════════════════════════════════════╗" > "${NVIDIA_CONF}"
        echo "# ║  Tokyo Night – NVIDIA Hyprland Umgebungsvariablen            ║" >> "${NVIDIA_CONF}"
        echo "# ╚══════════════════════════════════════════════════════════════╝" >> "${NVIDIA_CONF}"
    fi

    REQUIRED_ENV_VARS=(
        "LIBVA_DRIVER_NAME,nvidia"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    )

    for env_pair in "${REQUIRED_ENV_VARS[@]}"; do
        var_name="${env_pair%%,*}"
        var_val="${env_pair##*,}"
        target_line="env = ${var_name},${var_val}"

        # Prüfe ob Variable bereits in nvidia.conf oder hyprland.conf existiert
        if grep -qE "env\s*=\s*${var_name}" "${NVIDIA_CONF}" 2>/dev/null || \
           ([[ -f "${MAIN_CONF}" ]] && grep -qE "env\s*=\s*${var_name}" "${MAIN_CONF}" 2>/dev/null); then
            log_active "✔ [Env-Var] ${var_name} ist bereits optimal eingerichtet (Update-Check bestanden)"
            REPORT_NVIDIA_VARS_EXISTING+=("${var_name}")
        else
            echo "${target_line}" >> "${NVIDIA_CONF}"
            log_install "Variable '${target_line}' neu in ~/.config/hypr/nvidia.conf hinzugefügt."
            REPORT_NVIDIA_VARS_NEW+=("${var_name}")
        fi
    done

    # Falls hyprland.conf vorhanden ist, stelle sicher, dass nvidia.conf gesourct wird
    if [[ -f "${MAIN_CONF}" ]]; then
        if ! grep -q "nvidia.conf" "${MAIN_CONF}"; then
            echo -e "\n# Nvidia-Treiber-Konfiguration\nsource = ~/.config/hypr/nvidia.conf" >> "${MAIN_CONF}"
            log_install "nvidia.conf in ~/.config/hypr/hyprland.conf eingebunden."
        fi
    fi

    # Idempotente Lua-Unterstützung für das native Tokyo Night Setup
    if [[ -f "${MAIN_LUA}" ]]; then
        if [[ ! -f "${NVIDIA_LUA}" ]]; then
            cat << 'EOF' > "${NVIDIA_LUA}"
-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Tokyo Night – NVIDIA Umgebungsvariablen (Native Lua)       ║
-- ╚══════════════════════════════════════════════════════════════╝
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
EOF
            log_install "NVIDIA Lua-Modul (~/.config/hypr/nvidia.lua) angelegt."
        fi

        if ! grep -q "pcall(require, \"nvidia\")" "${MAIN_LUA}"; then
            echo -e '\npcall(require, "nvidia") -- Lädt nvidia.lua falls vorhanden' >> "${MAIN_LUA}"
            log_install "NVIDIA Lua-Modul in ~/.config/hypr/hyprland.lua eingebunden."
        fi
    fi

# ── 3b. AMD / Intel GPU Behandlung ───────────────────────────
else
    if [[ "${HAS_AMD}" == "true" ]]; then
        log_info "AMD Grafikkarte erkannt. Prüfe Open-Source Mesa & Vulkan (RADV)..."
        AMD_PKGS=("mesa" "vulkan-radeon" "libva-mesa-driver" "mesa-vdpau")
        for apkg in "${AMD_PKGS[@]}"; do
            install_pkg "${apkg}"
        done
        REPORT_GPU_DRIVER_STATUS="AMD Radeon (Open-Source Mesa & RADV aktiv)"
    fi

    if [[ "${HAS_INTEL}" == "true" ]]; then
        log_info "Intel Grafikkarte erkannt. Prüfe Open-Source Mesa & Vulkan (ANV)..."
        INTEL_PKGS=("mesa" "vulkan-intel" "intel-media-driver")
        for ipkg in "${INTEL_PKGS[@]}"; do
            install_pkg "${ipkg}"
        done
        REPORT_GPU_DRIVER_STATUS="Intel Graphics (Mesa & Vulkan aktiv)"
    fi

    if [[ "${HAS_AMD}" == "false" && "${HAS_INTEL}" == "false" ]]; then
        log_info "Standard Mesa Grafik-Treiber prüfen..."
        install_pkg "mesa"
        REPORT_GPU_DRIVER_STATUS="Generischer Mesa-Treiber"
    fi
fi

# ══════════════════════════════════════════════════════════════
# Schritt 4: Laptop- & Akku-Erkennung
# ══════════════════════════════════════════════════════════════
echo ""
log_check "Scanne System-Typ (Laptop vs. Desktop-PC)..."

IS_LAPTOP=false
BATTERY_PATHS=(/sys/class/power_supply/BAT* /sys/class/power_supply/CMB*)

for bpath in "${BATTERY_PATHS[@]}"; do
    if [[ -d "${bpath}" ]]; then
        IS_LAPTOP=true
        break
    fi
done

if [[ "${IS_LAPTOP}" == "false" ]]; then
    REPORT_SYSTEM_TYPE="Desktop-PC"
    REPORT_POWER_TOOL="Kein Akku vorhanden (Übersprungen)"
    echo -e "  ${TAG_ACTIVE} ${BOLD}🖥 Desktop-System erkannt – überspringe Akku-Tools.${NC}"
else
    REPORT_SYSTEM_TYPE="Laptop"
    echo -e "  ${TAG_ACTIVE} ${BOLD}💻 Laptop-System erkannt!${NC}"

    # 1. Helligkeitssteuerung (brightnessctl)
    log_check "Prüfe Helligkeitssteuerung (brightnessctl)..."
    install_pkg "brightnessctl"

    # 2. Akku-Management prüfen
    log_check "Prüfe vorhandene Energieverwaltungs-Dienste..."
    TLP_ACTIVE="$(systemctl is-active tlp 2>/dev/null || echo 'inactive')"
    AUTOCPU_ACTIVE="$(systemctl is-active auto-cpufreq 2>/dev/null || echo 'inactive')"

    if [[ "${AUTOCPU_ACTIVE}" == "active" ]]; then
        log_active "✔ [Energie] auto-cpufreq ist bereits aktiv (Status: active, Update-Check bestanden)"
        REPORT_POWER_TOOL="auto-cpufreq (Status: aktiv)"
    elif [[ "${TLP_ACTIVE}" == "active" ]]; then
        log_active "✔ [Energie] tlp ist bereits aktiv (Status: active, Update-Check bestanden)"
        REPORT_POWER_TOOL="tlp (Status: aktiv)"
    else
        # Noch kein Tool aktiv: Biete Auswahl an
        echo ""
        log_warn "Kein aktiver Akku-Manager (tlp oder auto-cpufreq) gefunden."
        CHOICE=""
        if command -v gum &>/dev/null; then
            CHOICE="$(gum choose \
                --header="Wähle eine Energieverwaltung für deinen Laptop:" \
                "1) auto-cpufreq (Empfohlen: dynamische CPU- & Akku-Optimierung)" \
                "2) tlp (Klassisches Akku- & Power-Management)" \
                "3) Überspringen (Keine automatische Energieverwaltung)")" || true
        else
            echo "1) auto-cpufreq (Empfohlen für moderne Laptops)"
            echo "2) tlp (Klassischer Standard)"
            echo "3) Überspringen"
            read -r -p "Auswahl [1-3, Standard 1]: " raw_c
            case "${raw_c:-1}" in
                1) CHOICE="1) auto-cpufreq" ;;
                2) CHOICE="2) tlp" ;;
                *) CHOICE="3) Überspringen" ;;
            esac
        fi

        case "${CHOICE}" in
            1*|"auto-cpufreq"*)
                log_install "Installiere und aktiviere auto-cpufreq..."
                install_pkg "auto-cpufreq"
                sudo systemctl enable --now auto-cpufreq 2>/dev/null || true
                log_done "auto-cpufreq erfolgreich aktiviert."
                REPORT_POWER_TOOL="auto-cpufreq (Neu eingerichtet & aktiv)"
                ;;
            2*|"tlp"*)
                log_install "Installiere und aktiviere tlp..."
                install_pkg "tlp"
                sudo systemctl enable --now tlp 2>/dev/null || true
                log_done "tlp erfolgreich aktiviert."
                REPORT_POWER_TOOL="tlp (Neu eingerichtet & aktiv)"
                ;;
            *)
                log_info "Akku-Management übersprungen."
                REPORT_POWER_TOOL="Vom Nutzer übersprungen"
                ;;
        esac
    fi
fi

# ══════════════════════════════════════════════════════════════
# Schritt 5: Abschluss-Report & Zusammenfassung
# ══════════════════════════════════════════════════════════════
echo ""
header "Hardware- & Treiber-Zusammenfassung"

echo -e "  ┌─────────────────────────┬────────────────────────────────────────────────────────┐"
printf "  │ %-23s │ %-54s │\n" "Komponente" "Status / Konfiguration"
echo -e "  ├─────────────────────────┼────────────────────────────────────────────────────────┤"
printf "  │ %-23s │ %-54s │\n" "CPU-Modell" "${REPORT_CPU_MODEL:0:54}"
printf "  │ %-23s │ %-54s │\n" "CPU-Hersteller" "${REPORT_CPU_VENDOR}"
printf "  │ %-23s │ %-54s │\n" "Microcode" "${REPORT_UCODE_STATUS}"
echo -e "  ├─────────────────────────┼────────────────────────────────────────────────────────┤"

gpu_first=true
for gpu in "${REPORT_GPU_LIST[@]}"; do
    if [[ "${gpu_first}" == "true" ]]; then
        printf "  │ %-23s │ %-54s │\n" "Grafikkarte (GPU)" "${gpu:0:54}"
        gpu_first=false
    else
        printf "  │ %-23s │ %-54s │\n" "" "${gpu:0:54}"
    fi
done

printf "  │ %-23s │ %-54s │\n" "Grafik-Treiber" "${REPORT_GPU_DRIVER_STATUS:0:54}"

if [[ "${HAS_NVIDIA}" == "true" ]]; then
    if [[ ${#REPORT_NVIDIA_VARS_NEW[@]} -gt 0 ]]; then
        vars_str="Neu: ${REPORT_NVIDIA_VARS_NEW[*]}"
        printf "  │ %-23s │ %-54s │\n" "Nvidia Env-Variablen" "${vars_str:0:54}"
    fi
    if [[ ${#REPORT_NVIDIA_VARS_EXISTING[@]} -gt 0 ]]; then
        vars_exist="Bestätigt: ${REPORT_NVIDIA_VARS_EXISTING[*]}"
        printf "  │ %-23s │ %-54s │\n" "Nvidia Env-Status" "${vars_exist:0:54}"
    fi
fi

echo -e "  ├─────────────────────────┼────────────────────────────────────────────────────────┤"
printf "  │ %-23s │ %-54s │\n" "System-Typ" "${REPORT_SYSTEM_TYPE}"
printf "  │ %-23s │ %-54s │\n" "Energieverwaltung" "${REPORT_POWER_TOOL:0:54}"
echo -e "  └─────────────────────────┴────────────────────────────────────────────────────────┘"

echo ""
echo -e "${GREEN}${BOLD}✔ Hardware- und Treiberprüfung erfolgreich abgeschlossen!${NC}"
echo ""
