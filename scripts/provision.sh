#!/usr/bin/env bash

distro=$1
remote=$2

antigen_version=1.2.1

source $DOTFILES/scripts/provision/$distro.sh

section(){
  echo -en '\n'
  echo "$1"
  echo "==============================================================="
}

section "Installing the basics"
install_basics

section "Installing Python 2 and 3"
install_python

section "Installing ZSH with Antigen"
install_shell

section "Installing Neovim with Vim-Plug"
install_neovim

section "Installing NodeJS"
install_nodejs

section "Installing Global NPM Packages"
install_npm_packages

section "Installing Elixir"
install_elixir

section "Installing .NET Core"
install_dotnet

if [[ $remote != true ]]; then
  section "Installing Terminal Emulator"
  install_terminal_emulator

  section "Installing Graphical Environment"
  install_graphical_environment

  section "Installing Fonts"
  install_fonts
fi
