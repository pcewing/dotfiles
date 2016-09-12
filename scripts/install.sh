#!/usr/bin/env bash

echo "Installing dotfiles"

source ~/.dotfiles/scripts/link.sh

if [[ "$(uname)" == "Linux" ]]; then
    # This will set OS/Architecture/Version variables.
    # https://unix.stackexchange.com/questions/6345/how-can-i-get-distrobution-name-and-version-number-in-a-simple-shell-script
    . /etc/lsb-release
    if [ "$DISTRIB_ID" == "Ubuntu" ]; then
        echo "Running on Ubuntu"

        source ~/.dotfiles/scripts/ubuntu.sh
    fi
fi

echo "Creating vim directories"
mkdir -p ~/.vim-tmp

echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Configuring urxvt as default terminal emulator"
sudo update-alternatives --config x-terminal-emulator

echo "Done; reboot to ensure all changes take effect."
