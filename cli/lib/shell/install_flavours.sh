#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

SCRIPT_PATH="$( realpath "$0" )"
SCRIPT_DIR="$( dirname "$SCRIPT_PATH" )"

function get_latest_github_release() {
    local org="$1"
    local repo="$2"

    local api_url="https://api.github.com/repos/$org/$repo/releases/latest"
    echo "$( curl --silent "$api_url" | jq -r .tag_name )"
}

function install_flavours() {
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

install_flavours
