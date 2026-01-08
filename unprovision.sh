#!/usr/bin/env bash

# Now that we've moved away from shell/python scripts for provisioning hosts
# and we're using Nix instead, use this script to deprovision existing hosts
# that we had set up the old way. Then provision them using the new Nix system.

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

SCRIPT_PATH="$( realpath "$0" )"
SCRIPT_DIR="$( dirname "$SCRIPT_PATH" )"

REMOVE_CORE="true"
REMOVE_DESKTOP="false"
REMOVE_WSL="true"

remove_docker() {
    try sudo apt remove -y containerd.io docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
    try sudo rm -f "/etc/apt/sources.list.d/docker.list"
}

remove_dot_completion() {
    try rm -f "~/.bash_completion.d/dot.bash"
}

remove_flavours() {
    try sudo rm -f "/usr/local/bin/flavours"

    try sudo rm -rf "/opt/flavours"
}

remove_i3wm() {
    try sudo rm -f "/usr/local/bin/i3"
    try sudo rm -f "/usr/local/bin/i3-config-wizard"
    try sudo rm -f "/usr/local/bin/i3-dump-log"
    try sudo rm -f "/usr/local/bin/i3-input"
    try sudo rm -f "/usr/local/bin/i3-msg"
    try sudo rm -f "/usr/local/bin/i3-nagbar"
    try sudo rm -f "/usr/local/bin/i3bar"
    try sudo rm -f "/usr/local/bin/i3-dmenu-desktop"
    try sudo rm -f "/usr/local/bin/i3-save-tree"
    try sudo rm -f "/usr/local/bin/i3-sensible-editor"
    try sudo rm -f "/usr/local/bin/i3-sensible-pager"
    try sudo rm -f "/usr/local/bin/i3-sensible-terminal"

    try sudo rm -rf "/opt/i3"
}

remove_kitty() {
    try sudo rm -f "/usr/local/bin/kitty"
    try sudo rm -f "/usr/local/bin/kitten"

    try sudo rm -rf "/opt/kitty"
}

remove_neovim() {
    try sudo rm -f "/usr/local/bin/nvim"

    try sudo rm -rf "/opt/neovim"
}

remove_nodejs() {
    try sudo rm -f "/usr/local/bin/corepack"
    try sudo rm -f "/usr/local/bin/node"
    try sudo rm -f "/usr/local/bin/npm"
    try sudo rm -f "/usr/local/bin/npx"

    try sudo rm -rf "/opt/nodejs"
}

remove_ripgrep() {
    try sudo apt remove -y ripgrep
}

remove_treesitter() {
    try sudo rm -f "/usr/local/bin/tree-sitter"

    try sudo rm -rf "/opt/tree-sitter"
}

# This one might not be necessary because Nix is going to just download this
# from GitHub the same way that we did manually but let Nix do it to be safe
remove_win32yank() {
    try sudo rm -f "/mnt/c/bin/win32yank.exe"
}

remove_symlink() {
    if [ -L "$1" ]; then
        echo "Removing symlink '$1'"
        try rm -f "$1"
    fi
}

unlink_dotfiles() {
    remove_symlink "$HOME/.xinitrc"
    remove_symlink "$HOME/.profile"
    remove_symlink "$HOME/.config/kitty/kitty.conf"
    remove_symlink "$HOME/.config/wezterm/wezterm.lua"
    remove_symlink "$HOME/.config/sway/config"
    remove_symlink "$HOME/.config/rofi/base16.rasi"
    remove_symlink "$HOME/.config/rofi/config.rasi"
    remove_symlink "$HOME/.config/mpd/mpd.conf"
    remove_symlink "$HOME/.config/flavours"
    remove_symlink "$HOME/.config/dunst/dunstrc"
    remove_symlink "$HOME/.config/i3/config"
    remove_symlink "$HOME/.config/py3status/config"
    remove_symlink "$HOME/.config/ranger/rc.conf"
    remove_symlink "$HOME/.config/alacritty/linux.yml"
    remove_symlink "$HOME/.config/alacritty/base16.yml"
    remove_symlink "$HOME/.config/ncmpcpp/bindings"
    remove_symlink "$HOME/.config/ncmpcpp/config"
    remove_symlink "$HOME/.config/nvim"
    remove_symlink "$HOME/.config/picom/picom.conf"
    remove_symlink "$HOME/.gvimrc"
    remove_symlink "$HOME/.bashrc"
    remove_symlink "$HOME/.inputrc"
    remove_symlink "$HOME/.tmux.conf"
    remove_symlink "$HOME/.env"
    remove_symlink "$HOME/.xsession"
    remove_symlink "$HOME/.bash_profile"
    remove_symlink "$HOME/.gitconfig"
    remove_symlink "$HOME/.Xresources"
    remove_symlink "$HOME/.vimrc"
    remove_symlink "$HOME/.pulse/daemon.conf"
    remove_symlink "$HOME/.swaysession"
}

main() {
    if [ "$REMOVE_CORE" = "true" ]; then
        remove_docker
        remove_dot_completion
        remove_flavours
        remove_neovim
        remove_nodejs
        remove_ripgrep
        remove_treesitter
    fi

    if [ "$REMOVE_DESKTOP" = "true" ]; then
        remove_i3wm
        remove_kitty
    fi

    if [ "$REMOVE_WSL" = "true" ]; then
        remove_win32yank
    fi

    unlink_dotfiles
}

main
