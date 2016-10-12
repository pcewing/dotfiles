#!/usr/bin/env bash

function remove_link {
    echo "Removing the $1 link..."
    rm $1
}

echo -e "\nRemoving symlinks"
echo "=============================="

remove_link ~/.ackrc
remove_link ~/.gitconfig
remove_link ~/.gitignore_global
remove_link ~/.config/nvim/init.vim
remove_link ~/.config/i3/config
remove_link ~/.inputrc
remove_link ~/.tmux.conf
remove_link ~/.Xdefaults
remove_link ~/.xinitrc
remove_link ~/.zshrc
