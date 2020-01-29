#!/usr/bin/env bash

# TODO: This script is very much WIP as I transition to Manjaro

function pacman_install() {
    packages="$@"
    echo sudo pacman -Sy $packages
}

pacman_install \
    docker \
    xclip \
    wl-clipboard \
    sway \
    swaybg \
    swayidle \
    swaylock \
    waybar \
    rxvt-unicode \
    firefox \
    rofi \
    steam \
    keepassxc \
    jdk-openjdk \
    py3status \
    i3status \
    ttf-font-awesome \
    python-pip \
    mpd \
    ncmpcpp \
    discord

