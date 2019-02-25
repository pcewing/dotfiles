#!/usr/bin/env bash

#############################
# General Utility Functions #
#############################
die() { echo "$1" 1>&2; exit 1; }

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

    echo -e "\\n"
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

configure_default_xsession() {
    local src_path="$1"

    echo "Configuring default xsession... "

    [ -f "$src_path" ] || die "File $src_path does not exist!"

    local dst_path="/usr/share/xsessions/default.desktop"

    if [ -f "$dst_path" ]; then
        echo "Skipping configuration becease $dst_path already exists..."
    else
        try sudo ln -s "$src_path" "$dst_path"
    fi
}

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

prepare_apt() {
    local codename="$1"

    configure_apt_repositories "$codename"
    apt_update
    apt_dist_upgrade
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
    p="$p i3lock"             # Lock screen

    # Media
    p="$p mpv"
    p="$p vlc"

    # Gaming
    p="$p steam"
    p="$p steam-devices"

    apt_install "$p"

}

install_neovim() {
    local cache_dir="$1"
    local version="$2"

    print_header "Installing neovim"

    local neovim_dir="$cache_dir/neovim/$version"
    local neovim_exe="$neovim_dir/build/bin/nvim"
    if [ -f "$neovim_exe" ]; then
        echo "$neovim_exe already exists, skipping installation..."
        return
    fi

    echo "Installing pre-requisites..."
    apt_install "gcc cmake ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip"

    echo "Cloning the neovim repository..."
    try mkdir -p "$(dirname -- "$neovim_dir")"
    try git clone "https://github.com/neovim/neovim" "$neovim_dir"

    local pwd; pwd="$(pwd)"
    try cd "$neovim_dir"

    echo "Checking out version $version..."
    try git checkout "$version"

    echo "Building neovim $version..."
    try make

    echo "Installing neovim $version..."
    try sudo make install

    try cd "$pwd"

    echo "Installing pynvim python modules..."
    try sudo pip2 install --upgrade pynvim
    try sudo pip3 install --upgrade pynvim

    echo "Updating alternatives to use nvim..."
    nvim_path="$(command -v nvim)"
    try sudo update-alternatives --install /usr/bin/vi vi "$nvim_path" 60
    try sudo update-alternatives --set vi "$nvim_path"
    try sudo update-alternatives --install /usr/bin/vim vim "$nvim_path" 60
    try sudo update-alternatives --set vim "$nvim_path"
    try sudo update-alternatives --install /usr/bin/editor editor "$nvim_path" 60
    try sudo update-alternatives --set editor "$nvim_path"
}

install_cava() {
    local cache_dir="$1"
    local version="$2"

    print_header "Installing cava"

    local cava_dir="$cache_dir/cava/$version"
    local cava_exe="$cava_dir/cava"
    if [ -f "$cava_exe" ]; then
        echo "$cava_exe already exists, skipping installation..."
        return
    fi

    echo "Installing pre-requisites..."
    apt_install "libfftw3-dev libasound2-dev libncursesw5-dev libpulse-dev libtool"

    echo "Cloning the cava repository"
    try mkdir -p "$(dirname -- "$cava_dir")"
    try git clone "https://github.com/karlstav/cava" "$cava_dir"

    local pwd; pwd="$(pwd)"
    try cd "$cava_dir"

    echo "Building cava $version..."
    try ./autogen.sh
    try ./configure
    try make

    echo "Installing cava $version..."
    try sudo make install

    try cd "$pwd"
}

install_i3gaps() {
    local cache_dir="$1"
    local version="$2"

    print_header "Installing i3-gaps"

    local i3gaps_dir="$cache_dir/i3gaps/$version"
    local i3gaps_exe="$i3gaps_dir/build/i3"
    if [ -f "$i3gaps_exe" ]; then
        echo "$i3gaps_exe already exists, skipping installation..."
        return
    fi

    echo "Installing pre-requisites..."
    apt_install "libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev autoconf libxcb-xrm0 libxcb-xrm-dev libxcb-shape0 libxcb-shape0-dev automake"

    echo "Cloning the i3-gaps repository"
    try mkdir -p "$(dirname -- "$i3gaps_dir")"
    try git clone "https://www.github.com/Airblader/i3" "$i3gaps_dir"

    local pwd; pwd="$(pwd)"
    try cd "$i3gaps_dir"

    echo "Checkout out version $version..."
    try git checkout "$version"
    
    echo "Building i3-gaps $version..."
    try autoreconf --force --install
    try rm -rf "./build/"
    try mkdir -p "./build"
    try cd "./build"
    try ../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
    try make

    echo "Installing i3-gaps $version..."
    try sudo make install

    try cd "$pwd"
}

install_polybar() {
    local cache_dir="$1"
    local version="$2"

    print_header "Installing polybar"

    local polybar_dir="$cache_dir/polybar/$version"
    local polybar_exe="$polybar_dir/build/bin/polybar"
    if [ -f "$polybar_exe" ]; then
        echo "$polybar_exe already exists, skipping installation..."
        return
    fi

    echo "Installing pre-requisites..."
    apt_install "cmake cmake-data pkg-config libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev"

    echo "Installing optional pre-requisites..."
    apt_install "libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libiw-dev libnl-3-dev"

    echo "Cloning the polybar repository"
    try mkdir -p "$(dirname -- "$polybar_dir")"
    try git clone --recursive https://github.com/jaagr/polybar "$polybar_dir"

    local pwd; pwd="$(pwd)"
    try cd "$polybar_dir"

    echo "Checkout out version $version..."
    try git checkout "$version"
    
    echo "Building polybar $version..."
    try mkdir -p "$polybar_dir/build"
    try cd "$polybar_dir/build"
    try cmake ..

    echo "Installing polybar $version..."
    try sudo make install

    try cd "$pwd"
}

install_youtube-dl() {
    local cache_dir="$1"
    local version="$2"
    local bin_dir="$3"

    print_header "Installing youtube-dl..."

    local ytdl_dir="$cache_dir/youtube-dl/$version"
    local ytdl_exe="$ytdl_dir/youtube-dl"
    if [ -f "$ytdl_exe" ]; then
        echo "$ytdl_exe already exists, skipping installation..."
        return
    fi

    echo "Downloading youtube-dl $version..."
    mkdir -p "$ytdl_dir"
    try curl -L "https://yt-dl.org/downloads/$version/youtube-dl" -o "$ytdl_exe"

    echo "Installing youtube-dl $version..."
    try chmod a+rx "$ytdl_exe"
    try rm -f "$bin_dir/youtube-dl"
    try ln -s "$ytdl_exe" "$bin_dir/youtube-dl"
}

install_urxvt() {
    print_header "Installing rxvt-unicode"

    if [ "$(command -v urxvt)" = "" ]; then
        apt_install rxvt-unicode
    else
        echo "Skipping installation because urxvt is already installed..."
    fi

    echo "Setting urxvt as the default terminal emulator..."
    try sudo update-alternatives --set x-terminal-emulator "$(command -v urxvt)"
}

install_wpr() {
    local cache_dir="$1"
    local version="$2"
    local bin_dir="$3"

    print_header "Installing wpr..."

    local wpr_dir="$cache_dir/wpr/$version"
    local wpr_exe="$wpr_dir/wpr"
    if [ -f "$wpr_exe" ]; then
        echo "$wpr_exe already exists, skipping installation..."
        return
    fi

    echo "Downloading wpr $version..."
    mkdir -p "$wpr_dir"
    local tarball_name="wpr.$version.linux-amd64.tar.gz"
    local s3_url="https://s3-us-west-2.amazonaws.com"
    local url="$s3_url/pcewing-wpr/releases/$version/$tarball_name"
    try curl -L "$url" -o "$wpr_dir/$tarball_name"

    echo "Installing wpr $version..."
    try tar --directory "$wpr_dir" -xvf "$wpr_dir/$tarball_name"
    try chmod a+rx "$wpr_exe"
    try rm -f "$bin_dir/wpr"
    try ln -s "$wpr_exe" "$bin_dir/wpr"
}

install_mpd() {
    print_header "Installing mpd"

    if [ ! -z "$(command -v mpd)" ]; then
        echo "mpd is already installed, skipping installation..."
        return
    fi

    apt_install "mpd"

    echo "Disabling the mpd service..."
    try sudo systemctl stop mpd.service
    try sudo systemctl stop mpd.socket
    try sudo systemctl disable mpd.service
    try sudo systemctl disable mpd.socket

    echo "Configuring mpd..."
    mkdir -p "$HOME/.mpd"
    mkdir -p "$HOME/.mpd/playlists"
    mkdir -p "$HOME/.local/share/mpd"
}

install_ncmpcpp() {
    print_header "Installing ncmpcpp"

    if [ ! -z "$(command -v ncmpcpp)" ]; then
        echo "ncmpcpp is already installed, skipping installation..."
        return
    fi

    apt_install "ncmpcpp"

    echo "Configuring ncmpcpp..."
    mkdir -p "$HOME/.config/ncmpcpp"
}

install_irssi() {
    local secrets_dir="$1"
    local pass="$2"

    print_header "Installing irssi"

    if [ ! -z "$(command -v irssi)" ]; then
        echo "irssi is already installed, skipping installation..."
        return
    fi

    apt_install "irssi"

    local config_dir="$HOME/.irssi"
    local tls_cert_path="$config_dir/irssi.pem"

    echo "Configuring irssi..."
    mkdir -p "$config_dir"
    try decrypt_with_pass "$secrets_dir/irssi.pem.gpg" "$tls_cert_path" "$pass"
}

install_bcompare4() {
    local cache_dir="$1"
    local version="$2"
    local secrets_dir="$3"
    local pass="$4"

    print_header "Installing Beyond Compare"

    local deb_name="bcompare-${version}_amd64.deb"
    local deb_path="$cache_dir/bcompare/$version/$deb_name"

    if [ -f "$deb_path" ]; then
        echo "$deb_path already exists, skipping installation..."
        return
    fi

    echo "Installing pre-requisites..."
    apt_install gdebi-core

    echo "Downloading Beyond Compare $version..."
    try mkdir -p "$(dirname -- "$deb_path")"
    try curl -L "https://www.scootersoftware.com/$deb_name" -o "$deb_path"

    echo "Installing Beyond Compare $version..."
    try sudo gdebi --non-interactive "$deb_path"

    echo "Installing license key..."
    local key_path="$HOME/.config/bcompare/BC4Key.txt"
    try mkdir -p "$(dirname -- "$key_path")"
    try decrypt_with_pass "$secrets_dir/BC4Key.txt.gpg" "$key_path" "$pass"
}

install_insync() {
    local codename="$1"
    local secrets_dir="$2"
    local pass="$3"

    print_header "Installing Insync"

    if [ ! "$(command -v insync)" = "" ]; then
        echo "Insync is already installed, skipping installation..."
        return
    fi

    echo "Adding the insync apt repository key..."
    try sudo apt-key adv \
        --keyserver keyserver.ubuntu.com \
        --recv-keys ACCAF35C

    echo "Adding the insync apt repository..."
    local insync_apt_source_list="/etc/apt/sources.list.d/insync.list"
    sudo_file_write \
        "$insync_apt_source_list" \
        "deb http://apt.insynchq.com/ubuntu $codename non-free contrib"

    apt_update

    apt_install insync

    echo "I'd rather avoid leaving this source list around..."
    try sudo rm -rf "$insync_apt_source_list"

    echo "Adding Google account..."
    local auth_code_path="$HOME/insync_auth_code.txt"
    try decrypt_with_pass "$secrets_dir/insync_auth_code.txt.gpg" \
        "$auth_code_path" "$pass"
    try insync add_account --auth-code "$(cat "$HOME/insync_auth_code.txt")" \
        --path "$HOME/box" --no-download
    rm -f "$auth_code_path"
}

########
# Main #
########

[[ "$DOTFILES" = "" ]] && DOTFILES="$HOME/.dotfiles"

source "$DOTFILES/config/bash/functions.sh"

distro_name="Ubuntu"
distro_version="18.10"
distro_codename="cosmic"

# For applications that are built from source, we will put them here
cache_dir="$HOME/.cache" && mkdir -p "$cache_dir"

bin_dir="$HOME/bin" && mkdir -p "$bin_dir"
secrets_dir="$DOTFILES/secrets"

# Print a warning if the current distro doesn't match what is expected
verify_distribution "$distro_name" "$distro_version" "$distro_codename"

# Make sure apt is ready to use
prepare_apt "$distro_codename"

# Install everything via apt that is available in the default repositories
install_apt_packages

# This adds a desktop entry that GDM3 will recognize
configure_default_xsession "$DOTFILES/config/default.desktop"

# We will need a passphrase to decrypt secrets that some apps depend on
echo -n "Enter secret passphrase: " && read -r -s pass && echo

# Install everything else that needs special attention
install_urxvt
install_neovim     "$cache_dir" "v0.3.4"
install_i3gaps     "$cache_dir" "4.16.1"
install_polybar    "$cache_dir" "3.3.0"
install_cava       "$cache_dir" "0.6.1"
install_youtube-dl "$cache_dir" "2019.02.18" "$bin_dir"
install_wpr        "$cache_dir" "0.1.0"      "$bin_dir"
install_mpd
install_ncmpcpp
install_irssi      "$secrets_dir" "$pass"

# Proprietary software
install_bcompare4 "$cache_dir" "4.2.9.23626" "$secrets_dir" "$pass"
install_insync "$distro_codename" "$secrets_dir" "$pass"
