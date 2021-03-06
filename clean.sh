#!/usr/bin/env bash

function remove_link {
    local link="$1"
    echo "Removing $link..."
    rm "$link"
}

echo -e "\\nRemoving symlinks"
echo "=============================="

remove_link "$HOME/.Xresources"
remove_link "$HOME/.bash_profile"
remove_link "$HOME/.bashrc"
remove_link "$HOME/.config/alacritty/alacritty.yml"
remove_link "$HOME/.config/conky/conky.conf"
remove_link "$HOME/.config/dunst/dunstrc"
remove_link "$HOME/.config/i3/config"
remove_link "$HOME/.config/mpd/mpd.conf"
remove_link "$HOME/.config/ncmpcpp/bindings"
remove_link "$HOME/.config/ncmpcpp/config"
remove_link "$HOME/.config/nvim/init.vim"
remove_link "$HOME/.config/polybar/config"
remove_link "$HOME/.config/py3status/config"
remove_link "$HOME/.config/ranger/rc.conf"
remove_link "$HOME/.config/rofi/config"
remove_link "$HOME/.config/rofi/dracula.rasi"
remove_link "$HOME/.config/sway/config"
remove_link "$HOME/.pulse/daemon.conf"
remove_link "$HOME/.env"
remove_link "$HOME/.gitconfig"
remove_link "$HOME/.gvimrc"
remove_link "$HOME/.inputrc"
remove_link "$HOME/.irssi/config"
remove_link "$HOME/.irssi/dracula.theme"
remove_link "$HOME/.profile"
remove_link "$HOME/.swaysession"
remove_link "$HOME/.tmux.conf"
remove_link "$HOME/.vimrc"
remove_link "$HOME/.xinitrc"
remove_link "$HOME/.xsession"
remove_link "$HOME/.config/nvim/UltiSnips/cpp.snippets"

# TODO: This is a temporary fix to https://github.com/arybczak/ncmpcpp/issues/91
# because the version of ncmpcpp in the apt repositories doesn't have the real
# fix yet
remove_link "$HOME/.ncmpcpp/bindings"

echo -e "\nRemoving symlink for sway-user.desktop requires root priveleges; run:"
echo "sudo rm \"/usr/share/wayland-sessions/sway-user.desktop\""
