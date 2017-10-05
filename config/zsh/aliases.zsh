# Reload zsh config.
alias reload!='source ~/.zshrc'

alias lv="locate --regex"
alias lV="locate"

# Forget about vim.
alias vim="nvim"
alias nvimf="nvim \$(fzf)"

# Filesystem aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ls="ls --color"
alias l="ls -lah --color"
alias la="ls -AF --color"
alias ll="ls -lFh --color"
alias lld="ls -l | grep ^d"
alias rmf="rm -rf"

# Helpers
alias grep='grep --color=auto'
alias df='df -h' # disk free, in Gigabytes, not bytes
alias du='du -h -c' # calculate disk usage for a folder

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"

# File size
alias fs="stat -f \"%z bytes\""

# Git Aliases
alias ga='git add'
alias gc='git commit'
alias gaa='git add --all'
alias gaad='git add --all --dry-run'
alias gb='git branch'
alias gl='git pull'
alias gp='git push'
alias gd='git diff'
alias gdc='git diff --cached'
alias gs='git s'
alias gss='git stash save'
alias gsp='git stash pop'
alias gmv='git mv'
alias grm='git rm'
alias grn='git-rename'
alias glog="git l"

alias git-amend='git commit --amend -C HEAD'
alias git-undo='git reset --soft HEAD~1'
alias git-count='git shortlog -sn'
alias git-undopush="git push -f origin HEAD^:master"

# Git root
alias gr='[ ! -z `git rev-parse --show-cdup` ] && cd `git rev-parse --show-cdup || pwd`'

alias sub-pull='git submodule foreach git pull origin master'

# Tmux aliases
alias ta='tmux attach'
alias tls='tmux ls'
alias tat='tmux attach -t'
alias tns='tmux new-session -s'
