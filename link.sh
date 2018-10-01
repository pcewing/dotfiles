#!/usr/bin/env bash

function create_folder {
    local dir="$1"
    echo "Ensuring the directory $dir exists"
    mkdir -p "$dir"
}

function link {
    local src="$1"
    local dst="$2"
    echo "Creating symlink $dst to $src"
    ln -sf "$src" "$dst"
}

echo -e "\\nEnsuring XDG folders exist"
echo "=========================="

create_folder "$HOME/.config/cmus"
create_folder "$HOME/.config/i3"
create_folder "$HOME/.config/i3status"
create_folder "$HOME/.config/mpd"
create_folder "$HOME/.config/ranger"
create_folder "$HOME/.config/nvim"
create_folder "$HOME/.config/polybar"

echo -e "\\nCreating symlinks"
echo "================="

link "$DOTFILES/config/bash_profile"     "$HOME/.bash_profile"
link "$DOTFILES/config/bashrc"           "$HOME/.bashrc"
link "$DOTFILES/config/cmusrc"           "$HOME/.config/cmus/rc"
link "$DOTFILES/config/env"              "$HOME/.env"
link "$DOTFILES/config/gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/config/gvimrc"           "$HOME/.gvimrc"
link "$DOTFILES/config/inputrc"          "$HOME/.inputrc"
link "$DOTFILES/config/i3config"         "$HOME/.config/i3/config"
link "$DOTFILES/config/i3status.conf"    "$HOME/.config/i3status/i3status.conf"
link "$DOTFILES/config/mpd"              "$HOME/.config/mpd/mpd.conf"
link "$DOTFILES/config/ncmpcpp/bindings" "$HOME/.config/ncmpcpp/bindings"
link "$DOTFILES/config/ncmpcpp/config"   "$HOME/.config/ncmpcpp/config"
link "$DOTFILES/config/polybar"          "$HOME/.config/polybar/config"
link "$DOTFILES/config/profile"          "$HOME/.profile"
link "$DOTFILES/config/rangerrc"         "$HOME/.config/ranger/rc.conf"
link "$DOTFILES/config/tmux.conf"        "$HOME/.tmux.conf"
link "$DOTFILES/config/vimrc"            "$HOME/.vimrc"
link "$DOTFILES/config/vimrc"            "$HOME/.config/nvim/init.vim"
link "$DOTFILES/config/xinitrc"          "$HOME/.xinitrc"

# TODO: This is a temporary fix to https://github.com/arybczak/ncmpcpp/issues/91
# because the version of ncmpcpp in the apt repositories doesn't have the real
# fix yet
link "$DOTFILES/config/ncmpcpp/bindings" "$HOME/.ncmpcpp/bindings"
