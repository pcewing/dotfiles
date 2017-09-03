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
link $DOTFILES/config/cmusrc           ~/.config/cmus/rc
link $DOTFILES/config/rangerrc         ~/.config/ranger/rc.conf

if [[ $remote != true ]]; then
  link $DOTFILES/config/i3config       ~/.config/i3/config
  link $DOTFILES/config/Xdefaults      ~/.Xdefaults
  link $DOTFILES/config/xinitrc        ~/.xinitrc
fi
