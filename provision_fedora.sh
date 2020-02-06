#!/usr/bin/env bash

git clone https://github.com/pcewing/dotfiles ~/dot
cd dot
./link.sh 

# Add rpm fusion repositories
sudo dnf install \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install rpm packages
sudo dnf install -y \
    sway \
    swaybg \
    swayidle \
    swaylock \
    py3status \
    rofi \
    ncmpcpp \
    mpd \
    neovim

# Install python packages
pip install --user \
    python-mpd2

