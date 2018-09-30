#!/usr/bin/env bash

function remove_link {
    local link="$1"
    echo "Removing $link..."
    rm "$link"
}

echo -e "\\nRemoving symlinks"
echo "=============================="

remove_link "$HOME/.bash_profile"
remove_link "$HOME/.bashrc"
remove_link "$HOME/.config/cmus/rc"
remove_link "$HOME/.env"
remove_link "$HOME/.gitconfig"
remove_link "$HOME/.gvimrc"
remove_link "$HOME/.inputrc"
remove_link "$HOME/.config/i3/config"
remove_link "$HOME/.config/i3status/i3status.conf"
remove_link "$HOME/.config/mpd/mpd.conf"
remove_link "$HOME/.config/polybar/config"
remove_link "$HOME/.profile"
remove_link "$HOME/.config/ranger/rc.conf"
remove_link "$HOME/.tmux.conf"
remove_link "$HOME/.vimrc"
remove_link "$HOME/.config/nvim/init.vim"
remove_link "$HOME/.xinitrc"