#!/usr/bin/env bash

set -euo pipefail

#==============================================================================
# Utilities
#==============================================================================

yell() { >&2 echo "$*"; }
die()  { yell "ERROR: $*"; exit 1; }
try()  { "$@" || die "Command failed: $*"; }

usage() {
    cat <<EOF
Usage: $0 [--dir PATH] [--venv PATH] [--no-update] [--provision]

  --dir PATH    Dotfiles directory (default: the directory containing this script)
  --venv PATH   Virtualenv location (default: <dotfiles>/.venv)
  --no-update   Skip apt-get update
  --provision   Run 'dot provision' after bootstrapping

This script installs just enough to run the 'dot' CLI (Python, package
prerequisites, and a virtualenv with the dot package installed). Run
'dot provision' afterwards to install everything else.
EOF
}

#==============================================================================
# Configuration
#==============================================================================

DOTFILES=""
VENV=""
DO_UPDATE=1
RUN_PROVISION=0

# The minimum needed to run the dot CLI and for the provisioners to download
# and build the rest. Keep this list small; everything else belongs in the
# Python provisioners.
APT_PACKAGES=(
    ca-certificates
    curl
    wget
    git
    gnupg
    software-properties-common
    apt-transport-https
    lsb-release
    unzip
    xz-utils
    build-essential
    pkg-config
    python3
    python3-venv
    python3-pip
    python3-dev
    python-is-python3
)

#==============================================================================
# Arguments
#==============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)         DOTFILES="$2"; shift 2;;
        --venv)        VENV="$2"; shift 2;;
        --no-update)   DO_UPDATE=0; shift;;
        --provision)   RUN_PROVISION=1; shift;;
        -h|--help)     usage; exit 0;;
        *)             die "Unknown argument: $1";;
    esac
done

if [[ -z "$DOTFILES" ]]; then
    DOTFILES="$( cd "$( dirname "$( realpath "$0" )" )" && pwd )"
fi

if [[ -z "$VENV" ]]; then
    VENV="$DOTFILES/.venv"
fi

[[ -f "$DOTFILES/pyproject.toml" ]] \
    || die "pyproject.toml not found in $DOTFILES; is --dir correct?"

echo "[bootstrap] Dotfiles directory: $DOTFILES"
echo "[bootstrap] Virtualenv:         $VENV"

if [[ "$DO_UPDATE" -eq 1 ]]; then
    echo "[bootstrap] Updating apt package lists..."
    try sudo apt-get update -y
fi

echo "[bootstrap] Installing bootstrap packages..."
try sudo apt-get install -y "${APT_PACKAGES[@]}"

if [[ ! -d "$VENV" ]]; then
    echo "[bootstrap] Creating virtual environment..."
    try python3 -m venv "$VENV"
else
    echo "[bootstrap] Virtual environment already exists, reusing it"
fi

echo "[bootstrap] Installing the dot CLI into the virtual environment..."
try "$VENV/bin/pip" install --upgrade pip setuptools wheel
try "$VENV/bin/pip" install -e "$DOTFILES"

echo "[bootstrap] Done."
echo
echo "Next steps:"
echo "  source \"$VENV/bin/activate\""
echo "  dot provision --host <host-name>   # or set DOT_HOST in ~/.localrc"

if [[ "$RUN_PROVISION" -eq 1 ]]; then
    echo "[bootstrap] Running 'dot provision'..."
    try "$VENV/bin/dot" provision
fi
