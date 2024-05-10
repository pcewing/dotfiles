#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

[ -z "$DOTFILES" ] && DOTFILES="$HOME/dot"

function usage() {
    yell "Usage: dot.sh <command>"
    yell "Commands:"
    yell "    windows   : Create symlinks to dotfiles on Windows"
}

# Symlinks in Git Bash aren't great due to Windows requiring administrator
# privileges to create them. See:
# https://stackoverflow.com/questions/18641864/git-bash-shell-fails-to-create-symbolic-links/40914277#40914277
#
# Instead, just copy the files to their destination. This makes it easy to
# accidentally update the wrong file and overwrite changes when re-linking so
# to mitigate that we mark the files as read-only.
function link_windows() {
    local src="$1"
    local dst="$2"

    local dir
    dir="$(dirname -- "$dst")"

    echo "Ensuring the parent directory $dir exists"
    mkdir -p "$dir"

    # Make sure destination file doesn't already exist; the -f flag is needed
    # here because we mark these files as read-only when creating them
    rm -f "$dst" &>"/dev/null"

    echo "Copying $dst to $src"
    cp "$src" "$dst"

    # This is a Windows command to set the read-only flag but it should work
    # correctly from Git Bash
    attrib +r "$dst"
}

function cmd_windows() {
    local cfg
    cfg="$DOTFILES/config"

    # TODO: This has fallen out of sync with the newer links.json approach. We
    # should implement a command for this in the Python CLI instead and then
    # delete this file entirely.

    link_windows "$cfg/profile"         "$HOME/.profile"
    link_windows "$cfg/env"             "$HOME/.env"
    link_windows "$cfg/bashrc"          "$HOME/.bashrc"
    link_windows "$cfg/bash_profile"    "$HOME/.bash_profile"
    link_windows "$cfg/vimrc"           "$HOME/.vimrc"
    link_windows "$cfg/vimrc"           "$HOME/AppData/Local/nvim/init.vim"
    link_windows "$cfg/gvimrc"          "$HOME/.gvimrc"
    link_windows "$cfg/vsvimrc"         "$HOME/.vsvimrc"
    link_windows "$cfg/gitconfig"       "$HOME/.gitconfig"
    link_windows "$cfg/alacritty.yml"   "$APPDATA/alacritty/alacritty.yml"

    link_windows "$cfg/alacritty/base16.yml"    "$HOME/.config/alacritty/base16.yml"
    link_windows "$cfg/alacritty/windows.yml"   "$HOME/.config/alacritty/windows.yml"

    link_windows "$cfg/wezterm.lua"     "$HOME/.config/wezterm/wezterm.lua"
}

case "$1" in
    "windows")  cmd_windows ;;
    *)          usage       ;;
esac
