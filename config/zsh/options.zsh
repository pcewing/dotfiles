# See section 2.5.1: http://zsh.sourceforge.net/Guide/zshguide02.html
setopt NO_BG_NICE
setopt NO_HUP
setopt LOCAL_OPTIONS
setopt LOCAL_TRAPS
setopt PROMPT_SUBST

# See section 2.5.3: http://zsh.sourceforge.net/Guide/zshguide02.html
setopt HIST_VERIFY

# See section 2.5.4: http://zsh.sourceforge.net/Guide/zshguide02.html
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

# See section 2.5.5: http://zsh.sourceforge.net/Guide/zshguide02.html
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# See section 4.2.2: http://zsh.sourceforge.net/Guide/zshguide04.html
setopt IGNORE_EOF

# See section 6.2.1: http://zsh.sourceforge.net/Guide/zshguide06.html
setopt NO_LIST_BEEP

# See section 6.2.4: http://zsh.sourceforge.net/Guide/zshguide06.html
setopt COMPLETE_ALIASES

# See section 9.1: http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
bindkey -v

