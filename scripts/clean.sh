#!/usr/bin/env bash

remote=$1

function remove_link {
    echo "Removing the $1 link..."
    rm $1
}

echo -e "\nRemoving symlinks"
echo "=============================="

remove_link ~/.gitconfig
remove_link ~/.gitignore_global
remove_link ~/.config/nvim/init.vim
remove_link ~/.inputrc
remove_link ~/.tmux.conf
remove_link ~/.zshrc
remove_link ~/.config/ranger/rc.conf

if [[ $remote != true ]]; then
    remove_link ~/.config/i3/config
    remove_link ~/.config/i3status/config
    remove_link ~/.Xresources
    remove_link ~/.xinitrc
    remove_link ~/.config/cmus/rc
    remove_link ~/.config/wpr/wprrc.json
    remove_link ~/.config/polybar/config
fi
