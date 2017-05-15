source $HOME/.zsh/antigen.zsh

# Plugins
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions

# Themes
antigen theme bhilburn/powerlevel9k powerlevel9k

antigen apply

# Plugin configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=10'

# Sometimes turning off version control is useful because it can slow down
# the shell significantly
#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(time dir)
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(time dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs)
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
