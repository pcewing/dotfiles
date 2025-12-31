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
REPO_URL_DEFAULT="https://github.com/pewing/dotfiles.git"
REPO_DIR_DEFAULT="$HOME/dot"

# This becomes your "attribute"/machine selector.
# Examples later: core, desktop, gaming, server, wsl
MACHINE_DEFAULT="core"

usage() {
  cat <<EOF
Usage: $0 [--repo URL] [--dir PATH] [--machine NAME] [--no-upgrade]

  --repo       Git repo containing your Nix/Home Manager config
               (default: $REPO_URL_DEFAULT)
  --dir        Where to clone it (default: $REPO_DIR_DEFAULT)
  --machine    Home Manager target to apply (default: $MACHINE_DEFAULT)
  --no-upgrade Skip apt-get dist-upgrade (default is to run it)

Examples:
  $0 --repo https://github.com/pcewing/dotfiles.git --machine desktop
  $0 --machine wsl
EOF
}

REPO_URL="$REPO_URL_DEFAULT"
REPO_DIR="$REPO_DIR_DEFAULT"
MACHINE="$MACHINE_DEFAULT"
DO_UPGRADE=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)     REPO_URL="$2"; shift 2;;
    --dir)      REPO_DIR="$2"; shift 2;;
    --machine)  MACHINE="$2"; shift 2;;
    --no-upgrade) DO_UPGRADE=0; shift;;
    -h|--help)  usage; exit 0;;
    *) die "Unknown argument: $1";;
  esac
done

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
# repo sync
#################################
# TODO: I think we can delete this. The plan is to put this bootstrap script in
# my dotfiles repo so this script doesn't need to try to pull/clone/etc because
# it will already be set up.
sync_repo() {
  echo "[bootstrap] Syncing config repo..."

  if [[ -d "$REPO_DIR/.git" ]]; then
    try git -C "$REPO_DIR" fetch --prune
    try git -C "$REPO_DIR" pull --ff-only
  else
    try mkdir -p "$(dirname "$REPO_DIR")"
    try git clone "$REPO_URL" "$REPO_DIR"
  fi
}

#################################
# apply home-manager
#################################
apply_home_manager() {
  echo "[bootstrap] Applying Home Manager target: $MACHINE"

  # Assumes your repo will contain a flake with:
  # homeConfigurations.<machine>
  #
  # We'll create that flake next.
  try nix --extra-experimental-features "nix-command flakes" \
    run "github:nix-community/home-manager" -- \
    switch -b hm-bak --flake "$REPO_DIR/nix#$MACHINE"
}

#################################
# main
#################################
main() {
  echo "[bootstrap] Starting on: $(lsb_release -ds 2>/dev/null || uname -a)"
  if is_wsl; then
    echo "[bootstrap] Detected WSL environment."
  fi

  apt_bootstrap
  install_nix_if_needed
  source_nix_profile
  enable_nix_experimental
  #sync_repo
  apply_home_manager

  echo "[bootstrap] Done."
  echo "Tip: if something goes sideways, Home Manager supports rollback."
}

main "$@"

