#!/usr/bin/env bash

# compare.sh is used to compare two commit hashes within a repository locally.
# This can come in handy in cases such as when a PR diff is too big to view
# nicely in the GitHub web UI.
#
# Example usage:
#     compare.sh "hashicorp" "consul" "e44bce3c" "8c519d54"

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

function usage() {
    >&2 cat << EOF
Usage:
    compare.sh <org> <repo> <commit-hash-before> <commit-hash-after>

Example:
    compare.sh 'hashicorp' 'consul' 'e44bce3c' '8c519d54'
EOF
}

if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
    usage
    exit 1
fi

org="$1"
repo="$2"
commit_hash_left="$3"
commit_hash_right="$4"

dir_compare="$HOME/src/compare"
try mkdir -p "$dir_compare"

dir_left="$dir_compare/$repo-left"
dir_right="$dir_compare/$repo-right"

# If either directory doesn't exist, just delete and re-clone
if [[ ! -d "$dir_left" || ! -d "$dir_right" ]]; then
    # Delete existing clones if they exist
    rm -rf "$dir_left"
    rm -rf "$dir_right"

    # Clone once and then copy
    try git clone "git@github.com:$org/$repo.git" "$dir_left"
    try cp -r "$dir_left" "$dir_right"
fi

# Checkout left commit hash
try cd "$dir_left"
try git clean -fdx
try git fetch --all
try git checkout "$commit_hash_left"
try cd "$dir_compare"

# Checkout right commit hash
try cd "$dir_right"
try git clean -fdx
try git fetch --all
try git checkout "$commit_hash_right"
try cd "$dir_compare"

# Compare the two
bcompare "$dir_left" "$dir_right"
