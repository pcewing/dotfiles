alias cl='clear'
alias x='exit'

alias lv="locate --regex"
alias lV="locate"

alias nvimf="nvim \$(fzf)"
alias nvimd="nvim $DOTFILES"
alias nvimt="nvim \$(mktemp)"
alias nvimdiff="nvim -d"

# Apt aliases
alias apti="sudo apt install -y"
alias apts="sudo apt search"

# Pacman aliases
alias pinstall="sudo pacman -Syu --noconfirm"
alias psearch="sudo pacman -Ss"
alias premove="sudo pacman -R --noconfirm"
#alias pupdate="sudo pacman -Syu --noconfirm"
alias pupdate="sudo pacman -Syyu --noconfirm"

# Wi-Fi aliases
alias wifisearch="nmcli device wifi list"
alias wificonnect="nmcli device wifi connect --ask"

# Git aliases
alias gs='git status --short'
alias gc='git commit'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gb='git branch'
alias gbc='git branch --show-current'
alias gac='git add --all && git commit'
alias gd='git diff'
alias gdbc='git_diff_bc3' # This is defined in functions.sh
alias gdm='git difftool -t "meld" -d'
alias gaa='git add --all'
alias gaad='git add --all --dry-run'

# Filesystem aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ls="ls --color"
alias lsl="ls -l --group-directories-first"
alias lss="ls --sort=extension --group-directories-first"

# Helpers
alias grep='grep --color=auto'

# Make disk free always human-readable
alias df='df -h' 

# Sorted, human-readable disk usage by depth
alias du1='du -hd1 2>/dev/null | sort -hr'
alias du2='du -hd2 2>/dev/null | sort -hr'
alias du3='du -hd3 2>/dev/null | sort -hr'
alias du4='du -hd4 2>/dev/null | sort -hr'
alias du5='du -hd5 2>/dev/null | sort -hr'

# Tmux aliases
alias tm="tmux"
alias tms="tmux new-session -s \"\$(basename \"\$(pwd)\")\""
alias tma='tmux attach'

# HashiCorp Tools
alias tf='terraform'
alias csl='consul'

# Restart mpd
alias mpd_restart='mpd --kill; mpd'

# Restart wpr (TODO: Make wpr a user systemd service)
alias wpr_restart='killall wpr &>/dev/null; wpr &>/dev/null &'

# Other
alias sx="startx"
alias notes='ranger ~/notebook'
alias reload_xresources="xrdb -merge ~/.Xresources"
alias clip="xclip -i -selection clipboard"

alias gnome-settings="env XDG_CURRENT_DESKTOP=GNOME gnome-control-center"

[ -z "$(command -v iex)" ] && alias iex="docker run -it elixir:latest iex"

# Stop all docker containers
alias docker_stop="docker ps | tail -n +2 | awk '{print \$1}' | xargs docker stop"
# Remove all docker containers
alias docker_rma="docker ps --all | tail -n +2 | sed -e 's/ .*//g' | xargs docker rm"
# Remove all docker images
alias docker_rmi="docker images --all | tail -n +2 | awk '{ print $3 }' | xargs docker rmi -f"
# Stop and remove all docker containers and then remove all docker images
alias docker_nuke="docker_stop; docker_rma; docker_rmi"

alias serve="python -m SimpleHTTPServer"

alias aliases="$EDITOR $DOTFILES/config/bash/aliases.sh"
alias functions="$EDITOR $DOTFILES/config/bash/functions.sh"
alias reload_aliases="source $DOTFILES/config/bash/aliases.sh"
alias reload_functions="source $DOTFILES/config/bash/functions.sh"

# On Ubuntu, the system-supplied open file dialog can be very slow to open.
# Running this should fix it temporarily. For more details, see:
# https://askubuntu.com/questions/1341909/file-browser-and-file-dialogs-take-a-long-time-to-open-or-fail-to-open-in-all-ap
alias fix_open_file_dialog="pkill gvfsd-trash"

# NoMachine
alias nomachine_client="/usr/NX/bin/nxplayer"

# Parsec
alias parsec="parsecd app_daemon=1"
