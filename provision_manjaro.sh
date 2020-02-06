#!/usr/bin/env bash

# TODO: This script is very much WIP as I transition to Manjaro

function pacman_install() {
    packages="$@"
    echo sudo pacman -Sy $packages
}

pacman_install \
    base-devel \
    discord
    docker \
    firefox \
    htop \
    i3status \
    jdk-openjdk \
    keepassxc \
    mlocate \
    mpd \
    ncmpcpp \
    py3status \
    python-pip \
    rofi \
    rxvt-unicode \
    steam \
    sway \
    swaybg \
    swayidle \
    swaylock \
    tmux
    ttf-font-awesome \
    waybar \
    wl-clipboard \
    xclip \
