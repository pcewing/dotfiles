#!/usr/bin/env bash

set -euo pipefail

yell() { >&2 echo "$*"; }
die()  { yell "ERROR: $*"; exit 1; }
try()  { "$@" || die "Command failed: $*"; }

DOTFILES="${DOTFILES:-$( cd "$( dirname "$( realpath "$0" )" )" && pwd )}"

# Use this when moving a host that was previously provisioned with Nix/Home
# Manager back to the hybrid provisioning system. It removes the Home Manager
# generated files and replaces store symlinks with links into this repository.

echo "[deprovision-nix] Cleaning up Home Manager-generated files"

# Home Manager provides ~/.local/bin/dot; the hybrid uses the repo virtualenv.
if [ -e "$HOME/.local/bin/dot" ] || [ -L "$HOME/.local/bin/dot" ]; then
    echo "[deprovision-nix] Removing $HOME/.local/bin/dot"
    rm -f "$HOME/.local/bin/dot"
fi

# Replace any Home Manager store symlinks with links to the repository.
if [ -x "$DOTFILES/.venv/bin/dot" ]; then
    echo "[deprovision-nix] Re-creating dotfile symlinks from links.json"
    try "$DOTFILES/.venv/bin/dot" links init
else
    yell "[deprovision-nix] $DOTFILES/.venv/bin/dot not found;"
    yell "                  run ./bootstrap.sh first, then 'dot links init'"
fi

cat <<'EOF'

[deprovision-nix] Done. Remaining manual steps to fully remove Nix:

  - Uninstall single-user Nix (destructive):
      rm -rf ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nix /nix
  - Remove any Nix-related shell configuration not managed by this repository.
EOF
