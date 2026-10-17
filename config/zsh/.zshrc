# ╔══════════════════════════════════════════════════════════════╗
# ║  Zsh – Shell-Konfiguration (Tokyo Night)                     ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Verlauf ───────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt hist_reduce_blanks

# ── Grundeinstellungen ────────────────────────────────────────
setopt autocd
setopt interactive_comments
setopt correct
setopt no_beep

# ── Vervollständigung ────────────────────────────────────────
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true

# ── Schlüsselbelegung ────────────────────────────────────────
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ── Aliase ────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'

# Paketmanager
alias pacs='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacu='sudo pacman -Syu'
alias pacq='pacman -Qs'
alias pacf='pacman -Ss'

# Systemd
alias sc='sudo systemctl'
alias scu='systemctl --user'
alias jctl='journalctl -p 3 -xb'

# Hyprland-spezifisch
alias hypr-reload='hyprctl reload'
alias hypr-monitors='hyprctl monitors'
alias hypr-clients='hyprctl clients'
alias hypr-version='hyprctl version'
alias hypr-logs='cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -1)/hyprland.log | tail -50'

# Sicherheit
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# ── Umgebungsvariablen ────────────────────────────────────────
export EDITOR="nano"
export VISUAL="nano"
export TERMINAL="kitty"
export BROWSER="firefox"
export PAGER="less"

# XDG-Verzeichnisse
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Pfad erweitern
export PATH="$HOME/.local/bin:$PATH"

# Sprache & Lokalisierung (automatisch synchronisiert mit Tokyo Settings)
if [[ -f "$HOME/.config/locale.conf" ]]; then
    source "$HOME/.config/locale.conf"
fi

# ── Starship Prompt ──────────────────────────────────────────
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# ── Fastfetch (optional) ─────────────────────────────────────
# Nur in interaktiven Terminals, nicht in Sub-Shells
if [[ -o interactive ]] && command -v fastfetch &>/dev/null; then
    # Nur anzeigen wenn kein Parent-Prozess ein Terminal ist
    if [[ -z "$TMUX" ]] && [[ -z "$INSIDE_EMACS" ]]; then
        fastfetch --logo small
    fi
fi
