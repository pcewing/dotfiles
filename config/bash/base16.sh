#!/usr/bin/env bash

# If the shell is non-interactive, don't do anything
[[ $- == *i* ]] || return

# Base16 color scheme
base16_shell_dir="$HOME/.config/base16-shell"
[ ! -d "$base16_shell_dir" ] && \
    git clone "https://github.com/chriskempson/base16-shell.git" \
        "$base16_shell_dir"

BASE16_SHELL_SET_BACKGROUND=true
if uname | grep -i 'linux' &>/dev/null; then
    BASE16_SHELL_SET_BACKGROUND=false
fi

BASE16_SHELL="$HOME/.config/base16-shell/"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        source "$BASE16_SHELL/profile_helper.sh"
