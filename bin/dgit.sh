#!/usr/bin/env bash

# Directory Git
#
# This script provides a way to run common git commands across multiple
# repositories cloned into the same directory. For example, if two repositories
# are cloned as follows:
#
# mkdir foo && cd foo
# git clone git@github.com:org/repo1.git
# git clone git@github.com:org/repo2.git
#
# Then the status of all repositories in the foo directory can be printed via:
#
# cd foo && dgit.sh s

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

script_path="$( realpath "$0" )"
script_dir="$( dirname "$script_path" )"

COLOR_RED='\033[0;31m'
COLOR_GREY='\033[1;30m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;37m'
COLOR_NONE='\033[0m'

function status_short() {
    local repo="$1"

    local status="$(git status --short)"

    if [ -z "$status" ]; then
        echo -e "${COLOR_GREEN}$repo${COLOR_NONE}"
    else
        echo -e "${COLOR_RED}$repo:\n$(git status --short)${COLOR_NONE}"
    fi
}

cmd="$1"
if [ -z "$cmd" ]; then
    cmd="s"
fi

dir="$(realpath ".")"
repos="$(find "$dir" -maxdepth 1 -type d | xargs realpath)"

for repo in $repos; do
    if [ "$repo" = "$dir" ]; then
        continue
    fi

    if [ ! -d "$repo/.git" ]; then
        echo -e "${COLOR_GREY}$repo is not a git repository, skipping...${COLOR_NONE}"
        continue
    fi

    cd "$repo"

    if [ "$cmd" = "s" ]; then
        status_short "$repo"
    fi
done
