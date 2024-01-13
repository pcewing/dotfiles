#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

SCRIPT_PATH="$( realpath "$0" )"
SCRIPT_DIR="$( dirname "$SCRIPT_PATH" )"

print_header() {
    local header="$1"

    echo -e "\\n"
    echo "$header"
    echo "========================================"
}

apt_update() {
    echo "(Apt) Updating package lists... "
    try sudo apt-get -y update
}

apt_dist_upgrade() {
    echo "(Apt) Upgrading packages... "
    try sudo apt-get -y dist-upgrade
}

apt_install() {
    local packages="$@"

    echo "(Apt) Installing $packages... "
    try sudo apt-get -y install $packages
}

pip_install() {
    local packages="$@"

    echo "(Pip) Installing $packages... "
    try python3 -m pip install $packages
}

function get_latest_github_release() {
    local org="$1"
    local repo="$2"

    local api_url="https://api.github.com/repos/$org/$repo/releases/latest"
    echo "$( curl --silent "$api_url" | jq -r .tag_name )"
}

######################################
# Application Installation Functions #
######################################

configure_xsession() {
    local src_path="$1"
    local dst_path="$2"

    echo "Configuring xsession... "

    [ -f "$src_path" ] || die "File $src_path does not exist!"

    try sudo rm -f "$dst_path"
    try sudo cp "$src_path" "$dst_path"
    try sudo chmod 644 "$dst_path"
}

configure_wayland_session() {
    local src_path="$1"
    local dst_path="$2"

    echo "Configuring wayland session... "

    [ -f "$src_path" ] || die "File $src_path does not exist!"

    try sudo rm -f "$dst_path"
    try sudo cp "$src_path" "$dst_path"
    try sudo chmod 644 "$dst_path"
}

install_apt_packages() {
    local p

    # Core utitilies
    p="apt-utils"
    p+=" ca-certificates"
    p+=" curl"
    p+=" wget"
    p+=" gnupg"
    p+=" jq"
    p+=" software-properties-common"
    p+=" apt-file"
    p+=" libfuse2" # This is required to use AppImage
    p+=" locate"
    p+=" fzf"
    p+=" net-tools"

    # Basic command line utitilies
    p+=" make"
    p+=" build-essential"
    p+=" cmake"
    p+=" meson"
    p+=" htop"
    p+=" iotop"
    p+=" git"
    p+=" vim"
    #p+=" exuberant-ctags"
    p+=" universal-ctags" # I think this has better c++11 support
    p+=" ranger"
    p+=" tmux"
    p+=" neofetch"
    p+=" id3v2"
    p+=" calcurse"
    p+=" rxvt-unicode"
    p+=" clang"
    p+=" clangd"

    # Python
    p+=" python3 python3-dev python3-pip" # Python 3.x

    # General GUI Applications
    p+=" fonts-font-awesome" # Used for media buttons on polybar
    p+=" rofi"               # Fuzzy application launcher
    p+=" dunst"              # Desktop notifications
    p+=" feh"                # Set wallpaper
    p+=" sxiv"               # Image viewer
    p+=" nitrogen"           # Set wallpaper
    p+=" pavucontrol"        # Pulse Audio frontend
    p+=" compton"            # Window compositor
    p+=" scrot"              # Screen capture
    p+=" gucharmap"          # Useful for debugging font issues
    p+=" keepassxc"          # Credential manager
    p+=" remmina"            # RDP session manager
    p+=" usb-creator-gtk"    # Easily flash bootable USBs
    p+=" i3lock"             # Lock screen
    p+=" meld"               # Diff tool
    p+=" xclip"              # Clipboard for X11
    p+=" wl-clipboard"       # Clipboard for Wayland
    p+=" xdotool"            # X11 automation tool
    p+=" kitty"              # Kitty terminal emulator
    p+=" kitty-terminfo"     # Kitty TERMINFO
    p+=" webp"               # Command line support for webp image files

    # Media
    p+=" inkscape" # Vector graphics editor
    p+=" mpv"      # Minimal media player
    p+=" vlc"      # General purpose FOSS media player
    p+=" easytag"  # Edit ID3 Tags on MP3 files
    p+=" blueman"  # Bluetooth device support

    # Gaming
    p+=" steam"
    p+=" steam-devices"

    apt_install "$p"
}

install_neovim() {
    print_header "Installing neovim"

    local nvim_path="/usr/local/bin/nvim"
    if [ -f "$nvim_path" ]; then
        echo "$nvim_path already exists, skipping installation..."
        return
    fi

    try sudo mkdir -p /opt/neovim
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    try sudo chmod u+x nvim.appimage
    try sudo mv nvim.appimage /opt/neovim/nvim
    try sudo ln -s /opt/neovim/nvim $nvim_path

    echo "Installing pynvim python modules..."
    try sudo pip3 install --upgrade pynvim

    echo "Updating alternatives to use nvim..."
    try sudo update-alternatives --install /usr/bin/vi vi "$nvim_path" 60
    try sudo update-alternatives --set vi "$nvim_path"
    try sudo update-alternatives --install /usr/bin/vim vim "$nvim_path" 60
    try sudo update-alternatives --set vim "$nvim_path"
    try sudo update-alternatives --install /usr/bin/editor editor "$nvim_path" 60
    try sudo update-alternatives --set editor "$nvim_path"
}

install_cava() {
    local cache_dir="$1"

    local version="$(get_latest_github_release "karlstav" "cava")"

    print_header "Installing cava ($version)"

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

    local version="$(get_latest_github_release "airblader" "i3")"

    print_header "Installing i3-gaps ($version)"

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
    try mkdir -p build
    try cd build
    try meson ..
    try ninja

    echo "Installing i3-gaps $version..."
    try sudo meson install

    apt_install "i3status"
    pip_install "py3status"

    try cd "$pwd"
}

# TODO: youtube-dl was discontinued. Update this to install yt-dlp instead:
# https://www.linuxadictos.com/en/yt-dlp-fork-sucesor-del-descontinuado-youtube-dl-que-permite-descargar-videos-de-decenas-de-plataformas.html
install_youtube-dl() {
    local cache_dir="$1"
    local bin_dir="$2"

    local version="$(get_latest_github_release "ytdl-org" "youtube-dl")"

    print_header "Installing youtube-dl ($version)"

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

install_kitty() {
    local tmp_dir version tar_file cwd kitty_path

    cwd="$(pwd)"

    version="$(get_latest_github_release "kovidgoyal" "kitty")"

    if [ -z "$version" ]; then
        die "Failed to determine latest kitty release"
    fi

    tmp_dir="$HOME/Downloads/kitty/$version"
    try mkdir -p "$tmp_dir"
    try cd "$tmp_dir"

    # Make sure to strip the 'v' from the version out of the file name
    tar_file="kitty-${version/v/}-x86_64.txz"
    try wget "https://github.com/kovidgoyal/kitty/releases/download/$version/$tar_file"

    try tar -xJf "$tar_file"
    try rm "$tar_file"

    try sudo mkdir -p "/opt/kitty"
    try sudo rm -rf "/opt/kitty/$version"
    try sudo mv "$tmp_dir" "/opt/kitty/$version"

    try sudo rm "/usr/local/bin/kitty"
    try sudo ln -s "/opt/kitty/$version/bin/kitty" "/usr/local/bin/kitty"
    try sudo rm "/usr/local/bin/kitten"
    try sudo ln -s "/opt/kitty/$version/bin/kitten" "/usr/local/bin/kitten"

    kitty_path="$(command -v kitty)"

    echo "Setting the default terminal emulator to $default_terminal"
    try sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$kitty_path" 50
    try sudo update-alternatives --set x-terminal-emulator "$kitty_path"

    try cd "$cwd"
}

install_wpr() {
    local cache_dir="$1"
    local bin_dir="$2"

    local version="0.1.0"

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

    # TODO: This doesn't seem to be working? Or maybe it's because I updated
    # Ubuntu and my pip packages disappeared? But this was missing and breaking
    # my i3 status bar.
    pip_install "python-mpd2"
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

install_flavours() {
    local tmp_dir version tar_file cwd

    cwd="$(pwd)"

    version="$(get_latest_github_release "Misterio77" "flavours")"

    if [ -z "$version" ]; then
        die "Failed to determine latest flavours release"
    fi

    tmp_dir="$HOME/Downloads/flavours/$version"
    try mkdir -p "$tmp_dir"
    try cd "$tmp_dir"

    tar_file="flavours-${version}-x86_64-linux.tar.gz"
    try wget "https://github.com/Misterio77/flavours/releases/download/$version/$tar_file"

    try tar -xzf "$tar_file"
    try rm "$tar_file"

    try sudo mkdir -p "/opt/flavours"
    try sudo rm -rf "/opt/flavours/$version"
    try sudo mv "$tmp_dir" "/opt/flavours/$version"
    try sudo rm -f "/usr/local/bin/flavours"
    try sudo ln -s "/opt/flavours/$version/flavours" "/usr/local/bin/flavours"

    flavours update all &>/dev/null

    try cd "$cwd"
}

########
# Main #
########

[[ -z "$DOTFILES" ]] && DOTFILES="$( realpath "$SCRIPT_DIR/.." )"

source "$DOTFILES/config/bash/functions.sh"

# For applications that are built from source, we will put them here
cache_dir="$HOME/.dotcache" && mkdir -p "$cache_dir"
bin_dir="$HOME/bin" && mkdir -p "$bin_dir"

# Make sure apt is ready to use
apt_update
apt_dist_upgrade

# Install everything via apt that is available in the default repositories
install_apt_packages

# Set up a simple xsession desktop file that display managers will recognize.
# This will execute /etc/X11/Xsession which in turn executes the .xsession in
# the user's home directory.
configure_xsession \
    "$DOTFILES/config/xsession.desktop" \
    "/usr/share/xsessions/xsession.desktop"

# Set up a wayland session for sway that the display manager will recognize
configure_wayland_session \
    "$DOTFILES/config/sway-user.desktop" \
    "/usr/share/wayland-sessions/sway-user.desktop"

# Install everything else that needs special attention
install_kitty
install_neovim
install_i3gaps      "$cache_dir"
#install_cava        "$cache_dir"
install_youtube-dl  "$cache_dir" "$bin_dir"
install_wpr         "$cache_dir" "$bin_dir"
install_mpd
install_ncmpcpp
install_flavours

# TODO: Install picom from source
