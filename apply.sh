#!/usr/bin/env bash

set -euo pipefail

# TODO: Comment cleanup throughout

#################################
# tiny helpers (like your script)
#################################
yell() { >&2 echo "$*"; }
die()  { yell "ERROR: $*"; exit 1; }
try()  { "$@" || die "Command failed: $*"; }

# TODO: This name makes no sense. This returns true if the cmd is installed,
# implying that we would NOT need it. Rename to is_installed or something
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
  --no-apt     Skip all apt-get steps

Examples:
  $0 --nix-host personal-desktop
EOF
}

DOTFILES_DIR="$DOTFILES_DIR_DEFAULT"
NIX_HOST=""
DO_UPGRADE=1
DO_APT=1

# If jq isn't installed, we will run this very early in the script. Keep track
# of whether or not we've done it so we don't waste time doing it again
APT_UPDATE_COMPLETE="0"

# Track if docker was installed during this run so that we can print a reminder
# at the end to either reboot or log out and back in for the group change to
# take effect
DOCKER_INSTALLED="0"

nix_hosts() {
    jq -r '.hosts | keys[]' "$DOTFILES_DIR/nix/hosts.json"
}

host_has_role() {
    local role="$1"
    if [ -z "$NIX_HOST" ] || [ ! -f "$DOTFILES_DIR/nix/hosts.json" ]; then
        return 1
    fi
    jq -e ".hosts[\"$NIX_HOST\"].roles | index(\"$role\")" \
        "$DOTFILES_DIR/nix/hosts.json" >/dev/null 2>&1
}

install_docker() {
    # TODO: Eventually we're going to move this from core to its own role and
    # when we do we'll need to update this condition
    if ! host_has_role "core"; then
        echo "[bootstrap] (install_docker) core role not enabled, skipping docker install"
        return 0
    fi

    if command -v docker >/dev/null 2>&1; then
        echo "[bootstrap] (install_docker) Docker is already installed, skipping docker install"
    fi

    # Add Docker's official GPG key:
    try sudo install -m 0755 -d /etc/apt/keyrings
    try sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    try sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    try sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    # Update apt to pick up the new docker repository and install
    try sudo apt-get update -y
    try sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group so we don't need to use sudo
    sudo groupadd docker >/dev/null 2>&1
    try sudo usermod -aG docker $USER

    DOCKER_INSTALLED="1"
}

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
        yell "See $DOTFILES_DIR/nix/hosts.json for details."
        exit 1
    fi

    if [ ! -f "$DOTFILES_DIR/nix/hosts.json" ]; then
        die "hosts.json not found at $DOTFILES_DIR/nix/hosts.json"
    fi

    if ! jq -e ".hosts[\"$NIX_HOST\"]" "$DOTFILES_DIR/nix/hosts.json" >/dev/null 2>&1; then
        yell "NIX_HOST '$NIX_HOST' is not valid. Available hosts:"
        yell "$(nix_hosts)"
        yell "See $DOTFILES_DIR/nix/hosts.json for details."
        exit 1
    fi
}

#################################
# apt bootstrap (minimal)
#################################
apt_bootstrap() {
  if [[ ! "$DO_APT" -eq 1 ]]; then
    echo "[bootstrap] (apt_bootstrap) Skipping apt steps because --no-apt was specified..."
    try sudo apt-get dist-upgrade -y
    return
  fi

  echo "[bootstrap] Installing minimal prerequisites via apt..."

  # You can expand this later, but keep it small.
  local pkgs=(
    apt-file
    ca-certificates
    curl
    git
    jq
    libfuse3-3
    locate
    software-properties-common
    xz-utils
  )

  # Add role-specific packages based on host configuration
  if host_has_role "desktop"; then
    pkgs+=(
      i3
      i3status
      kitty
    )
  fi

  if [[ ! "$APT_UPDATE_COMPLETE" -eq 1 ]]; then
  	try sudo apt-get update -y
  fi

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
  # TODO: We already exectued this in main, remove this?
  #source_nix_profile

  if host_has_role "desktop"; then
  	local nvim_path
  	kitty_path="$(command -v kitty || true)"

	  if [[ -n "$kitty_path" ]]; then
	    try sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$kitty_path" 50
	    try sudo update-alternatives --set x-terminal-emulator "$kitty_path"
	  else
	    yell "[bootstrap] kitty not found on PATH; skipping terminal alternative"
	  fi
  else
          echo "[bootstrap] (set_default_terminal_and_editor) Desktop role not enabled, skipping setting default terminal emulator"
  fi

  local nvim_path
  nvim_path="$(command -v nvim || true)"

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


  if ! host_has_role "desktop"; then
        echo "[bootstrap] (install_session_desktop_files) Desktop role not enabled, skipping installing session desktop files"
	return 0
  fi

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
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)          DOTFILES_DIR="$2"; shift 2;;
    --nix-host)     NIX_HOST="$2"; shift 2;;
    --no-upgrade)   DO_UPGRADE=0; shift;;
    --no-apt)       DO_APT=0; shift;;
    -h|--help)      usage; exit 0;;
    *) die "Unknown argument: $1";;
  esac
done

main() {
  echo "[bootstrap] Starting on: $(lsb_release -ds 2>/dev/null || uname -a)"
  if is_wsl; then
    echo "[bootstrap] Detected WSL environment."
  fi

  # TODO: Put this in a function
  # We need jq for this script to run at all so if it's not installed, get it
  if ! command -v jq >/dev/null 2>&1; then
	  try sudo apt-get update -y
	  try sudo apt-get install -y jq
	  APT_UPDATE_COMPLETE="1"
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

  install_docker

  echo "[bootstrap] Done."

  if [[ "$DOCKER_INSTALLED" -eq 1 ]]; then
    echo "[bootstrap] Docker was just installed. Either reboot or log out and back in for the group change to take effect."
  fi
}

main "$@"
