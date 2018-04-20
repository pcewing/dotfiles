#!/usr/bin/env bash

if [[ "$DOTFILES" = "" ]]; then echo "Please ensure the DOTFILES environment variable is set"; exit 1; fi
source "$DOTFILES/scripts/provision/ubuntu/17.10/utils.sh"

print_header "Installing Neovim with Vim-Plug"
apt_add_repo neovim-ppa/unstable
apt_update
apt_install neovim

apt_install exuberant-ctags

echo "Setting up neovim python support..."
try pip install --upgrade neovim
echo "Setting up neovim python2 support..."
try pip2 install --upgrade neovim
echo "Setting up neovim python3 support..."
try pip3 install --upgrade neovim

echo "Creating the $HOME/.config/nvim/autoload directory if it doesn't exist...  "
try mkdir -p "$HOME/.config/nvim/autoload"

echo "Downloading vim-plug from https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim...  "
try curl -fLo "$HOME/.config/nvim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

