#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

SCRIPT_PATH="$( realpath "$0" )"
SCRIPT_DIR="$( dirname "$SCRIPT_PATH" )"

# TODO: This is only half implemented as a hacky test to see if it would be
# useful
#
# Diff the current git repository with a previous commit using Beyond Compare.
# Copies the repository to a temp directory and checks out the specified
# commit/branch/tag. Then runs Beyond compare to do a directory comparison
# between the current directory and the temp directory.
git_diff_with()
{
    # TODO: Document this parameter
    local diff_target="$1"

    if [ -z "$diff_target" ]; then
        # If diff_target isn't specified, default it to the previous commit hash
        diff_target="$(git log -n 1 | grep -E '^commit ' | sed -e 's/^commit //' -e 's/ .*//')"
        echo "Defaulting diff_target to $diff_target"
    fi

    # TODO: We could make this robust and walk up the file tree but for now
    # keep it simple
    if [ ! -d "./.git" ]; then
        yell "ERROR: Not at the root of a git repository"
        return 1
    fi

    local tmp_dir_name tmp_dir
    tmp_dir_name="$(basename $(pwd))_${diff_target}_diff"
    tmp_dir="$HOME/tmp/${tmp_dir_name}"
    
    # TODO: DEBUG REMOVE
    echo "tmp_dir = $tmp_dir"

    # TODO: Error handling below

    # Make sure the temporary directory doesn't already exist
    # TODO: Maybe if it does just leave it and use it? If we're targeting a
    # commit hash or tag it's unlikely to have changed. Could add a parameter
    # to force re-checkout?
    #rm -rf "$tmp_dir"

    if [ ! -d "$tmp_dir" ]; then

        local parent_dir="$(dirname "$tmp_dir")"
        # Make sure the parent directory exists
        if ! mkdir -p "$parent_dir"; then
            yell "ERROR: Parent directory '$parent_dir' does not exist"
            return 1
        fi

        if ! cp -r "$(pwd)" "$tmp_dir"; then
            yell "ERROR: Failed to copy repository to the diff directory"
            return 1
        fi
    fi

    if ! cd "$tmp_dir"; then
        yell "ERROR: Failed to change current working directory to the diff directory"
        return 1
    fi

    # TODO: Find a cleaner way to always get back to the previous working
    # directory. Maybe just execute all of this in a sub-shell?

    if ! git reset --hard; then
        cd -
        yell "ERROR: Git reset in diff directory failed"
        return 1
    fi

    if ! git clean -fdx; then
        cd -
        yell "ERROR: Git clean in diff directory failed"
        return 1
    fi

    if ! git checkout "$diff_target"; then
        cd -
        yell "ERROR: Git checkout in diff directory failed"
        return 1
    fi

    cd -

    local bcompare_exe
    # TODO: If WSL else...
    #bcompare_exe="bcompare"
    bcompare_exe="BCompare.exe"

    # TODO: Doesn't work on WSL because we need to canonicalize the path so
    # that it's a valid Windows network path.
    # e.g. /home/pewing/foo -> \\wsl.localhost\Ubuntu-24.04\home\pewing\foo
    # I don't feel like trying to do that in bash, maybe we can make a Python
    # utility for various path conversions
    echo -e "Executing:\n\"$bcompare_exe\" \"$(pwd)\" \"$tmp_dir\""
    #"$bcompare_exe" "$(pwd)" "$tmp_dir"
    "$bcompare_exe" \
        "\\\\WSL.LOCALHOST\\Ubuntu-24.04\\home\\pewing\\dot" \
        "\\\\WSL.LOCALHOST\\Ubuntu-24.04\\home\\pewing\\tmp\\${tmp_dir_name}"
}

git_diff_with "$1"
