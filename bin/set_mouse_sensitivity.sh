#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

# Imperative helper for changing mouse acceleration in the current X session.
#
# The persistent version of this setting is managed by the dotfiles repo; see
# config/xorg.conf.d/50-mouse-acceleration.conf, which is installed to
# /etc/X11/xorg.conf.d/ by:
#
#     dot provision system
#
# Because that file matches on the device product name, it only ever applies to
# the physical mice listed in MICE_NAMES below, and is never picked up by the
# virtual pointers that remote desktop tools inject. Use this script to apply
# the change without restarting the X server, or to experiment with values.
#
# To discover the product string of a device, run:
# $ xinput
#
# | Virtual core pointer                        id=2    [master pointer  (3)]
# |   |_ Virtual core XTEST pointer             id=4    [slave  pointer  (2)]
# |   |_ SINOWEALTH 2.4G Wireless Receiver      id=16   [slave  pointer  (2)]
#
# Keep MICE_NAMES in sync with the MatchProduct entries in that config file.

MICE_NAMES=(
    "Logitech G Pro"
    "SINOWEALTH 2.4G Wireless Receiver"
)

ACCELERATION_SPEED="$1"
if [[ -z "$ACCELERATION_SPEED" ]]; then
    ACCELERATION_SPEED="-1.0"
fi

XINPUT_LIST="$( xinput list )"

for mouse_name in "${MICE_NAMES[@]}"; do
    DEVICE_ID_STR="$( xinput list | grep "$mouse_name.*pointer" )"
    if [[ ! $DEVICE_ID_STR =~ id=([0-9]+) ]]; then
        echo "Pointer device \"$mouse_name\" not found, skipping..."
        continue
    fi

    DEVICE_ID="${BASH_REMATCH[1]}"
    try xinput --set-prop "$DEVICE_ID" 'libinput Accel Speed' "$ACCELERATION_SPEED"
    echo "Set $mouse_name (ID = $DEVICE_ID) acceleration speed to $ACCELERATION_SPEED"
done
