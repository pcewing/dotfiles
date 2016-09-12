#!/usr/bin/env bash

echo -e "\nInstalling dotfiles"
echo "=============================="

source ~/.dotfiles/scripts/link.sh
source ~/.dotfiles/scripts/arch.sh

echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Configuring urxvt as default terminal emulator"
sudo update-alternatives --config x-terminal-emulator

echo "Done; reboot to ensure all changes take effect."
