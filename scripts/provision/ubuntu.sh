#!/bin/bash

DOTFILES=$HOME/.dotfiles
remote=$1
antigen_version=1.2.1
golang_version=1.9
dotnet_version=2.0.0

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

apt_update(){ echo "Updating package lists... "; try sudo apt-get -y update; }
apt_upgrade(){ echo "Upgrading packages... "; try sudo apt-get -y upgrade; }
apt_install(){ echo "Installing $1... "; try sudo apt-get -y install $1; }
apt_add_repo(){ echo "Adding $1 repository... "; try sudo add-apt-repository -y ppa:$1; }

install_basics()
{
  apt_update
  apt_install git
  apt_install vim
  apt_install wget
  apt_install curl
  apt_install make
  apt_install xclip
  apt_install ack-grep
  apt_install build-essential
  apt_install tmux
  apt_install inotify-tools
}

install_python()
{
  apt_install python-dev
  apt_install python-pip
  apt_install python3-dev
  apt_install python3-pip
}

install_shell()
{
  apt_install zsh

  echo "Creating the $HOME/.zsh directory if it doesn't exist...  "
  try mkdir -p $HOME/.zsh
  echo "Downloading antigen version ${antigen_version}..."
  try eval $(curl https://cdn.rawgit.com/zsh-users/antigen/v${antigen_version}/bin/antigen.zsh > $HOME/.zsh/antigen.zsh)
}

install_golang()
{
  echo "Downloading golang v$golang_version tarball"
  try wget "https://storage.googleapis.com/golang/go$golang_version.linux-amd64.tar.gz"

  echo "Extracting the golang tarball"
  try sudo tar -C /usr/local -xzf go$golang_version.linux-amd64.tar.gz

  echo "Removing golang tarball"
  try rm go$golang_version.linux-amd64.tar.gz

  echo "Setting up golang directory structure"
  try mkdir -p $HOME/go/bin
  try mkdir -p $HOME/go/pkg
  try mkdir -p $HOME/go/src/github.com/pcewing
}

install_neovim()
{
  apt_add_repo neovim-ppa/unstable
  apt_update
  apt_install neovim

  echo "Setting up neovim python support..."
  try pip install --upgrade neovim
  echo "Setting up neovim python2 support..."
  try pip2 install --upgrade neovim
  echo "Setting up neovim python3 support..."
  try pip3 install --upgrade neovim

  echo "Creating the $HOME/.config/nvim/autoload directory if it doesn't exist...  "
  try mkdir -p $HOME/.config/nvim/autoload
  echo "Downloading vim-plug from https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim...  "
  try curl -fLo $HOME/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  echo "Installing Neovim plugins"
  try nvim +PlugInstall +qa
}

install_nodejs()
{
  echo "Adding NodeJS repository... "
  try sudo bash -c "curl --silent --location https://deb.nodesource.com/setup_6.x | bash -"
  apt_install nodejs
  echo "Creating the $HOME/.npm-global directory if it doesn't exist...  "
  try mkdir -p $HOME/.npm-global
  echo "Setting npm global directory to $HOME/.npm-global to avoid permissions issues when globally installing packages...  "
  try npm config set prefix "$HOME/.npm-global"
}

install_npm_packages()
{
  echo "Installing diff-so-fancy... "
  try npm install -g diff-so-fancy
}

install_elixir()
{
  echo "Downloading the Erlang/Elixir package"
  try wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
  echo "Installing the Erlang/Elixir package"
  try sudo dpkg -i erlang-solutions_1.0_all.deb
  apt_update
  apt_install esl-erlang
  apt_install elixir
  echo "Removing the Erlang/Elixir package"
  rm erlang-solutions_1.0_all.deb
}

install_dotnet()
{
  echo "Downloading the Microsoft GPG key"
  try sudo sh -c 'curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg'
  echo "Registering the Microsoft GPG key"
  try sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
  echo "Registering the package source"
  try sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod xenial main" > /etc/apt/sources.list.d/dotnetdev.list'

  apt_update
  apt_install dotnet-sdk-$dotnet_version
}

if [[ $remote != true ]]; then
  install_terminal_emulator()
  {
    apt_install rxvt-unicode
    apt_install rxvt-unicode-256color
  }

  install_graphical_environment()
  {
    # This is used for taking screenshots instead of gnome-screenshot; it is
    # mapped to hotkeys in the i3config
    apt_install scrot

    # This will install the following:
    # https://github.com/Airblader/i3
    apt_install libxcb1-dev
    apt_install libxcb-keysyms1-dev
    apt_install libpango1.0-dev
    apt_install libxcb-util0-dev
    apt_install libxcb-icccm4-dev
    apt_install libyajl-dev
    apt_install libstartup-notification0-dev
    apt_install libxcb-randr0-dev
    apt_install libev-dev
    apt_install libxcb-cursor-dev
    apt_install libxcb-xinerama0-dev
    apt_install libxcb-xkb-dev
    apt_install libxkbcommon-dev
    apt_install libxkbcommon-x11-dev
    apt_install autoconf

    apt_add_repo aguignard/ppa
    apt_update
    apt_install libxcb-xrm-dev

    mkdir -p ~/src

    # clone the repository
    i3dir=~/src/i3-gaps
    [ ! -e $i3dir ] || rm -rf $i3dir
    git clone https://www.github.com/Airblader/i3 $i3dir
    cd $i3dir

    # compile & install
    try autoreconf --force --install
    rm -rf build/
    mkdir -p build && cd build/

    # Disabling sanitizers is important for release versions!
    # The prefix and sysconfdir are, obviously, dependent on the distribution.
    try ../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
    try make
    try sudo make install

    # Install py3status (Alternative to i3status)
    apt_install i3status
    echo "Installing py3status"
    try sudo pip install py3status

    # Install wallpaper rotator
    wprdir=$HOME/go/src/github.com/pcewing/wpr
    if [[ ! -e $wprdir ]]; then
      echo "Downloading wallpaper rotator repo"
      try git clone https://github.com/pcewing/wpr $wprdir
    fi

    echo "Installing the wallpaper rotator app"
    try go install github.com/pcewing/wpr

    # TODO: I should probably split these apps into their own function
    apt_install cmus
  }

  install_dropbox()
  {
    echo "Adding dropbox to apt sources list"
    try sudo sh -c 'echo "deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu wily main" > /etc/apt/sources.list'

    echo "Adding .NET core gpg key... "
    try sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E

    apt_update
    apt_install dropbox
  }

  install_fonts()
  {
    echo "Cloning powerline/fonts to ~/powerline_fonts... "
    try git clone https://github.com/powerline/fonts ~/powerline_fonts
    echo "Executing ~/powerline_fonts/install.sh..."
    try ~/powerline_fonts/install.sh
    echo "Cleaning up ~/powerline_fonts directory... "
    try rm -rf ~/powerline_fonts
  }
fi
