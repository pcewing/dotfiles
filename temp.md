Ok, I created new files for the various hosts and features I expect to need at
first. I didn't go back and remove things from the `core.nix` file yet. Can you
make that change? I've included all relevant files below for context.

Context Files:

File `./provision/ubuntu_22.04.sh`:
```
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
    p+=" unzip"
    p+=" uchardet" # Useful for detecting text file encoding

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

    echo "Disabling the system mpd service..."
    try sudo systemctl stop --now mpd.service
    try sudo systemctl stop --now mpd.socket
    try sudo systemctl disable mpd.service
    try sudo systemctl disable mpd.socket
    try sudo systemctl mask mpd.service
    try sudo systemctl mask mpd.socket

    echo "Disabling the user mpd service..."
    try systemctl stop --now --user mpd.service
    try systemctl stop --now --user mpd.socket
    try systemctl disable --user mpd.service
    try systemctl disable --user mpd.socket
    try systemctl mask --user mpd.service
    try systemctl mask --user mpd.socket

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
```

File `./bootstrap.sh`:
```
#!/usr/bin/env bash
set -euo pipefail

#################################
# tiny helpers (like your script)
#################################
yell() { >&2 echo "$*"; }
die()  { yell "ERROR: $*"; exit 1; }
try()  { "$@" || die "Command failed: $*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

is_wsl() {
  # Simple heuristic; good enough for now
  grep -qi microsoft /proc/version 2>/dev/null
}

#################################
# config knobs (safe defaults)
#################################
DOTFILES_DIR_DEFAULT="$HOME/dot"

usage() {
  cat <<EOF
Usage: $0 [--dir PATH] [--nix-host NAME] [--no-upgrade]

  --dir        Where to clone it (default: $DOTFILES_DIR_DEFAULT)
  --nix-host   Home Manager target to apply
  --no-upgrade Skip apt-get dist-upgrade (default is to run it)

Examples:
  $0 --nix-host personal-desktop
EOF
}

DOTFILES_DIR="$DOTFILES_DIR_DEFAULT"
NIX_HOST=""
DO_UPGRADE=1

nix_hosts() {
    ls "$DOTFILES_DIR/nix/home/hosts" | sed 's/\.nix$//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)          DOTFILES_DIR="$2"; shift 2;;
    --nix-host)     NIX_HOST="$2"; shift 2;;
    --no-upgrade)   DO_UPGRADE=0; shift;;
    -h|--help)      usage; exit 0;;
    *) die "Unknown argument: $1";;
  esac
done

source_localrc() {
    local localrc_path="$HOME/.localrc"

    if [ -f "$localrc_path" ]; then
        echo "[bootstrap] (source_localrc) Sourcing localrc from path $localrc_path"
        source "$HOME/.localrc"
    else
        echo "[bootstrap] (source_localrc) Localrc path '$localrc_path' doesn't exist; skipping."
    fi
}

validate_nix_host() {
    if [ -z "$NIX_HOST" ]; then
        yell "[bootstrap] (validate_nix_host) Error: NIX_HOST is not set."
        yell "Either specify the --nix-host argument or export this variable in your ~/.localrc file. Available hosts:"
        yell "$(nix_hosts)"
        exit 1
    fi

    if [ ! -e "$DOTFILES_DIR/nix/home/hosts/$NIX_HOST.nix" ]; then
        die "NIX_HOST '$NIX_HOST' is not valid. Available hosts: $(nix_hosts)"
    fi
}

#################################
# apt bootstrap (minimal)
#################################
apt_bootstrap() {
  echo "[bootstrap] Installing minimal prerequisites via apt..."

  # You can expand this later, but keep it small.
  local pkgs=(
    ca-certificates
    curl
    git
    xz-utils
  )

  try sudo apt-get update -y
  if [[ "$DO_UPGRADE" -eq 1 ]]; then
    # In a VM this is fine; on real machines you may prefer to disable.
    try sudo apt-get dist-upgrade -y
  fi
  try sudo apt-get install -y "${pkgs[@]}"
}

#################################
# nix install / init
#################################
install_nix_if_needed() {
  if need_cmd nix; then
    echo "[bootstrap] nix already installed."
    return 0
  fi

  echo "[bootstrap] Installing Nix (single-user)..."
  # Standard installer; we'll tighten this up later if you prefer a different method.
  try sh -c 'curl -L https://nixos.org/nix/install | sh -s -- --no-daemon'
}

source_nix_profile() {
  # Make nix available in the current shell, even right after install.
  if need_cmd nix; then
    return 0
  fi

  # Common install locations for single-user Nix.
  if [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.nix-profile/etc/profile.d/nix.sh"
  elif [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
    # multi-user install (if you ever switch later)
    # shellcheck disable=SC1091
    source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  fi

  need_cmd nix || die "nix still not on PATH after sourcing profile."
}

enable_nix_experimental() {
  # Home Manager via flakes is the nicest iteration experience.
  # This just ensures nix can use flakes/commands on fresh installs.
  mkdir -p "$HOME/.config/nix"
  local conf="$HOME/.config/nix/nix.conf"

  if [[ ! -f "$conf" ]] || ! grep -q "experimental-features" "$conf"; then
    echo "[bootstrap] Enabling nix-command + flakes in $conf"
    {
      echo "experimental-features = nix-command flakes"
    } >> "$conf"
  fi
}

#################################
# apply home-manager
#################################
apply_home_manager() {
  echo "[bootstrap] Applying Home Manager target: $NIX_HOST"

  # Assumes your repo will contain a flake with:
  # homeConfigurations.<nixHost>
  #
  # We'll create that flake next.
  try nix --extra-experimental-features "nix-command flakes" \
    run "github:nix-community/home-manager" -- \
    switch -b hm-bak --flake "$DOTFILES_DIR/nix#$NIX_HOST"
}

# Setting the default terminal and editor via `update-alternatives` is a
# system-wide action so we need to do that here after we've applied the Nix
# configuration
set_default_terminal_and_editor() {
  echo "[bootstrap] Setting system defaults via update-alternatives..."

  # Ensure nix is on PATH in this script:
  source_nix_profile

  local kitty_path nvim_path
  kitty_path="$(command -v kitty || true)"
  nvim_path="$(command -v nvim || true)"

  if [[ -n "$kitty_path" ]]; then
    try sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$kitty_path" 50
    try sudo update-alternatives --set x-terminal-emulator "$kitty_path"
  else
    yell "[bootstrap] kitty not found on PATH; skipping terminal alternative"
  fi

  if [[ -n "$nvim_path" ]]; then
    try sudo update-alternatives --install /usr/bin/vi vi "$nvim_path" 60
    try sudo update-alternatives --set vi "$nvim_path"
    try sudo update-alternatives --install /usr/bin/vim vim "$nvim_path" 60
    try sudo update-alternatives --set vim "$nvim_path"
    try sudo update-alternatives --install /usr/bin/editor editor "$nvim_path" 60
    try sudo update-alternatives --set editor "$nvim_path"
  else
    yell "[bootstrap] nvim not found on PATH; skipping editor alternatives"
  fi
}

install_session_desktop_files() {
  echo "[bootstrap] Installing session desktop files..."

  local dot="$DOTFILES_DIR"
  local xs_src="$dot/config/xsession.desktop"
  local xs_dst="/usr/share/xsessions/xsession.desktop"

  local sway_src="$dot/config/sway-user.desktop"
  local sway_dst="/usr/share/wayland-sessions/sway-user.desktop"

  if [[ -f "$xs_src" ]]; then
    try sudo install -m 0644 "$xs_src" "$xs_dst"
  else
    yell "[bootstrap] Missing $xs_src; skipping xsession.desktop"
  fi

  if [[ -f "$sway_src" ]]; then
    try sudo install -m 0644 "$sway_src" "$sway_dst"
  else
    yell "[bootstrap] Missing $sway_src; skipping sway-user.desktop"
  fi
}

#################################
# main
#################################
main() {
  echo "[bootstrap] Starting on: $(lsb_release -ds 2>/dev/null || uname -a)"
  if is_wsl; then
    echo "[bootstrap] Detected WSL environment."
  fi

  source_localrc
  validate_nix_host
  apt_bootstrap
  install_nix_if_needed
  source_nix_profile
  enable_nix_experimental
  apply_home_manager
  set_default_terminal_and_editor
  install_session_desktop_files

  echo "[bootstrap] Done."
  echo "Tip: if something goes sideways, Home Manager supports rollback."
}

main "$@"
```

File `./nix/home/features/wsl.nix`:
```
{ pkgs, ... }:
{
  # TODO
  # Example WSL tweaks; add real ones as you need them.
  home.sessionVariables = {
    BROWSER = "wslview";
  };

  # Often you *don’t* want X11/Wayland stuff here.
}
```

File `./nix/home/features/desktop.nix`:
```
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rofi
    dunst
    feh
    picom
    scrot
    meld
    xclip
    wl-clipboard
    xdotool
    kitty
    # etc.
  ];
}
```

File `./nix/home/features/dotfiles-links.nix`:
```
{ config, lib, ... }:

let
  dotConfigDir = ../../../config;

  link = { dst, srcPath }:
    if lib.hasPrefix ".config/" dst then
      { xdg = true; key = lib.removePrefix ".config/" dst; value = { source = srcPath; }; }
    else
      { xdg = false; key = dst; value = { source = srcPath; }; };

  mk = dstRel: srcRel:
    link { dst = dstRel; srcPath = dotConfigDir + "/${srcRel}"; };

  items = [
    (mk ".Xresources"                      "Xresources")
    (mk ".bash_profile"                    "bash_profile")
    (mk ".bashrc"                          "bashrc")
    (mk ".config/dunst/dunstrc"            "dunstrc")
    (mk ".env"                             "env")
    (mk ".gitconfig"                       "gitconfig")
    (mk ".gvimrc"                          "gvimrc")
    (mk ".config/i3/config"                "i3")
    (mk ".inputrc"                         "inputrc")
    (mk ".config/mpd/mpd.conf"             "mpd")
    (mk ".config/ncmpcpp/bindings"         "ncmpcpp/bindings")
    (mk ".config/ncmpcpp/config"           "ncmpcpp/config")
    (mk ".config/picom/picom.conf"         "picom.conf")
    (mk ".profile"                         "profile")
    (mk ".pulse/daemon.conf"               "pulse/daemon.conf")
    (mk ".config/py3status/config"         "py3status.conf")
    (mk ".config/ranger/rc.conf"           "rangerrc")
    (mk ".config/rofi/config.rasi"         "rofi/config.rasi")
    (mk ".config/rofi/base16.rasi"         "rofi/base16.rasi")
    (mk ".config/sway/config"              "sway")
    (mk ".swaysession"                     "swaysession")
    (mk ".tmux.conf"                       "tmux.conf")
    (mk ".vimrc"                           "vimrc")
    (mk ".xinitrc"                         "xinitrc")
    (mk ".xsession"                        "xsession")

    # directories
    (mk ".config/nvim"                     "nvim")
    (mk ".config/flavours"                 "flavours")

    # individual files under ~/.config
    (mk ".config/kitty/kitty.conf"         "kitty.conf")
    (mk ".config/alacritty/alacritty.yml"  "alacritty.yml")
    (mk ".config/alacritty/base16.yml"     "alacritty/base16.yml")
    (mk ".config/alacritty/linux.yml"      "alacritty/linux.yml")
    (mk ".config/wezterm/wezterm.lua"      "wezterm.lua")
  ];

  xdgPairs = builtins.filter (x: x.xdg) items;
  homePairs = builtins.filter (x: !x.xdg) items;

  xdgAttr = lib.listToAttrs (map (x: { name = x.key; value = x.value; }) xdgPairs);
  homeAttr = lib.listToAttrs (map (x: { name = x.key; value = x.value; }) homePairs);
in
{
  xdg.enable = true;

  home.file = homeAttr;
  xdg.configFile = xdgAttr;
}
```

File `./nix/home/features/core.nix`:
```
{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  # TODO: These might collide with my `config/env` or other files
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "kitty";
  };

  imports = [
    ./dotfiles-links.nix
  ];

  # Needed for things like steam (and a few other packages you may want later).
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    #################################
    # Core utilities (your apt list)
    # TODO: COMMENT CLEANUP
    #################################
    # TODO: apt-utils?
    cacert # apt: ca-certificates
    #curl # TODO: Don't think we need this here since the bootstrap script installs it system-wide
    wget
    gnupg
    jq
    # TODO: software-properties-common
    # TODO: apt-file
    # TODO: libfuse
    # TODO: Make sure this works
    # “locate” equivalent (note: the database update is typically system-level)
    plocate
    fzf
    nettools # apt: net-tools
    unzip
    libuchardet # apt: uchardet
    xz

    ###############################
    # Basic command line utilities
    ###############################
    gnumake
    gcc
    cmake
    meson
    htop
    iotop
    universal-ctags
    ranger
    tmux
    neofetch
    id3v2
    calcurse
    rxvt-unicode
    flavours
    #ripgrep
    #fd

    #################
    # C/C++ toolchain
    #################
    # TODO: Installing both this and `gcc` causes an issue because they both
    # provide the same colliding ld.bfd file. For now, just only install
    # clang-tools but not the full compiler toolchain. We can try to figure out
    # how to have both side-by-side later on or maybe just make a different
    # profile for clang
    #clang
    clang-tools

    #########
    # Python
    #########
    # TODO: Let's thoroughly test Python since this is a hairy and important one
    python3
    python3Packages.pip
    python3Packages.pynvim
    #python3Packages.python-mpd2 # TODO: Replace with below?
    python3Packages.mpd2

    ########################
    # Desktop / GUI utilities
    # (we’ll later move these to a desktop profile)
    ########################
    font-awesome
    rofi
    dunst
    feh
    sxiv
    nitrogen
    pavucontrol
    picom
    scrot
    gucharmap
    keepassxc
    remmina
    # TODO: There doesn't appear to be a Nix package for this. We could just
    # install it in the bootstrap script but we only want it on hosts with
    # desktop environments since it's a GTK GUI app. So, figure that out later.
    # Maybe we can just find an alternative app for making bootable USB drives.
    #usb-creator-gtk
    i3lock
    meld
    xclip
    wl-clipboard
    xdotool
    kitty
    #kitty-terminfo TODO: Is this not necessary in Nix?
    libwebp # apt: webp

    ########
    # Media
    ########
    inkscape
    mpv
    vlc
    easytag
    blueman

    #########################
    # Music tooling (old script)
    #########################
    mpd
    ncmpcpp
    cava

    #########################
    # “youtube-dl” replacement
    #########################
    yt-dlp

    #########################
    # i3 / bar tooling (old i3gaps step)
    #
    # Note: "i3-gaps" as a separate project is largely obsolete; the gaps
    # patches were merged into i3 years ago. nixpkgs typically just uses i3.
    #########################
    i3
    i3status

    #########################
    # Gaming (old apt section)
    #########################
    steam
    steam-run
  ];

  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.home-manager.enable = true;
}
```

File `./nix/home/features/gaming.nix`:
```
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    steam
    steam-run
  ];
}
```

File `./nix/home/hosts/work-wsl.nix`:
```
{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  imports = [
    ../features/core.nix
    ../features/wsl.nix
  ];
}
```

File `./nix/home/hosts/work-desktop.nix`:
```
{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  imports = [
    ../features/core.nix
    ../features/desktop.nix
  ];
}
```

File `./nix/home/hosts/personal-desktop.nix`:
```
{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  imports = [
    ../features/core.nix
    ../features/desktop.nix
    ../features/gaming.nix
  ];
}
```

File `./nix/home/hosts/work-server.nix`:
```
{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  imports = [
    ../features/core.nix
    ../features/desktop.nix
  ];
}
```

File `./nix/home/hosts/personal-server.nix`:
```
{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  imports = [
    ../features/core.nix
    ../features/desktop.nix
    ../features/gaming.nix
  ];
}
```

File `./nix/home/hosts/personal-wsl.nix`:
```
{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  imports = [
    ../features/core.nix
    ../features/wsl.nix
  ];
}
```

File `./nix/flake.nix`:
```
{
  description = "Paul's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      homeConfigurations = {
        personal-desktop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/personal-desktop.nix ];
        };

        work-desktop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/work-desktop.nix ];
        };

        personal-wsl = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/personal-wsl.nix ];
        };

        work-wsl = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/work-wsl.nix ];
        };

        personal-server = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/personal-server.nix ];
        };

        work-server = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/work-server.nix ];
        };
      };
    };
}
```
