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

install_basics()
{
  update
  install git
  install vim
  install wget
  install curl
  install make
  install xclip
  install ack-grep
  install build-essential
  install tmux
  install inotify-tools
}

install_python()
{
  install python-dev
  install python-pip
  install python3-dev
  install python3-pip
}

install_shell()
{
  install zsh

  echo "Creating the $HOME/.zsh directory if it doesn't exist...  "
  try mkdir -p $HOME/.zsh
  echo "Downloading antigen version ${antigen_version}..."
  try eval $(curl https://cdn.rawgit.com/zsh-users/antigen/v${antigen_version}/bin/antigen.zsh > $HOME/.zsh/antigen.zsh)
}

install_neovim()
{
  add-apt-repository neovim-ppa/unstable
  update
  install neovim

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
}

install_nodejs()
{
  echo "Adding NodeJS repository... "
  try sudo bash -c "curl --silent --location https://deb.nodesource.com/setup_6.x | bash -"
  install nodejs
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
  update
  install esl-erlang
  install elixir
  echo "Removing the Erlang/Elixir package"
  rm erlang-solutions_1.0_all.deb
}

install_dotnet()
{
  echo "Adding .NET core to package lists... "
  try sudo sh -c 'echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet-release/ xenial main" > /etc/apt/sources.list.d/dotnetdev.list'
  echo "Adding .NET core gpg key... "
  try sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 417A0893
  update
  install dotnet-dev-1.0.0-preview2.1-003177
}

if [[ $remote != true ]]; then
  install_terminal_emulator()
  {
    install rxvt-unicode
    install rxvt-unicode-256color
  }

  install_graphical_environment()
  {
    # This is used for taking screenshots instead of gnome-screenshot; it is
    # mapped to hotkeys in the i3config
    install scrot

    # This will install the following:
    # https://github.com/Airblader/i3
    install libxcb1-dev
    install libxcb-keysyms1-dev
    install libpango1.0-dev
    install libxcb-util0-dev
    install libxcb-icccm4-dev
    install libyajl-dev
    install libstartup-notification0-dev
    install libxcb-randr0-dev
    install libev-dev
    install libxcb-cursor-dev
    install libxcb-xinerama0-dev
    install libxcb-xkb-dev
    install libxkbcommon-dev
    install libxkbcommon-x11-dev
    install autoconf

    add-apt-repository aguignard/ppa
    update
    install libxcb-xrm-dev

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
    try sudo pip install py3status
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
