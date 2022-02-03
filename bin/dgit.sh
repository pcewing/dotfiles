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

COLOR_RED='\033[0;31m'
COLOR_GREY='\033[1;30m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;37m'
COLOR_NONE='\033[0m'

cmd="$1"

function status_short() {
    local repo
    local status

    repo="$1"

    status="$(git status --short)"

    if [ -z "$status" ]; then
        echo -e "${COLOR_GREEN}$repo${COLOR_NONE}"
    else
        echo -e "${COLOR_RED}$repo:\n$(git status --short)${COLOR_NONE}"
    fi
}

function unpushed() {
    local repo
    local unpushed_commits

    repo="$1"

    unpushed_commits="$(git log --branches --not --remotes)"

    if [ -z "$unpushed_commits" ]; then
        echo -e "${COLOR_GREEN}$repo${COLOR_NONE}"
    else
        echo -e "${COLOR_RED}$repo${COLOR_NONE}"
    fi
}

function pull() {
    local repo

    repo="$1"

    if git pull origin master &>/dev/null; then
        echo -e "${COLOR_GREEN}$repo pull succeeeded${COLOR_NONE}"
    else
        echo -e "${COLOR_RED}$repo pull failed${COLOR_NONE}"
    fi
}

function usage() {
    echo "Usage: dgit.sh <command>"
    echo "Commands:"
    echo "    s    Print short status of repositories"
    echo "    u    Show unpushed commits in repositories"
    echo "    p    Pull repositories from origin/master"
}

dir="$(realpath ".")"
repos="$(find "$dir" -maxdepth 1 -type d -print0 | xargs -0 realpath)"

for repo in $repos; do
    if [ "$repo" = "$dir" ]; then
        continue
    fi

    if [ ! -d "$repo/.git" ]; then
        echo -e "${COLOR_GREY}$repo is not a git repository, skipping...${COLOR_NONE}"
        continue
    fi

    try cd "$repo"

    case "$cmd" in
        "s") status_short "$repo" ;;
        "u") unpushed     "$repo" ;;
        "p") pull         "$repo" ;;
        *)   usage;       exit 1; ;;
    esac
done
