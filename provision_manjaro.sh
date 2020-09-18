#!/usr/bin/env bash

# TODO: This script is very much WIP as I transition to Manjaro

function pacman_install() {
    package="$1"
    sudo pacman -Syu --noconfirm $package
}

pacman_install base-devel
pacman_install ctags
pacman_install discord
pacman_install docker
pacman_install firefox
pacman_install flatpak
pacman_install htop
pacman_install i3-gaps
pacman_install i3status
pacman_install inkscape
pacman_install jdk-openjdk
pacman_install keepassxc
pacman_install kicad
pacman_install mlocate
pacman_install mpd
pacman_install mpv
pacman_install ncmpcpp
pacman_install poppler
pacman_install py3status
pacman_install python-pip
pacman_install ranger
pacman_install remmina
pacman_install rofi
pacman_install rxvt-unicode
pacman_install steam
pacman_install tmux
pacman_install transmission-gtk
pacman_install ttf-font-awesome
pacman_install xclip
pacman_install scrot
pacman_install feh

# Sway is not quite ready for usage as a daily driver; however, this is the
# command to install it along with peripherals.
#pacman_install \
#    mako \
#    sway \
#    swaybg \
#    swayidle \
#    swaylock \
#    waybar \
#    wl-clipboard \

# Proprietary packages from the AUR
#pamac build nordvpn-bin
#pamac build bcompare

# https://github.com/flathub/com.slack.Slack/issues/34
#flatpak install com.slack.Slack
