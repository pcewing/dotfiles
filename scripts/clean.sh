#!/usr/bin/env bash

remote=$1

function remove_link {
    echo "Removing the $1 link..."
    rm "$1"
}

echo -e "\\nRemoving symlinks"
echo "=============================="

remove_link "$HOME/.gitconfig"
remove_link "$HOME/.config/nvim/init.vim"
remove_link "$HOME/.inputrc"
remove_link "$HOME/.tmux.conf"
remove_link "$HOME/.zshrc"
remove_link "$HOME/.config/ranger/rc.conf"

if [[ $remote != true ]]; then
    remove_link "$HOME/.config/i3/config"
    remove_link "$HOME/.config/i3status/i3status.conf"
    remove_link "$HOME/.Xresources"
    remove_link "$HOME/.xinitrc"
    remove_link "$HOME/.config/cmus/rc"
    remove_link "$HOME/.config/polybar/config"
fi
