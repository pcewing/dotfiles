alias cl='clear'

alias lv="locate --regex"
alias lV="locate"

alias nvimf="nvim \$(fzf)"

# Git aliases
alias gs='git status --short'
alias gc='git commit'
alias gb='git branch'
alias gac='git add --all && git commit'
alias gd='git diff'
alias gdbc='git_diff_bc3' # This is defined in functions.sh
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
alias clip="xclip -i -selection clipboard"

alias gnome-settings="env XDG_CURRENT_DESKTOP=GNOME gnome-control-center"

[ -z "$(command -v iex)" ] && alias iex="docker run -it elixir:latest iex"

