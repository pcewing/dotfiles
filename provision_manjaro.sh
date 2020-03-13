#!/usr/bin/env bash

# TODO: This script is very much WIP as I transition to Manjaro

function pacman_install() {
    packages="$@"
    echo sudo pacman -Sy $packages
}

pacman_install \
    base-devel \
    ctags \
    discord
    docker \
    firefox \
    flatpak \
    htop \
    i3status \
    inkscape \
    jdk-openjdk \
    keepassxc \
    kicad \
    mako \
    mlocate \
    mpd \
    mpv \
    ncmpcpp \
    poppler \
    py3status \
    python-pip \
    rofi \
    rxvt-unicode \
    steam \
    sway \
    swaybg \
    swayidle \
    swaylock \
    tmux \
    transmission-gtk \
    ttf-font-awesome \
    waybar \
    wl-clipboard \
    xclip

pamac build nordvpn-bin
pamac build bcompare

# https://github.com/flathub/com.slack.Slack/issues/34
flatpak install com.slack.Slack
