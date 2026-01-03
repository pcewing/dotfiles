#!/usr/bin/env bash

# Delete any log files that haven't been touched in 14 days
days="14"

DOTFILES_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/logs"

[ -d "$DOTFILES_LOG_DIR" ] && find "$DOTFILES_LOG_DIR" -ctime +$days -type f -exec rm {} \;