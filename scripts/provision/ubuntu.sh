#!/usr/bin/env bash

source "$DOTFILES/scripts/provision/ubuntu/utils.sh"

install_basics()
{
    section "Installing the basics"
    apt_install git
    apt_install vim
    apt_install wget
    apt_install curl
    apt_install make
    apt_install xclip
    apt_install build-essential
    apt_install tmux
    apt_install ranger
    apt_install inotify-tools
}

install_python()
{
    section "Installing Python 2 and 3"
    apt_install python-dev
    apt_install python-pip
    apt_install python3-dev
    apt_install python3-pip
}

install_shell()
{
    section "Installing ZSH with Antigen"
    apt_install zsh

    echo "Creating the $HOME/.zsh directory if it doesn't exist...  "
    try mkdir -p "$HOME/.zsh"


    antigen_version=1.2.1
    echo "Downloading antigen version ${antigen_version}..."
    try eval $(curl https://cdn.rawgit.com/zsh-users/antigen/v${antigen_version}/bin/antigen.zsh > "$HOME/.zsh/antigen.zsh")
}

install_neovim()
{
    section "Installing Neovim with Vim-Plug"
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
    try mkdir -p "$HOME/.config/nvim/autoload"
    echo "Downloading vim-plug from https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim...  "
    try curl -fLo "$HOME/.config/nvim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

install_terminal_emulator()
{
    section "Installing Terminal Emulator"
    apt_install rxvt-unicode
    apt_install rxvt-unicode-256color
}

install_graphical_environment()
{
    section "Installing Graphical Environment"

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

    # This pulls up an installer TUI that halts the script
    #apt_install wicd
    apt_install ubuntu-drivers-common
    apt_install mesa-utils
    apt_install mesa-utils-extra
    apt_install compton
    apt_install xorg
    #apt_install xserver-xorg

    apt_add_repo aguignard/ppa
    apt_update
    apt_install libxcb-xrm-dev

    mkdir -p ~/src

    # clone the repository
    dir=$(pwd)
    i3dir="$HOME/src/i3-gaps"
    [ ! -e "$i3dir" ] || rm -rf "$i3dir"
    git clone https://www.github.com/Airblader/i3 "$i3dir"
    cd "$i3dir"

    # compile & install
    try autoreconf --force --install
    rm -rf build/
    mkdir -p build && cd build/

    # Disabling sanitizers is important for release versions!
    # The prefix and sysconfdir are, obviously, dependent on the distribution.
    try ../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
    try make
    try sudo make install

    cd "$dir"

    # Install py3status (Alternative to i3status)
    apt_install i3status
    echo "Installing py3status"
    try sudo pip install py3status
}

install_gui_tools()
{
    # This technically isn't a GUI tool but I only use it in graphical environments
    apt_install cmus

    # This is used for taking screenshots instead of gnome-screenshot; it is
    # mapped to hotkeys in the i3config
    apt_install scrot

    # Other graphical applications
    apt_install rofi
    apt_install feh
    apt_install arandr
    apt_install chromium-browser
    apt_install shotwell

    apt_install nautilus
    gsettings set org.gnome.desktop.background show-desktop-icons false
}

install_wpr() {
    # TODO: We should just put wpr in the $DOTFILES/tools/ directory

    # Install wallpaper rotator
    wprdir=$HOME/go/src/github.com/pcewing/wpr
    if [[ ! -e $wprdir ]]; then
        echo "Downloading wallpaper rotator repo"
        try git clone https://github.com/pcewing/wpr "$wprdir"
    fi

    echo "Installing the wallpaper rotator app"
    try /usr/local/go/bin/go install github.com/pcewing/wpr
}

install_all()
{
    apt_update
    install_basics
    install_python
    install_shell
    install_neovim

    if [[ $1 != true ]]; then
        install_terminal_emulator
        install_graphical_environment
        install_wpr
    fi
}
