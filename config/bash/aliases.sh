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
alias pinstall="sudo pacman -Sy --noconfirm"
alias psearch="sudo pacman -Ss"
alias premove="sudo pacman -R --noconfirm"

# Wi-Fi aliases
alias wifisearch="nmcli device wifi list"
alias wificonnect="nmcli device wifi connect --ask"

# Git aliases
alias gs='git status --short'
alias gc='git commit'
alias gb='git branch'
alias gac='git add --all && git commit'
alias gd='git diff'
alias gdbc='git_diff_bc3' # This is defined in functions.sh
alias gdm='git difftool -t "meld" -d'
alias gaa='git add --all'
alias gaad='git add --all --dry-run'

# Svn aliases
alias ss='svn status'
alias sd='svn diff --diff-cmd=bcompare_svn'
alias sl='svn log -l'

# Filesystem aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ls="ls --color"

alias n='nautilus . >/dev/null 2>&1 & disown'

# Helpers
alias grep='grep --color=auto'
alias df='df -h' # disk free, in Gigabytes, not bytes
alias du='du -h -c' # calculate disk usage for a folder

# Tmux aliases
alias tm="tmux"
alias ta='tmux attach'
alias tls='tmux ls'
alias tat='tmux attach -t'
alias tns='tmux new-session -s'

# Other
alias sx="startx"
alias notes='ranger ~/notebook'
alias reload_xresources="xrdb -merge ~/.Xresources"
alias reload_aliases="source $DOTFILES/config/bash/aliases.sh"
alias reload_functions="source $DOTFILES/config/bash/functions.sh"
alias clip="xclip -i -selection clipboard"

# List the functions defined in my dotfiles
alias functions="grep -E 'function' $DOTFILES/config/bash/functions.sh | sed -e 's/function //g' | sed -e 's/() {//g'"

alias gnome-settings="env XDG_CURRENT_DESKTOP=GNOME gnome-control-center"

[ -z "$(command -v iex)" ] && alias iex="docker run -it elixir:latest iex"

# Remove all docker containers
alias docker_rma="docker ps --all | grep '^[0-9a-z]' | sed -e 's/ .*//g' | xargs docker rm"

alias aliases="$EDITOR $DOTFILES/config/bash/aliases.sh"
