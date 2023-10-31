#!/usr/bin/env bash

# Edit/reload bash configs
alias aliases='$EDITOR $DOTFILES/config/bash/aliases.sh'
alias functions='$EDITOR $DOTFILES/config/bash/functions.sh'
alias reload_aliases='source $DOTFILES/config/bash/aliases.sh'
alias reload_functions='source $DOTFILES/config/bash/functions.sh'

# Basic aliases
alias cl='clear'
alias x='exit'

# Filesystem aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ls='ls --color'
alias lsl='ls -l --group-directories-first'
alias lss='ls --sort=extension --group-directories-first'

# Helpers
alias grep='grep --color=auto'

# Make disk free always human-readable
if command -v 'df' &>/dev/null; then
    alias df='df -h'
fi

# Sorted, human-readable disk usage by depth
if command -v 'du' &>/dev/null; then
    alias du1='du -hd1 2>/dev/null | sort -hr'
    alias du2='du -hd2 2>/dev/null | sort -hr'
    alias du3='du -hd3 2>/dev/null | sort -hr'
    alias du4='du -hd4 2>/dev/null | sort -hr'
    alias du5='du -hd5 2>/dev/null | sort -hr'
fi

# Ranger aliases
if command -v 'ranger' &>/dev/null; then
    alias r='ranger'
    alias notes='ranger ~/notebook'
fi

# Locate aliases
if command -v 'locate' &>/dev/null; then
    alias lv='locate --regex'
    alias lV='locate'
fi

# Neovim aliases
if command -v 'nvim' &>/dev/null; then
    alias nvimf='nvim $(fzf)'
    alias nvimd='nvim $DOTFILES'
    alias nvimt='nvim $(mktemp)'
    alias nvimdiff='nvim -d'
fi

# Apt aliases
if command -v 'apt' &>/dev/null; then
    alias apti='sudo apt install -y'
    alias apts='sudo apt search'
fi

# Pacman aliases
if command -v 'pacman' &>/dev/null; then
    alias pinstall='sudo pacman -Syu --noconfirm'
    alias psearch='sudo pacman -Ss'
    alias premove='sudo pacman -R --noconfirm'
    alias pupdate='sudo pacman -Syyu --noconfirm'
fi

# Wi-Fi aliases
if command -v 'nmcli' &>/dev/null; then
    alias wifisearch='nmcli device wifi list'
    alias wificonnect='nmcli device wifi connect --ask'
fi

# Git aliases
if command -v 'git' &>/dev/null; then
    alias gs='git status --short'
    alias gc='git commit'
    alias gco='git checkout'
    alias gcob='git checkout -b'
    alias gb='git branch'
    alias gbc='git branch --show-current'
    alias gac='git add --all && git commit'
    alias gd='git diff'
    alias gdt='git difftool --dir-diff --no-symlinks'
    alias gdm='git difftool -t "meld" -d'
    alias gaa='git add --all'
    alias gaad='git add --all --dry-run'
fi

# Tmux aliases
if command -v 'tmux' &>/dev/null; then
    alias tm='tmux'
    alias tms="tmux new-session -s \"\$(basename \"\$(pwd)\")\""
    alias tma='tmux attach'
fi

# HashiCorp Tools
command -v 'terraform' &>/dev/null && alias tf='terraform'
command -v 'consul' &>/dev/null && alias csl='consul'

# Restart mpd
if command -v 'mpd' &>/dev/null; then
    alias mpd_restart='mpd --kill; mpd'
fi

# Restart wpr
if command -v 'wpr' &>/dev/null; then
    alias wpr_restart='killall wpr &>/dev/null; wpr &>/dev/null &'
fi

# Other
command -v 'startx' &>/dev/null && \
    alias sx='startx'
command -v 'xrdb' &>/dev/null && \
    alias reload_xresources='xrdb -merge ~/.Xresources'
command -v 'xclip' &>/dev/null && \
    alias clip='xclip -i -selection clipboard'
command -v 'gnome-control-center' &>/dev/null && \
    alias gnome-settings='env XDG_CURRENT_DESKTOP=GNOME gnome-control-center'


if command -v 'docker' &>/dev/null; then
    alias dps='docker_pss'

    # Stop all docker containers
    # shellcheck disable=SC2142
    alias docker_stop="docker ps | tail -n +2 | awk '{print \$1}' | xargs docker stop"
    # Remove all docker containers
    alias docker_rma="docker ps --all | tail -n +2 | sed -e 's/ .*//g' | xargs docker rm"
    # Remove all docker images
    # shellcheck disable=SC2142
    alias docker_rmi="docker images --all | tail -n +2 | awk '{ print \$3 }' | xargs docker rmi -f"
    # Stop and remove all docker containers and then remove all docker images
    alias docker_nuke='docker_stop; docker_rma; docker_rmi'

    if ! command -v 'iex' &>/dev/null; then
        alias iex='docker run -it elixir:latest iex'
    fi
fi

if command -v 'python' &>/dev/null; then
    alias serve='python -m SimpleHTTPServer'
fi

# On Ubuntu, the system-supplied open file dialog can be very slow to open.
# Running this should fix it temporarily. For more details, see:
# https://askubuntu.com/questions/1341909/file-browser-and-file-dialogs-take-a-long-time-to-open-or-fail-to-open-in-all-ap
if grep 'DISTRIB_ID=Ubuntu' /etc/lsb-release &>/dev/null; then
    alias fix_open_file_dialog='pkill gvfsd-trash'
fi

# Parsec
if command -v 'parsecd' &>/dev/null; then
    alias parsec='parsecd app_daemon=1'
fi
