#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Tokyo Night – Cyber-Security & Pentesting Schnellmenü       ║
# ║  Startet Security-Tools via Rofi (GUI & CLI in Kitty)        ║
# ╚══════════════════════════════════════════════════════════════╝
set -Eeuo pipefail

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# Wayland Umgebung sicherstellen
if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    wp_sock="$(find "${XDG_RUNTIME_DIR}" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' 2>/dev/null | head -n 1 || true)"
    [[ -n "${wp_sock}" ]] && export WAYLAND_DISPLAY="$(basename "${wp_sock}")"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROFI_THEME="${HOME}/.config/rofi/config.rasi"

# Terminal-Ermittlung (Kitty bevorzugt)
TERM_CMD="kitty"
if ! command -v kitty &>/dev/null; then
    for t in alacritty foot wezterm xterm; do
        if command -v "${t}" &>/dev/null; then
            TERM_CMD="${t}"
            break
        fi
    done
fi

notify() {
    local title="$1"
    local msg="$2"
    local icon="${3:-security-high}"
    if command -v notify-send &>/dev/null; then
        notify-send -a "Cyber-Security" -i "${icon}" "${title}" "${msg}" 2>/dev/null || true
    fi
}

run_cli_tool() {
    local title="$1"
    local cmd="$2"
    if [[ "${TERM_CMD}" == "kitty" ]]; then
        kitty --title "CyberSec: ${title}" -e bash -c "${cmd}; exec bash" &
    else
        "${TERM_CMD}" -e bash -c "${cmd}; exec bash" &
    fi
}

install_missing() {
    local pkg="$1"
    local name="$2"
    notify "Installation erforderlich" "${name} ist nicht installiert. Öffne Terminal..." "dialog-warning"
    if command -v yay &>/dev/null; then
        run_cli_tool "Installer: ${name}" "yay -S --needed ${pkg}"
    else
        run_cli_tool "Installer: ${name}" "sudo pacman -S --needed ${pkg}"
    fi
}

# ── Tool-Liste ────────────────────────────────────────────────
# Format: Display-Name
OPT_WIRESHARK="🦈 Wireshark             Packet Analyzer & Network Traffic (GUI)"
OPT_BURP="🌐 Burp Suite            Web Pentesting & Security Scanner (GUI)"
OPT_NMAP="🔍 Nmap                  Network Port & Vulnerability Scanner (CLI)"
OPT_MSF="💥 Metasploit            Exploitation Framework (msfconsole) (CLI)"
OPT_GOBUSTER="📁 Gobuster              Directory & Subdomain Brute-Forcer (CLI)"
OPT_FFUF="⚡ FFUF                  Fast Web Fuzzer & Path Enumeration (CLI)"
OPT_SQLMAP="💉 SQLmap                Automatisches SQL-Injection Tool (CLI)"
OPT_AIRCRACK="📡 Aircrack-ng           WLAN Security Audit & Handshake Tool (CLI)"
OPT_HASHCAT="🔑 Hashcat               Advanced GPU Password & Hash Cracker (CLI)"
OPT_JOHN="🔓 John the Ripper       Passwort-Sicherheits-Audit & Cracker (CLI)"
OPT_GHIDRA="🔬 Ghidra                NSA Software Reverse-Engineering (GUI)"
OPT_NIKTO="🎯 Nikto                 Web Server Vulnerability Scanner (CLI)"
OPT_TCPDUMP="🛰️ Tcpdump               Netzwerk-Sniffer & Live-Paketaufzeichnung (CLI)"
OPT_NETCAT="🔌 Netcat (nc)           TCP/UDP Port Listener & Schweizer Taschenmesser"
OPT_INSTALLER="📦 Security-Installer    Weitere Hacking-Tools & BlackArch installieren"

MENU_ITEMS="${OPT_WIRESHARK}\n${OPT_BURP}\n${OPT_NMAP}\n${OPT_MSF}\n${OPT_GOBUSTER}\n${OPT_FFUF}\n${OPT_SQLMAP}\n${OPT_AIRCRACK}\n${OPT_HASHCAT}\n${OPT_JOHN}\n${OPT_GHIDRA}\n${OPT_NIKTO}\n${OPT_TCPDUMP}\n${OPT_NETCAT}\n${OPT_INSTALLER}"

CHOSEN="$(echo -e "${MENU_ITEMS}" | rofi -dmenu \
    -i \
    -p "🛡️ Cyber-Tools" \
    -theme-str 'window { width: 680px; }' \
    -theme-str 'listview { lines: 12; }' \
    ${ROFI_THEME:+-theme "${ROFI_THEME}"} \
    2>/dev/null)" || exit 0

case "${CHOSEN}" in
    "${OPT_WIRESHARK}")
        if command -v wireshark &>/dev/null; then
            wireshark &>/dev/null &
        else
            install_missing "wireshark-qt" "Wireshark"
        fi
        ;;
    "${OPT_BURP}")
        if command -v burpsuite &>/dev/null; then
            burpsuite &>/dev/null &
        elif [[ -f "/usr/bin/burpsuite" ]]; then
            /usr/bin/burpsuite &>/dev/null &
        else
            install_missing "burpsuite" "Burp Suite"
        fi
        ;;
    "${OPT_NMAP}")
        if command -v nmap &>/dev/null; then
            run_cli_tool "Nmap Scanner" "echo -e '\033[1;36m=== Nmap Network Exploration & Security Audit ===\033[0m\n'; nmap --help | head -n 28; echo -e '\n\033[1;32mBeispiel: nmap -sC -sV -p- <target-ip>\033[0m\n'"
        else
            install_missing "nmap" "Nmap"
        fi
        ;;
    "${OPT_MSF}")
        if command -v msfconsole &>/dev/null; then
            run_cli_tool "Metasploit Console" "msfconsole"
        else
            install_missing "metasploit" "Metasploit Framework"
        fi
        ;;
    "${OPT_GOBUSTER}")
        if command -v gobuster &>/dev/null; then
            run_cli_tool "Gobuster" "echo -e '\033[1;36m=== Gobuster Directory & DNS Buster ===\033[0m\n'; gobuster --help; echo -e '\n\033[1;32mBeispiel: gobuster dir -u http://target.local -w /usr/share/wordlists/dirb/common.txt\033[0m\n'"
        else
            install_missing "gobuster" "Gobuster"
        fi
        ;;
    "${OPT_FFUF}")
        if command -v ffuf &>/dev/null; then
            run_cli_tool "FFUF Web Fuzzer" "echo -e '\033[1;36m=== FFUF Fast Web Fuzzer ===\033[0m\n'; ffuf -h | head -n 35; echo -e '\n\033[1;32mBeispiel: ffuf -u http://target.local/FUZZ -w /usr/share/seclists/Discovery/Web-Content/common.txt\033[0m\n'"
        else
            install_missing "ffuf" "FFUF"
        fi
        ;;
    "${OPT_SQLMAP}")
        if command -v sqlmap &>/dev/null; then
            run_cli_tool "SQLmap" "echo -e '\033[1;36m=== SQLmap Injection Tool ===\033[0m\n'; sqlmap -h | head -n 35; echo -e '\n\033[1;32mBeispiel: sqlmap -u \"http://target.local/item.php?id=1\" --dbs\033[0m\n'"
        else
            install_missing "sqlmap" "SQLmap"
        fi
        ;;
    "${OPT_AIRCRACK}")
        if command -v aircrack-ng &>/dev/null; then
            run_cli_tool "Aircrack-ng Suite" "echo -e '\033[1;36m=== Aircrack-ng Wireless Security ===\033[0m\n'; aircrack-ng --help | head -n 30; echo -e '\n\033[1;32mTools verfügbar: airmon-ng, airodump-ng, aireplay-ng, aircrack-ng\033[0m\n'"
        else
            install_missing "aircrack-ng" "Aircrack-ng"
        fi
        ;;
    "${OPT_HASHCAT}")
        if command -v hashcat &>/dev/null; then
            run_cli_tool "Hashcat GPU Cracker" "echo -e '\033[1;36m=== Hashcat Advanced Password Recovery ===\033[0m\n'; hashcat --help | head -n 30; echo -e '\n\033[1;32mBeispiel: hashcat -m 0 hashes.txt wordlist.txt\033[0m\n'"
        else
            install_missing "hashcat" "Hashcat"
        fi
        ;;
    "${OPT_JOHN}")
        if command -v john &>/dev/null; then
            run_cli_tool "John the Ripper" "echo -e '\033[1;36m=== John the Ripper Password Audit ===\033[0m\n'; john --help | head -n 30; echo -e '\n\033[1;32mBeispiel: john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt\033[0m\n'"
        else
            install_missing "john" "John the Ripper"
        fi
        ;;
    "${OPT_GHIDRA}")
        if command -v ghidra &>/dev/null; then
            ghidra &>/dev/null &
        else
            install_missing "ghidra" "Ghidra"
        fi
        ;;
    "${OPT_NIKTO}")
        if command -v nikto &>/dev/null; then
            run_cli_tool "Nikto Web Scanner" "echo -e '\033[1;36m=== Nikto Web Server Scanner ===\033[0m\n'; nikto -Help | head -n 25; echo -e '\n\033[1;32mBeispiel: nikto -h http://target.local\033[0m\n'"
        else
            install_missing "nikto" "Nikto"
        fi
        ;;
    "${OPT_TCPDUMP}")
        if command -v tcpdump &>/dev/null; then
            run_cli_tool "Tcpdump" "echo -e '\033[1;36m=== Tcpdump Packet Capture ===\033[0m\n'; echo 'Starte mit Root-Rechten für Schnittstelle: sudo tcpdump -i any -n'; sudo tcpdump -h 2>&1 | head -n 20"
        else
            install_missing "tcpdump" "Tcpdump"
        fi
        ;;
    "${OPT_NETCAT}")
        if command -v nc &>/dev/null || command -v netcat &>/dev/null; then
            local nc_bin="$(command -v nc || command -v netcat)"
            run_cli_tool "Netcat" "echo -e '\033[1;36m=== Netcat (${nc_bin}) ===\033[0m\n'; ${nc_bin} -h 2>&1 | head -n 25; echo -e '\n\033[1;32mBeispiel Listener: nc -lvnp 4444\033[0m\n'"
        else
            install_missing "gnu-netcat" "Netcat"
        fi
        ;;
    "${OPT_INSTALLER}")
        if [[ -f "${SCRIPT_DIR}/app-installer.sh" ]]; then
            run_cli_tool "Tokyo App- & Security-Installer" "bash '${SCRIPT_DIR}/app-installer.sh'"
        elif [[ -f "${HOME}/.config/hypr/scripts/app-installer.sh" ]]; then
            run_cli_tool "Tokyo App- & Security-Installer" "bash '${HOME}/.config/hypr/scripts/app-installer.sh'"
        else
            notify "Installer" "app-installer.sh nicht gefunden" "dialog-error"
        fi
        ;;
    *)
        exit 0
        ;;
esac
