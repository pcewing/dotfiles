#!/usr/bin/env bash

if [[ "$DOTFILES" = "" ]]; then echo "Please ensure the DOTFILES environment variable is set"; exit 1; fi
source "$DOTFILES/scripts/provision/ubuntu/17.10/utils.sh"

print_header "Installing the basics"
apt_install git
apt_install vim
apt_install wget
apt_install curl
apt_install make
apt_install xclip
apt_install build-essential
apt_install tmux
apt_install ranger
apt_install inotify-tools

print_header "Installing Python (2 & 3)"

apt_install python-dev
apt_install python-pip
apt_install python3-dev
apt_install python3-pip

print_header "Installing ZSH with Antigen"
apt_install zsh

print_header "Installing Terminal Emulator"
apt_install rxvt-unicode
apt_install rxvt-unicode-256color

print_header "Installing Graphical Environment"
apt_install compton
apt_install i3

print_header "Installing GUI tools"
apt_install cmus
apt_install scrot
apt_install rofi
apt_install feh
apt_install arandr
apt_install chromium-browser
apt_install shotwell

apt_install nautilus
echo "Updating Gnome settings to fix an issue with Nautilus and i3 "
try gsettings set org.gnome.desktop.background show-desktop-icons false

