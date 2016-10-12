#!/usr/bin/env bash

DOTFILES=$HOME/.dotfiles

function link {
    if [ -e $2 ]; then
        echo "~${2#$HOME} already exists... Skipping."
    else
        echo "Creating symlink for $1"
        ln -s $1 $2
    fi
}

echo -e "\nCreating symlinks"
echo "=============================="

[[ ! -d ~/.config/nvim ]] && mkdir -p ~/.config/nvim
[[ ! -d ~/.config/i3 ]] && mkdir -p ~/.config/i3

link $DOTFILES/symlinks/ackrc.symlink            ~/.ackrc
link $DOTFILES/symlinks/gitconfig.symlink        ~/.gitconfig
link $DOTFILES/symlinks/gitignore_global.symlink ~/.gitignore_global
link $DOTFILES/symlinks/init.vim.symlink         ~/.config/nvim/init.vim
link $DOTFILES/symlinks/i3config.symlink         ~/.config/i3/config
link $DOTFILES/symlinks/inputrc.symlink          ~/.inputrc
link $DOTFILES/symlinks/tmux.conf.symlink        ~/.tmux.conf
link $DOTFILES/symlinks/Xdefaults.symlink        ~/.Xdefaults
link $DOTFILES/symlinks/xinitrc.symlink          ~/.xinitrc
link $DOTFILES/symlinks/zshrc.symlink            ~/.zshrc
