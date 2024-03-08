#!/usr/bin/env bash

# Some core bash utilities used throughout other dotfiles.

if [ -z "$DOT_CORE_SOURCED" ]; then
    DOT_CORE_SOURCED=1

    function _is_wsl() {
        [ -n "$WSL_DISTRO_NAME" ] && return 0 || return 1
    }

    # Using `command -v foo` on WSL is very slow. I profiled this on 2024/03/08
    # on my desktop PC which is relatively powerful and it was regularly taking
    # 40-60ms to resolve. This caused my bash startup time in WSL to be very
    # slow because we used this in several places, such as when setting
    # aliases. To avoid that, don't bother checking if commands already exist
    # in WSL. For any scripts where the existence of the command is important,
    # don't use this function.
    function _is_installed() {
        _is_wsl && return 0 || command -v "$1" &>/dev/null
    }
fi
