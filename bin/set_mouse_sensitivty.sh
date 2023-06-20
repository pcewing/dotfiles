#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

MOUSE_NAME="Logitech G Pro"

ACCELERATION_SPEED="$1"
if [[ -z "$ACCELERATION_SPEED" ]]; then
    ACCELERATION_SPEED="-1.0"
fi

DEVICE_ID_STR="$( xinput list | grep "$MOUSE_NAME.*pointer" )"
if [[ ! $DEVICE_ID_STR =~ id=([0-9]+) ]]; then
    die "ERROR: Pointer device \"$MOUSE_NAME\" not found"
fi

DEVICE_ID="${BASH_REMATCH[1]}"

try xinput --set-prop "$DEVICE_ID" 'libinput Accel Speed' "$ACCELERATION_SPEED"

echo "Set $MOUSE_NAME (ID = $DEVICE_ID) acceleration speed to $ACCELERATION_SPEED"
