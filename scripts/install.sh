#!/usr/bin/env bash

DOTFILE_DIR="$HOME/.dotfiles"

print_section_header(){
  echo -en '\n'
  echo "$1"
  echo "==============================================================="
}

print_section_header "Installing dotfiles"

source $DOTFILE_DIR/scripts/link.sh

case "$1" in
  arch)
    source $DOTFILE_DIR/scripts/arch.sh
    ;;
  ubuntu)
    source $DOTFILE_DIR/scripts/ubuntu.sh
    ;;
  *)
    echo "Usage: ./install.sh {arch|ubuntu}"
    ;;
esac

echo "Configuring zsh as default shell"
chsh -s $(which zsh)

echo "Configuring urxvt as default terminal emulator"
sudo update-alternatives --config x-terminal-emulator

echo "Done; reboot to ensure all changes take effect."
