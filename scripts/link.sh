#!/usr/bin/env bash

DOTFILES=$HOME/.dotfiles
remote=$1

function link {
    if [ -e $2 ]; then
        echo "~${2#$HOME} already exists... Skipping."
    else
        echo "Creating for $1"
        ln -s $1 $2
    fi
}

echo -e "\nCreatings"
echo "=============================="

[[ ! -d ~/.config/nvim ]] && mkdir -p ~/.config/nvim
[[ ! -d ~/.config/i3 ]] && mkdir -p ~/.config/i3

link $DOTFILES/config/gitconfig        ~/.gitconfig
link $DOTFILES/config/gitignore_global ~/.gitignore_global
link $DOTFILES/config/init.vim         ~/.config/nvim/init.vim
link $DOTFILES/config/inputrc          ~/.inputrc
link $DOTFILES/config/tmux.conf        ~/.tmux.conf
link $DOTFILES/config/zshrc            ~/.zshrc
link $DOTFILES/config/rangerrc         ~/.config/ranger/rc.conf

if [[ $remote != true ]]; then
    link $DOTFILES/config/i3config       ~/.config/i3/config
    mkdir -p ~/.config/i3status
    link $DOTFILES/config/i3status.conf  ~/.config/i3status/i3status.conf
    link $DOTFILES/config/Xresources     ~/.Xresources
    link $DOTFILES/config/xinitrc        ~/.xinitrc

    mkdir -p ~/.config/wpr
    link $DOTFILES/config/wprrc.json     ~/.config/wpr/wprrc.json

    mkdir -p ~/.config/polybar
    link $DOTFILES/config/polybar     ~/.config/polybar/config

    # Even though this is technically a console application, I'll never
    # be listening to music on a remote machine.
    link $DOTFILES/config/cmusrc         ~/.config/cmus/rc
fi
