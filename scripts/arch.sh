#!/usr/bin/env bash

echo -e "\nRunning Arch Linux Installation"
echo "================================="

# Downloads and extracts a package from the AUR.
# Example usage: download_aur "dropbox"
function download_aur {
  (
    app=$1

    mkdir -p ~/builds
    cd ~/builds
    curl -L -O https://aur.archlinux.org/cgit/aur.git/snapshot/${app}.tar.gz
    tar -xvf ${app}.tar.gz

    # This generally isn't safe, but this script will only be downloading trusted packages
    # and there isn't any sensitive information on the system yet as it's the inital
    # configuration.
    cd ${app}
    makepkg --noconfirm -sri
  )
}

# Install a graphics driver.
# WARNING: Make sure this line is correct for your own system.
sudo pacman -S --noconfirm nvidia nvidia-libgl

# Install base-devel which is necessary for building some packages from the AUR
sudo pacman -S --noconfirm base-devel

# Install Xorg
sudo pacman -S --noconfirm xorg-server xorg-server-utils

# Install i3 Window Manager and DMenu
sudo pacman -S --noconfirm i3-wm i3status i3lock dmenu

# Install URxvt
sudo pacman -S --noconfirm rxvt-unicode

# Install the Ubuntu font family (Powerline derivative)
sudo pacman -S --noconfirm bdf-unifont
download_aur "ttf-ubuntu-mono-derivative-powerline-git"

# Install ZSH
pacman -S --noconfirm zsh

# Install ZSH pure prompt.
git clone https://github.com/sindresorhus/pure ~/.dotfiles/pure
sudo mkdir -p $HOME/.zfunctions
sudo ln -s ~/.dotfiles/pure/pure.zsh $HOME/.zfunctions/prompt_pure_setup
sudo ln -s ~/.dotfiles/pure/async.zsh $HOME/.zfunctions/async

# Install ZSH Plugins
mkdir -p ~/.zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions

# Install Tmux
sudo pacman -S --noconfirm tmux

# Install Git
sudo pacman -S --noconfirm git hub

# Install xclip
sudo pacman -S --noconfirm xclip

# Install Vim and Neovim
sudo pacman -S --noconfirm vim neovim

# Install vim-plug
mkdir -p ~/.config/nvim/autoload
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Erlang/Elixir
sudo pacman -S --noconfirm elixir

# NodeJS/NPM
sudo pacman -S --noconfirm nodejs npm
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

# Cmus
sudo pacman -S --noconfirm cmus

# FireFox
sudo pacman -S --noconfirm firefox

# Ack
sudo pacman -S --noconfirm ack

# Install diff-so-fancy
npm install -g diff-so-fancy


