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
  --no-apt     Skip all apt-get steps

Examples:
  $0 --nix-host personal-desktop
EOF
}

DOTFILES_DIR="$DOTFILES_DIR_DEFAULT"
NIX_HOST=""
DO_UPGRADE=1
DO_APT=1

nix_hosts() {
    if [ -f "$DOTFILES_DIR/nix/hosts.json" ]; then
        jq -r '.hosts | keys[]' "$DOTFILES_DIR/nix/hosts.json"
    else
        ls "$DOTFILES_DIR/nix/home/hosts" 2>/dev/null | sed 's/\.nix$//' || true
    fi
}

host_has_feature() {
    local feature="$1"
    if [ -z "$NIX_HOST" ] || [ ! -f "$DOTFILES_DIR/nix/hosts.json" ]; then
        return 1
    fi
    jq -e ".hosts[\"$NIX_HOST\"].features | index(\"$feature\")" \
        "$DOTFILES_DIR/nix/hosts.json" >/dev/null 2>&1
}

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
  if [[ ! "$DO_APT" -eq 1 ]]; then
    echo "[bootstrap] (apt_bootstrap) Skipping apt steps because --no-apt was specified..."
    try sudo apt-get dist-upgrade -y
    return
  fi

  echo "[bootstrap] Installing minimal prerequisites via apt..."

  # You can expand this later, but keep it small.
  local pkgs=(
    ca-certificates
    curl
    git
    locate
    xz-utils
    jq
  )

  # Add feature-specific packages based on host configuration
  if host_has_feature "desktop"; then
    pkgs+=(
      kitty
      i3
      i3status
    )
  fi

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
