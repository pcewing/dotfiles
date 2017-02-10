#!/usr/bin/env bash

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

install(){ echo "Installing $1... "; try sudo pacman -S --noconfirm $1; }

section(){
  echo -en '\n'
  echo "$1"
  echo "==============================================================="
}

# Update and install basic tools
section "Installing the Basics"
install linux-headers
install base-devel
install net-tools
install pkgfile
install git
install wget
install curl
install make
install xclip
install ack
install tmux
install inotify-tools
install python2
install python2-pip
install python
install python-pip

section "Installing zsh with antigen"
install zsh

echo "Creating the $HOME/.zsh directory if it doesn't exist...  "
try mkdir -p $HOME/.zsh
echo "Downloading antigen version ${antigen_version}..."
try eval $(curl https://cdn.rawgit.com/zsh-users/antigen/v${antigen_version}/bin/antigen.zsh > $HOME/.zsh/antigen.zsh)

section "Installing neovim"
install neovim
echo "Setting up neovim python support..."
try sudo pip install --upgrade neovim
try sudo pip2 install --upgrade neovim
try sudo pip3 install --upgrade neovim

section "Installing Vim-Plug"
echo "Creating the $HOME/.config/nvim/autoload directory if it doesn't exist...  "
try mkdir -p $HOME/.config/nvim/autoload
echo "Downloading vim-plug from https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim...  "
try curl -fLo $HOME/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

if [[ $remote != true ]]; then
  section "Installing graphical components"
  install xorg-server
  install xorg-server-utils
  install xorg-apps
  install xorg-xinit
  install rxvt-unicode
  install i3

  section "Installing Powerline Derivative Fonts"
  fonts_dir=/usr/share/fonts
  powerline_dir=$fonts_dir/powerline
  if [[ ! -d $powerline_dir ]]; then
    echo "Cloning powerline fonts to $powerline_dir... "
    try sudo git clone https://github.com/powerline/fonts $powerline_dir
  fi
  echo "Executing $powerline_dir/install.sh..."
  try sudo $powerline_dir/install.sh
fi

section "Installing NodeJS"
install nodejs
install npm
echo "Creating the $HOME/.npm-global directory if it doesn't exist...  "
try mkdir -p $HOME/.npm-global
echo "Setting npm global directory to $HOME/.npm-global to avoid permissions issues when globally installing packages...  "
try npm config set prefix "$HOME/.npm-global"

section "Installing Global NPM Packages"
echo "Installing diff-so-fancy... "
try npm install -g diff-so-fancy
