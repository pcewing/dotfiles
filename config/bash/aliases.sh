#!/usr/bin/env bash

# Disable this for the whole file because there are a lot of cases where we
# intentionally don't want to expand variables.
# shellcheck disable=SC2016

function yell() { >&2 echo "$*";  }

function _is_installed() {
    local cmd
    cmd="$1"
    command -v "$cmd" &>/dev/null
}

function set_alias() {
    local override name command

    override="$1"
    name="$2"
    command="$3"

    if [ "$override" = "0" ]; then
        if COMMAND_OUTPUT="$( command -v "$name" )"; then
            if ! echo "$COMMAND_OUTPUT" | grep -E '^alias .*' &>/dev/null; then
                yell "ERROR: Setting alias '$name' would override an existing command"
                return 1
            fi
        fi
    fi

    # Disable this warning because we want the name to expand here
    # shellcheck disable=SC2139
    alias "$name=$command"
}

# Edit/reload bash configs
set_alias '0' 'aliases'             '$EDITOR $DOTFILES/config/bash/aliases.sh'
set_alias '0' 'functions'           '$EDITOR $DOTFILES/config/bash/functions.sh'
set_alias '0' 'reload_aliases'      'source $DOTFILES/config/bash/aliases.sh'
set_alias '0' 'reload_functions'    'source $DOTFILES/config/bash/functions.sh'
set_alias '0' 'localrc'             '$EDITOR $HOME/.localrc'

# Basic aliases
set_alias '0' 'cl'  'clear'
set_alias '0' 'x'   'exit'

# Filesystem aliases
set_alias '0' '..'      'cd ..'
set_alias '0' '...'     'cd ../..'
set_alias '0' '....'    'cd ../../..'
set_alias '0' '.....'   'cd ../../../..'
set_alias '1' 'ls'      'ls --color'
set_alias '0' 'lsl'     'ls -l --group-directories-first'
set_alias '0' 'lss'     'ls --sort=extension --group-directories-first'

# Helpers
set_alias '1' 'grep' 'grep --color=auto'

# I can never remember where core dumps are by default on Ubuntu
# TODO: We should probably make a function for this so we can do something more powerful. Like:
# - Pipe the list of core files into FZF
# - If one is selected, open it with GDB
set_alias '0' 'cores' 'echo -e "/var/lib/apport/coredump\n" && ls /var/lib/apport/coredump -l'

# Make disk free always human-readable
if _is_installed 'df'; then
    set_alias '1' 'df' 'df -h'
fi

# Sorted, human-readable disk usage by depth
if _is_installed 'du'; then
    set_alias '0' 'du1' 'du -hd1 2>/dev/null | sort -hr'
    set_alias '0' 'du2' 'du -hd2 2>/dev/null | sort -hr'
    set_alias '0' 'du3' 'du -hd3 2>/dev/null | sort -hr'
    set_alias '0' 'du4' 'du -hd4 2>/dev/null | sort -hr'
    set_alias '0' 'du5' 'du -hd5 2>/dev/null | sort -hr'
fi

# Ranger aliases
if _is_installed 'ranger'; then
    set_alias '0' 'r'       'ranger'
    set_alias '0' 'notes'   'ranger ~/notebook'
fi

# Locate aliases
if _is_installed 'locate'; then
    set_alias '0' 'lv' 'locate --regex'
    set_alias '0' 'lV' 'locate'
fi

# Neovim aliases
if _is_installed 'nvim'; then
    set_alias '0' 'nvimf'       'nvim $(fzf)'
    set_alias '0' 'nvimd'       'nvim $DOTFILES'
    set_alias '0' 'nvimt'       'nvim $(mktemp)'
    set_alias '0' 'nvimdiff'    'nvim -d'
fi

# Apt aliases
if _is_installed 'apt'; then
    set_alias '0' 'apti' 'sudo apt install -y'
    set_alias '0' 'apts' 'sudo apt search'
fi

# Pacman aliases
if _is_installed 'pacman'; then
    set_alias '0' 'pinstall'    'sudo pacman -Syu --noconfirm'
    set_alias '0' 'psearch'     'sudo pacman -Ss'
    set_alias '0' 'premove'     'sudo pacman -R --noconfirm'
    set_alias '0' 'pupdate'     'sudo pacman -Syyu --noconfirm'
fi

# Wi-Fi aliases
if _is_installed 'nmcli'; then
    set_alias '0' 'wifisearch' 'nmcli device wifi list'
    set_alias '0' 'wificonnect' 'nmcli device wifi connect --ask'
fi

# Git aliases
if _is_installed 'git'; then
    set_alias '1' 'gs'      'git status --short'
    set_alias '0' 'gc'      'git commit'
    set_alias '0' 'gco'     'git checkout'
    set_alias '0' 'gcob'    'git checkout -b'
    set_alias '0' 'gb'      'git branch'
    set_alias '0' 'gbc'     'git branch --show-current'
    set_alias '0' 'gac'     'git add --all && git commit'
    set_alias '0' 'gd'      'git diff'
    set_alias '0' 'gdt'     'git difftool --dir-diff --no-symlinks'
    set_alias '0' 'gdm'     'git difftool -t "meld" -d'
    set_alias '0' 'gaa'     'git add --all'
    set_alias '0' 'gaad'    'git add --all --dry-run'
    set_alias '0' 'gpl'     'git pull origin $(gbc)'
    set_alias '0' 'gps'     'git push origin $(gbc)'
fi

# SVN aliases
if _is_installed 'svn'; then
    set_alias '1' 'ss'  'svn status'
    set_alias '0' 'sd'  'svn diff'
    set_alias '0' 'sdt' 'svn diff --diff-cmd=bcompare_svn'
    set_alias '0' 'sl'  'svn log -l'
fi

# Tmux aliases
if _is_installed 'tmux'; then
    set_alias '0' 'tm'  'tmux'
    set_alias '0' 'tms' "tmux new-session -s \"\$(basename \"\$(pwd)\")\""
    set_alias '0' 'tma' 'tmux attach'
fi

if _is_installed 'terraform'; then
    set_alias '0' 'tf' 'terraform'
fi

if _is_installed 'consul'; then
    set_alias '0' 'csl' 'consul'
fi

# Restart mpd
if _is_installed 'mpd'; then
    set_alias '0' 'mpd_restart' 'mpd --kill; mpd'
fi

# Restart wpr
if _is_installed 'wpr'; then
    set_alias '0' 'wpr_restart' 'killall wpr &>/dev/null; wpr &>/dev/null &'
fi

# Other
if _is_installed 'startx'; then
    set_alias '0' 'sx' 'startx'
fi

if _is_installed 'xrdb'; then
    set_alias '0' 'reload_xresources' 'xrdb -merge ~/.Xresources'
fi

if _is_installed 'xclip'; then
    set_alias '0' 'clip' 'xclip -i -selection clipboard'
fi

if _is_installed 'gnome-control-center'; then
    set_alias '0' 'gnome-settings' 'env XDG_CURRENT_DESKTOP=GNOME gnome-control-center'
fi

# Docker utilities
if _is_installed 'docker'; then
    set_alias '0' 'dps' 'docker_pss'

    # Stop all docker containers
    # shellcheck disable=SC2142
    set_alias '0' 'docker_stop' "docker ps | tail -n +2 | awk '{print \$1}' | xargs docker stop"

    # Remove all docker containers
    set_alias '0' 'docker_rma' "docker ps --all | tail -n +2 | sed -e 's/ .*//g' | xargs docker rm"

    # Remove all docker images
    # shellcheck disable=SC2142
    set_alias '0' 'docker_rmi' "docker images --all | tail -n +2 | awk '{ print \$3 }' | xargs docker rmi -f"

    # Stop and remove all docker containers and then remove all docker images
    set_alias '0' 'docker_nuke' 'docker_stop; docker_rma; docker_rmi'

    if ! _is_installed 'iex'; then
        set_alias '0' 'iex' 'docker run -it elixir:latest iex'
    fi
fi

if _is_installed 'python'; then
    set_alias '0' 'serve' 'python -m SimpleHTTPServer'
fi

# On Ubuntu, the system-supplied open file dialog can be very slow to open.
# Running this should fix it temporarily. For more details, see:
# https://askubuntu.com/questions/1341909/file-browser-and-file-dialogs-take-a-long-time-to-open-or-fail-to-open-in-all-ap
if grep 'DISTRIB_ID=Ubuntu' /etc/lsb-release &>/dev/null; then
    set_alias '0' 'fix_open_file_dialog' 'pkill gvfsd-trash'
fi

# Parsec
if _is_installed 'parsecd'; then
    set_alias '0' 'parsec' 'parsecd app_daemon=1'
fi
