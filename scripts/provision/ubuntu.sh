#!/bin/bash

DOTFILES="$HOME/.dotfiles"
remote=$1

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
fi

#TODO: We shouldn't exit if this fails.
section "Installing Pure Prompt for ZSH"
echo "Cloning sindresorhus/pure to $DOTFILES/pure... "
try git clone https://github.com/sindresorhus/pure $DOTFILES/pure
echo "Creating the $HOME/.zfunctions directory if it doesn't exist...  "
try sudo mkdir -p $HOME/.zfunctions
echo "Linking $HOME/.zfunctions/prompt_pure_setup to $DOTFILES/pure/pure.zsh...  "
try sudo ln -s $DOTFILES/pure/pure.zsh $HOME/.zfunctions/prompt_pure_setup
echo "Linking $HOME/.zfunctions/async to $DOTFILES/pure/async.zsh...  "
try sudo ln -s $DOTFILES/pure/async.zsh $HOME/.zfunctions/async

section "Installing ZSH Plugins"
echo "Creating the $HOME/.zsh directory if it doesn't exist...  "
try mkdir -p $HOME/.zsh
echo "Cloning zsh-users/zsh-syntax-highlighting to $HOME/.zsh/zsh-syntax-highlighting... "
try git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.zsh/zsh-syntax-highlighting
echo "Cloning zsh-users/zsh-autosuggestions to $HOME/.zsh/zsh-autosuggestions... "
try git clone https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.zsh/zsh-autosuggestions

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
try npm config set prefix '$HOME/.npm-global'

section "Installing Global NPM Packages"
echo "Installing diff-so-fancy... "
try npm install -g diff-so-fancy

section "Installing Erlang & Elixir"
echo "Downloading Erlang Solutions Package"
try sudo wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
echo "Installing the Erlang Solutions Package"
try sudo dpkg -i erlang-solutions_1.0_all.deb
update
install esl-erlang
install elixir

section "Installing PostgreSQL"
echo "Adding PostgreSQL Repository to Sources"
try sudo bash -c "echo \"deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main\" > /etc/apt/sources.list.d/pgdg.list"
echo "Adding PostgreSQL key"
try sudo bash -c "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -"
update
upgrade
install postgresql-9.6

# Configure PostgreSQL
echo "Setting up necessary postgres role"
try sudo -u postgres psql --command="ALTER USER $DB_USER PASSWORD '$DB_PASS';"

