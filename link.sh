#!/usr/bin/env bash

function link {
    local src="$1"
    local dst="$2"

    local dir; dir="$(dirname -- "$dst")"

    echo "Ensuring the directory $dir exists"
    mkdir -p "$dir"

    echo "Creating symlink $dst to $src"
    ln -sf "$src" "$dst"
}

[ -z "$DOTFILES" ] && DOTFILES="$HOME/dot"

echo -e "\\nCreating symlinks"
echo "================="

link "$DOTFILES/config/Xresources"       "$HOME/.Xresources"
link "$DOTFILES/config/bash_profile"     "$HOME/.bash_profile"
link "$DOTFILES/config/bashrc"           "$HOME/.bashrc"
link "$DOTFILES/config/conky.conf"       "$HOME/.config/conky/conky.conf"
link "$DOTFILES/config/dunstrc"          "$HOME/.config/dunst/dunstrc"
link "$DOTFILES/config/env"              "$HOME/.env"
link "$DOTFILES/config/gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/config/gvimrc"           "$HOME/.gvimrc"
link "$DOTFILES/config/i3"               "$HOME/.config/i3/config"
link "$DOTFILES/config/inputrc"          "$HOME/.inputrc"
link "$DOTFILES/config/irssi"            "$HOME/.irssi/config"
link "$DOTFILES/config/mpd"              "$HOME/.config/mpd/mpd.conf"
link "$DOTFILES/config/ncmpcpp/bindings" "$HOME/.config/ncmpcpp/bindings"
link "$DOTFILES/config/ncmpcpp/config"   "$HOME/.config/ncmpcpp/config"
link "$DOTFILES/config/polybar"          "$HOME/.config/polybar/config"
link "$DOTFILES/config/profile"          "$HOME/.profile"
link "$DOTFILES/config/py3status.conf"   "$HOME/.config/py3status/config"
link "$DOTFILES/config/rangerrc"         "$HOME/.config/ranger/rc.conf"
link "$DOTFILES/config/rofi/base16.rasi" "$HOME/.config/rofi/base16.rasi"
link "$DOTFILES/config/rofi/config"      "$HOME/.config/rofi/config"
link "$DOTFILES/config/sway"             "$HOME/.config/sway/config"
link "$DOTFILES/config/tmux.conf"        "$HOME/.tmux.conf"
link "$DOTFILES/config/vimrc"            "$HOME/.config/nvim/init.vim"
link "$DOTFILES/config/vimrc"            "$HOME/.vimrc"
link "$DOTFILES/config/xinitrc"          "$HOME/.xinitrc"
link "$DOTFILES/config/xsession"         "$HOME/.xsession"

# TODO: This is a temporary fix to https://github.com/arybczak/ncmpcpp/issues/91
# because the version of ncmpcpp in the apt repositories doesn't have the real
# fix yet
link "$DOTFILES/config/ncmpcpp/bindings" "$HOME/.ncmpcpp/bindings"

