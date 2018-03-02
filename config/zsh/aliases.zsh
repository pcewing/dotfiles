# Reload zsh config
alias reload!='source ~/.zshrc'

alias lv="locate --regex"
alias lV="locate"

alias nvimf="nvim \$(fzf)"

# Git aliases
alias gs='git status --short'
alias gc='git commit'
alias gd='git diff'
alias gaa='git add --all'
alias gaad='git add --all --dry-run'

# Svn aliases
alias ss='svn status'
alias sd='svn diff --diff-cmd=bcompare_svn'

# Filesystem aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ls="ls --color"

# Helpers
alias grep='grep --color=auto'
alias df='df -h' # disk free, in Gigabytes, not bytes
alias du='du -h -c' # calculate disk usage for a folder

# Tmux aliases
alias ta='tmux attach'
alias tls='tmux ls'
alias tat='tmux attach -t'
alias tns='tmux new-session -s'

# Other
alias sx="startx"

