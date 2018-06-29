#!/usr/bin/env bash

remote=$1

function link {
    echo "Creating for $1"
    ln -sf "$1" "$2"
}

echo -e "\\nCreating symlinks"
echo "=============================="

link "$DOTFILES/config/gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/config/inputrc"          "$HOME/.inputrc"
link "$DOTFILES/config/tmux.conf"        "$HOME/.tmux.conf"
link "$DOTFILES/config/zshrc"            "$HOME/.zshrc"

link "$DOTFILES/config/vimrc"            "$HOME/.vimrc"

mkdir -p "$HOME/.config/nvim"
link "$DOTFILES/config/vimrc"            "$HOME/.config/nvim/init.vim"

mkdir -p "$HOME/.config/ranger"
link "$DOTFILES/config/rangerrc"         "$HOME/.config/ranger/rc.conf"

if [[ $remote != true ]]; then
    link "$DOTFILES/config/Xresources"     "$HOME/.Xresources"
    link "$DOTFILES/config/xinitrc"        "$HOME/.xinitrc"

    mkdir -p "$HOME/.config/i3"
    link "$DOTFILES/config/i3config"       "$HOME/.config/i3/config"

    mkdir -p "$HOME/.config/i3status"
    link "$DOTFILES/config/i3status.conf"  "$HOME/.config/i3status/i3status.conf"

    mkdir -p "$HOME/.config/polybar"
    link "$DOTFILES/config/polybar"     "$HOME/.config/polybar/config"

    mkdir -p "$HOME/.config/cmus"
    link "$DOTFILES/config/cmusrc"         "$HOME/.config/cmus/rc"
fi
