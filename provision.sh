#!/usr/bin/env bash

# This script will install everything that I expect in an Ubuntu 18.04
# environment 

# Save this off so we can return later
initial_dir="$(pwd)"

# For applications that need to be built from source, we will put them here
temp_src_dir="$HOME/src/temp"
mkdir -p "$temp_src_dir"

#############################
# General Utility Functions #
#############################
try()
{
    "$@" > ~/.command_log 2>&1
    local ret_val=$?
  
    if [ ! $ret_val -eq 0 ]; then
        echo "FAILURE"
        echo "Command: $*"
        echo "Output:"
        cat ~/.command_log
        exit 1
    fi
}

print_header() {
    local header="$1"

    echo -e "\n"
    echo "$header"
    echo "========================================"

}

apt_update() {
    echo "Updating package lists... "
    try sudo apt-get -y update
}

apt_install() {
    echo "Installing $1... "
    try sudo apt-get -y install "$1"
}

apt_add_repo() {
    echo "Adding $1 repository... "
    try sudo add-apt-repository -y "$1"
}

######################################
# Application Installation Functions #
######################################

function install_cava() {
    print_header "Installing cava"

    # Install dependencies
    apt_install libfftw3-dev
    apt_install libasound2-dev
    apt_install libncursesw5-dev
    apt_install libpulse-dev
    apt_install libtool

    local cava_src_dir="$temp_src_dir/cava"

    echo "Removing pre-existing source directory if necessary"
    try rm -rf "$cava_src_dir"

    echo "Cloning the polybar repository"
    try git clone https://github.com/karlstav/cava "$cava_src_dir"

    echo "Building and installing cava"
    cd "$cava_src_dir"
    try ./autogen.sh
    try ./configure
    try make
    try sudo make install
}

function install_polybar() {
    print_header "Installing polybar"

    # Required dependencies
    apt_install cmake 
    apt_install cmake-data 
    apt_install pkg-config
    apt_install libcairo2-dev	
    apt_install libxcb1-dev 
    apt_install libxcb-util0-dev 
    apt_install libxcb-randr0-dev 
    apt_install libxcb-composite0-dev	
    apt_install python-xcbgen 
    apt_install xcb-proto	
    apt_install libxcb-image0-dev	
    apt_install libxcb-ewmh-dev 
    apt_install libxcb-icccm4-dev	

    # Optional dependencies
    apt_install libxcb-xkb-dev	
    apt_install libxcb-xrm-dev	
    apt_install libxcb-cursor-dev	
    apt_install libasound2-dev	
    apt_install libpulse-dev
    # This installs vanilla i3wm which we will overwrite with i3-gaps
    apt_install i3-wm
    apt_install libjsoncpp-dev	
    apt_install libmpdclient-dev	
    apt_install libcurl4-openssl-dev 
    apt_install libiw-dev	
    apt_install libnl-3-dev	

    # This is necessary to use Font Awesome icons
    apt_install fonts-font-awesome	

    local polybar_src_dir="$temp_src_dir/polybar"
    local polybar_build_dir="$temp_src_dir/polybar/build"

    echo "Removing pre-existing source directory if necessary"
    try rm -rf "$polybar_src_dir"

    echo "Cloning the polybar repository"
    try git clone --branch 3.2 --recursive https://github.com/jaagr/polybar \
        "$polybar_src_dir"

    echo "Building and installing polybar"
    try mkdir -p "$polybar_build_dir"
    try cd "$polybar_build_dir"
    try cmake ..
    try sudo make install
}

function install_i3gaps() {
    print_header "Installing i3-gaps"

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
    apt_install libxcb-xrm0
    apt_install libxcb-xrm-dev
    apt_install automake

    local i3gaps_src_dir="$temp_src_dir/i3-gaps"

    echo "Removing pre-existing source directory if necessary"
    try rm -rf "$i3gaps_src_dir"

    echo "Cloning the i3-gaps repository"
    try git clone https://www.github.com/Airblader/i3 "$i3gaps_src_dir"
    
    # Disabling sanitizers (See below) is important for release versions!
    # The prefix and sysconfdir are, obviously, dependent on the distribution.

    echo "Building and installing i3-gaps"
    try cd "$i3gaps_src_dir"
    try autoreconf --force --install
    try rm -rf build/
    try mkdir -p build && cd build/
    try ../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
    try make
    try sudo make install
}

function install_youtube-dl() {
    print_header "Installing youtube-dl"

    local bin_dir="$HOME/bin"
    local youtube_dl="$bin_dir/youtube-dl"

    mkdir -p "$bin_dir"

    echo "Downloading youtube-dl"
    try curl -L https://yt-dl.org/downloads/latest/youtube-dl -o "$youtube_dl"

    echo "Setting up youtube-dl"
    try chmod a+rx "$youtube_dl"
}

function install_dotnet() {
    print_header "Installing .NET Core SDK"

    echo "Setting up Microsoft key and feed"
    wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb

    echo "Installing .NET Core SDK"
    sudo apt-get install apt-transport-https
    sudo apt-get update
    sudo apt-get install dotnet-sdk-2.1
}

########
# Main #
########

install_cava
install_polybar
install_i3gaps
install_youtube-dl
install_dotnet

apt_install id3v2
