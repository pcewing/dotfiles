#!/bin/bash

DOTFILES=$HOME/.dotfiles
remote=$1
antigen_version=1.2.1

try()
{
  "$@" > ~/.command_log 2>&1
  local ret_val=$?

  if [ $ret_val -eq 0 ]; then
    echo "SUCCESS"
  else
    echo "FAILURE"
    echo "Command: $@"
    echo "Output:"
    cat ~/.command_log
    exit 1
  fi
}

update(){ echo "Updating package lists... "; try sudo apt-get -y update; }
upgrade(){ echo "Upgrading packages... "; try sudo apt-get -y upgrade; }
install(){ echo "Installing $1... "; try sudo apt-get -y install $1; }
add-apt-repository(){ echo "Adding $1 repository... "; try sudo add-apt-repository -y ppa:$1; }

section(){
  echo -en '\n'
  echo "$1"
  echo "==============================================================="
}

# Update and install basic tools
section "Installing the Basics"
update
install git
install wget
install curl
install make
install xclip
install ack-grep
install build-essential
install tmux
install zsh
install inotify-tools
add-apt-repository neovim-ppa/unstable
update
install neovim
install python-dev
install python-pip
install python3-dev
install python3-pip

if [[ $remote != true ]]; then
  install rxvt-unicode
  install rxvt-unicode-256color
  install i3

  section "Installing Powerline Derivative Fonts"
  echo "Cloning powerline/fonts to ~/powerline_fonts... "
  try git clone https://github.com/powerline/fonts ~/powerline_fonts
  echo "Executing ~/powerline_fonts/install.sh..."
  try ~/powerline_fonts/install.sh
  echo "Cleaning up ~/powerline_fonts directory... "
  try rm -rf ~/powerline_fonts
fi

section "Installing Antigen"
echo "Creating the $HOME/.zsh directory if it doesn't exist...  "
try mkdir -p $HOME/.zsh
echo "Downloading antigen version ${antigen_version}..."
try curl https://cdn.rawgit.com/zsh-users/antigen/v${antigen_version}/bin/antigen.zsh > $HOME/.zsh/antigen.zsh

section "Installing Vim-Plug"
echo "Creating the $HOME/.config/nvim/autoload directory if it doesn't exist...  "
try mkdir -p $HOME/.config/nvim/autoload
echo "Downloading vim-plug from https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim...  "
try curl -fLo $HOME/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

section "Installing NodeJS"
echo "Adding NodeJS repository... "
try sudo bash -c "curl --silent --location https://deb.nodesource.com/setup_6.x | bash -"
install nodejs
echo "Creating the $HOME/.npm-global directory if it doesn't exist...  "
try mkdir -p $HOME/.npm-global
echo "Setting npm global directory to $HOME/.npm-global to avoid permissions issues when globally installing packages...  "
try npm config set prefix "$HOME/.npm-global"

section "Installing Global NPM Packages"
echo "Installing diff-so-fancy... "
try npm install -g diff-so-fancy
