#!/usr/bin/env bash

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

sudo_file_write() {
    local file="$1"
    local content="$2"

    try sudo sh -c "echo \"$content\" > \"$file\""
}

sudo_file_append() {
    local file="$1"
    local content="$2"

    try sudo sh -c "echo \"$content\" >> \"$file\""
}

apt_update() {
    echo "Updating package lists... "
    try sudo apt-get -y update
}

apt_dist_upgrade() {
    echo "Upgrading packages... "
    try sudo apt-get -y dist-upgrade
}

apt_install() {
    local packages="$@"

    echo "Installing $packages... "
    try sudo apt-get -y install $packages
}

apt_add_repo() {
    echo "Adding $1 repository... "
    try sudo add-apt-repository -y "$1"
}

verify_distribution() {
    source "/etc/lsb-release"

    local expected_id="$1"
    local expected_release="$2"
    local expected_codename="$3"

    local mismatch="0"

    [[ ! "$DISTRIB_ID" = "$expected_id" ]]                   && mismatch="1"
    [[ ! "$DISTRIB_RELEASE" = "$expected_release" ]]         && mismatch="1"
    [[ ! "$DISTRIB_CODENAME" = "$expected_codename" ]]       && mismatch="1"

    if [[ "$mismatch" = "1" ]]; then
        echo "WARNING: Current Linux distribution doesn't match expectations"
        echo "Expected = $expected_id $expected_release ($expected_codename)"
        echo "Actual = $DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_CODENAME)"
    fi
}

######################################
# Application Installation Functions #
######################################

configure_apt_repositories() {
    local dist="$1"

    local archive_url="http://us.archive.ubuntu.com/ubuntu/"
    local security_url="http://security.ubuntu.com/ubuntu"
    local sources_dir="/etc/apt/sources.list.d"

    echo "Configuring default apt repositories... "
    sudo_file_write "/etc/apt/sources.list" ""
    try sudo rm -rf "$sources_dir"
    try sudo mkdir -p "$sources_dir"

    sudo_file_write \
        "$sources_dir/ubuntu-main.list" \
        "deb $archive_url $dist main restricted"
    sudo_file_write \
        "$sources_dir/ubuntu-main.list" \
        "deb $archive_url $dist main restricted"
    sudo_file_write \
        "$sources_dir/ubuntu-main-updates.list" \
        "deb $archive_url $dist-updates main restricted"
    sudo_file_write \
        "$sources_dir/ubuntu-universe.list" \
        "deb $archive_url $dist universe"
    sudo_file_write \
        "$sources_dir/ubuntu-universe-updates.list" \
        "deb $archive_url $dist-updates universe"
    sudo_file_write \
        "$sources_dir/ubuntu-multiverse.list" \
        "deb $archive_url $dist multiverse"
    sudo_file_write \
        "$sources_dir/ubuntu-multiverse-updates.list" \
        "deb $archive_url $dist-updates multiverse"
    sudo_file_write \
        "$sources_dir/ubuntu-backports.list" \
        "deb $archive_url $dist-backports main restricted universe multiverse"
    sudo_file_write \
        "$sources_dir/ubuntu-security-main.list" \
        "deb $security_url $dist-security main restricted"
    sudo_file_write \
        "$sources_dir/ubuntu-security-universe.list" \
        "deb $security_url $dist-security universe"
    sudo_file_write \
        "$sources_dir/ubuntu-security-multiverse.list" \
        "deb $security_url $dist-security multiverse"
}

install_apt_packages() {

    # Core utitilies
    local p="apt-utils"
    p="$p ca-certificates"
    p="$p curl"
    p="$p wget"
    p="$p gnupg"
    p="$p software-properties-common"

    # Basic command line utitilies
    p="$p make"
    p="$p build-essential"
    p="$p cmake"
    p="$p htop"
    p="$p iotop"
    p="$p git"
    p="$p vim"
    p="$p exuberant-ctags"
    p="$p ranger"
    p="$p tmux"
    p="$p neofetch"
    p="$p id3v2"

    # Python
    p="$p python python-dev python-pip"    # Python 2.7
    p="$p python3 python3-dev python3-pip" # Python 3.x

    # General GUI Applications
    p="$p fonts-font-awesome" # Used for media buttons on polybar
    p="$p rofi"               # Fuzzy application launcher
    p="$p dunst"              # Desktop notifications
    p="$p feh"                # Set wallpaper
    p="$p sxiv"               # Image viewer
    p="$p nitrogen"           # Set wallpaper
    p="$p pavucontrol"        # Pulse Audio frontend
    p="$p compton"            # Window compositor
    p="$p scrot"              # Screen capture
    p="$p gucharmap"          # Useful for debugging font issues
    p="$p keepassxc"          # Credential manager
    p="$p remmina"            # RDP session manager
    p="$p usb-creator-gtk"    # Easily flash bootable USBs
    p="$p chromium-browser"   # Chrome

    # Media
    p="$p mpv"
    p="$p vlc"

    # Gaming
    p="$p steam"
    p="$p steam-devices"

    apt_install "$p"

}

install_neovim() {
    print_header "Installing neovim"

    # Necessary to use add-apt-repository
    apt_install software-properties-common

    apt_add_repo ppa:neovim-ppa/stable
    apt_update
    apt_install neovim

    # Install python modules
    echo "Installing python modules..."
    try sudo pip2 install --upgrade neovim
    try sudo pip3 install --upgrade neovim

    echo "Updating alternatives to use nvim..."
    nvim_path="$(which nvim)"
    try sudo update-alternatives --install /usr/bin/vi vi "$nvim_path" 60
    try sudo update-alternatives --set vi "$nvim_path"
    try sudo update-alternatives --install /usr/bin/vim vim "$nvim_path" 60
    try sudo update-alternatives --set vim "$nvim_path"
    try sudo update-alternatives --install /usr/bin/editor editor "$nvim_path" 60
    try sudo update-alternatives --set editor "$nvim_path"

    echo "Downloading plug.vim..."
    try curl -fLo "~/.vim/autoload/plug.vim" --create-dirs \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    try mkdir -p "~/.local/share/nvim/site/autoload"
    try cp "~/.vim/autoload/plug.vim" "~/.local/share/nvim/site/autoload/plug.vim"
}

install_cava() {
    print_header "Installing cava"

    # Install dependencies
    apt_install libfftw3-dev
    apt_install libasound2-dev
    apt_install libncursesw5-dev
    apt_install libpulse-dev
    apt_install libtool

    local cava_src_dir="$cache_dir/cava"

    echo "Removing pre-existing source directory if necessary"
    try rm -rf "$cava_src_dir"

    echo "Cloning the cava repository"
    try git clone https://github.com/karlstav/cava "$cava_src_dir"

    echo "Building and installing cava"
    cd "$cava_src_dir"
    try ./autogen.sh
    try ./configure
    try make
    try sudo make install
}

install_i3gaps() {
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
    apt_install libxcb-shape0
    apt_install libxcb-shape0-dev
    apt_install automake

    local i3gaps_src_dir="$cache_dir/i3-gaps"

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

install_polybar() {
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
    # This is necessary if not installing i3-gaps from source
    #apt_install i3-wm
    apt_install libjsoncpp-dev	
    apt_install libmpdclient-dev	
    apt_install libcurl4-openssl-dev 
    apt_install libiw-dev	
    apt_install libnl-3-dev	

    # This is necessary to use Font Awesome icons
    apt_install fonts-font-awesome	

    local polybar_src_dir="$cache_dir/polybar"
    local polybar_build_dir="$cache_dir/polybar/build"

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

install_youtube-dl() {
    print_header "Installing youtube-dl"

    local bin_dir="$HOME/bin"
    local youtube_dl="$bin_dir/youtube-dl"

    mkdir -p "$bin_dir"

    echo "Downloading youtube-dl"
    try curl -L https://yt-dl.org/downloads/latest/youtube-dl -o "$youtube_dl"

    echo "Setting up youtube-dl"
    try chmod a+rx "$youtube_dl"
}

install_urxvt() {
    print_header "Installing rxvt-unicode"

    apt_install rxvt-unicode
    sudo update-alternatives --set x-terminal-emulator "$(which urxvt)"
}

########
# Main #
########

[[ "$DOTFILES" = "" ]] && DOTFILES="$HOME/.dotfiles"

# Save this off so we can return later
initial_dir="$(pwd)"

# For applications that are built from source, we will put them here
cache_dir="$HOME/.cache" && mkdir -p "$cache_dir"

# Print a warning if the current distro doesn't match what is expected
verify_distribution "Ubuntu" "18.04" "bionic"

# Make sure apt is ready to use
configure_apt_repositories "bionic"
apt_update

# Upgrade existing packages
apt_dist_upgrade

# Install everything via apt that is available in the default repositories
install_apt_packages

# Install everything else that needs special attention
[[ "$(which nvim)" = "" ]]          && install_neovim
[[ "$(which i3)" = "" ]]            && install_i3gaps
[[ "$(which polybar)" = "" ]]       && install_polybar
[[ "$(which cava)" = "" ]]          && install_cava
[[ "$(which youtube-dl)" = "" ]]    && install_youtube-dl
[[ "$(which urxvt)" = "" ]]         && install_urxvt

# TODO: Implement these
#[[ "$(which bcompare)" = "" ]]      && install_bcompare4
#[[ "$(which insync)" = "" ]]        && install_insync
#[[ "$(which mpd)" = "" ]]           && install_mpd
#[[ "$(which ncmpcpp)" = "" ]]       && install_ncmpcpp
#[[ "$(which wpr)" = "" ]]           && install_wpr

