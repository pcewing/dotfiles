#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }

function run_compton() {
    if pgrep compton &>/dev/null; then
        killall compton &>/dev/null
    fi

    compton --no-fading-openclose
}

function run_picom() {
    if ! pgrep picom &>/dev/null; then
        picom --no-fading-openclose
    fi
}

function run_default() {
    if command -v picom &>/dev/null; then
        run_picom
    elif command -v compton &>/dev/null; then
        run_compton
    else
        die "ERROR: No supported compositor installed"
    fi
}

case "$1" in
    "compton")  run_compton ;;
    "picom")    run_picom   ;;
    *)          run_default ;;
esac
