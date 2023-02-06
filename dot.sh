#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

[ -z "$DOTFILES" ] && DOTFILES="$HOME/dot"

function usage() {
    yell "Usage: dot.sh <command>"
    yell "Commands:"
    yell "    link      : Create symlinks to dotfiles"
    yell "    clean     : Remove symlinks to dotfiles"
    yell "    windows   : Create symlinks to dotfiles on Windows"
}

function link() {
    local src="$1"
    local dst="$2"

    local dir; dir="$(dirname -- "$dst")"

    echo "Ensuring the directory $dir exists"
    mkdir -p "$dir"

    echo "Creating symlink $dst to $src"
    ln -sf "$src" "$dst"
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

    echo "Ensuring the directory $dir exists"
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

function unlink() {
    local link="$1"
    echo "Removing $link..."
    rm "$link"
}

function cmd_clean() {
    echo -e "\\nRemoving symlinks"
    echo "=============================="

    unlink "$HOME/.Xresources"
    unlink "$HOME/.bash_profile"
    unlink "$HOME/.bashrc"
    unlink "$HOME/.config/dunst/dunstrc"
    unlink "$HOME/.config/i3/config"
    unlink "$HOME/.config/mpd/mpd.conf"
    unlink "$HOME/.config/ncmpcpp/bindings"
    unlink "$HOME/.config/ncmpcpp/config"
    unlink "$HOME/.config/nvim/init.vim"
    unlink "$HOME/.config/py3status/config"
    unlink "$HOME/.config/ranger/rc.conf"
    unlink "$HOME/.config/rofi/config.rasi"
    unlink "$HOME/.config/rofi/dracula.rasi"
    unlink "$HOME/.config/sway/config"
    unlink "$HOME/.pulse/daemon.conf"
    unlink "$HOME/.env"
    unlink "$HOME/.gitconfig"
    unlink "$HOME/.gvimrc"
    unlink "$HOME/.inputrc"
    unlink "$HOME/.profile"
    unlink "$HOME/.swaysession"
    unlink "$HOME/.tmux.conf"
    unlink "$HOME/.vimrc"
    unlink "$HOME/.xinitrc"
    unlink "$HOME/.xsession"
    unlink "$HOME/.config/nvim/UltiSnips/cpp.snippets"

    echo -e "\nRemoving symlink for sway-user.desktop requires root priveleges; run:"
    echo "sudo rm \"/usr/share/wayland-sessions/sway-user.desktop\""
}

function cmd_link() {
    echo -e "\\nCreating symlinks"
    echo "================="

    link "$DOTFILES/config/Xresources"       "$HOME/.Xresources"
    link "$DOTFILES/config/bash_profile"     "$HOME/.bash_profile"
    link "$DOTFILES/config/bashrc"           "$HOME/.bashrc"
    link "$DOTFILES/config/dunstrc"          "$HOME/.config/dunst/dunstrc"
    link "$DOTFILES/config/env"              "$HOME/.env"
    link "$DOTFILES/config/gitconfig"        "$HOME/.gitconfig"
    link "$DOTFILES/config/gvimrc"           "$HOME/.gvimrc"
    link "$DOTFILES/config/i3"               "$HOME/.config/i3/config"
    link "$DOTFILES/config/inputrc"          "$HOME/.inputrc"
    link "$DOTFILES/config/mpd"              "$HOME/.config/mpd/mpd.conf"
    link "$DOTFILES/config/ncmpcpp/bindings" "$HOME/.config/ncmpcpp/bindings"
    link "$DOTFILES/config/ncmpcpp/config"   "$HOME/.config/ncmpcpp/config"
    link "$DOTFILES/config/profile"          "$HOME/.profile"
    link "$DOTFILES/config/pulse/daemon.conf" "$HOME/.pulse/daemon.conf"
    link "$DOTFILES/config/py3status.conf"   "$HOME/.config/py3status/config"
    link "$DOTFILES/config/rangerrc"         "$HOME/.config/ranger/rc.conf"
    link "$DOTFILES/config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
    link "$DOTFILES/config/rofi/dracula.rasi" "$HOME/.config/rofi/dracula.rasi"
    link "$DOTFILES/config/sway"             "$HOME/.config/sway/config"
    link "$DOTFILES/config/swaysession"      "$HOME/.swaysession"
    link "$DOTFILES/config/tmux.conf"        "$HOME/.tmux.conf"
    link "$DOTFILES/config/vimrc"            "$HOME/.config/nvim/init.vim"
    link "$DOTFILES/config/vimrc"            "$HOME/.vimrc"
    link "$DOTFILES/config/xinitrc"          "$HOME/.xinitrc"
    link "$DOTFILES/config/xsession"         "$HOME/.xsession"
    link "$DOTFILES/config/snippets/cpp.snippets" "$HOME/.config/nvim/UltiSnips/cpp.snippets"
}

function cmd_windows() {
    link_windows "$DOTFILES/config/profile"         "$HOME/.profile"
    link_windows "$DOTFILES/config/env"             "$HOME/.env"
    link_windows "$DOTFILES/config/bashrc"          "$HOME/.bashrc"
    link_windows "$DOTFILES/config/bash_profile"    "$HOME/.bash_profile"
    link_windows "$DOTFILES/config/vimrc"           "$HOME/.vimrc"
    link_windows "$DOTFILES/config/vimrc"           "$HOME/AppData/Local/nvim/init.vim"
    link_windows "$DOTFILES/config/gvimrc"          "$HOME/.gvimrc"
    link_windows "$DOTFILES/config/vsvimrc"         "$HOME/.vsvimrc"
    link_windows "$DOTFILES/config/gitconfig"       "$HOME/.gitconfig"
    link_windows "$DOTFILES/config/alacritty.yml"   "$APPDATA/alacritty/alacritty.yml"
}

case "$1" in
    "link")     cmd_link    ;;
    "clean")    cmd_clean   ;;
    "windows")  cmd_windows ;;
    *)          usage       ;;
esac
