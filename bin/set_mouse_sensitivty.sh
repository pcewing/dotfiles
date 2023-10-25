#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

# To permanently set this, identify the product string by running:
# $ xinput
#
# | Virtual core pointer                        id=2    [master pointer  (3)]
# |   |_ Virtual core XTEST pointer             id=4    [slave  pointer  (2)]
# |   |_ SINOWEALTH 2.4G Wireless Receiver      id=16   [slave  pointer  (2)]
#
# Next, create a file here:
#
# /etc/X11/xorg.conf.d/50-mouse-acceleration.conf
#
# Finally, add the contents:
#
#Section "InputClass"
#    Identifier "Dark Matter Wireless Gaming Mouse"
#    MatchDriver "libinput"
#    MatchProduct "SINOWEALTH 2.4G Wireless Receiver"
#    Option "AccelSpeed" "-0.75"
#EndSection

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
