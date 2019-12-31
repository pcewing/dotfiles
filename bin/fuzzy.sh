#!/usr/bin/env bash

action="$1"

if [ -z "$action" ]; then
    echo "Usage: ./fuzzy.sh <action>" 1>&2
    exit 1
fi

directories="$HOME
$HOME/box/pic/screenshots
$HOME/src
$HOME/box
$HOME/.config
$HOME/box/doc
$HOME/box/pic
$HOME/box/mus
$HOME/box/vid
$HOME/Desktop
$HOME/Downloads
$HOME/Templates
$HOME/Public
$HOME/Documents
$HOME/Music
$HOME/Pictures
$HOME/Videos"

function fuzzy_nautilus() {
    selection="$(echo "$directories" | rofi -i -dmenu -p "nautilus")"

    if [ ! -z "$selection" ]; then
        nautilus "$selection" > /dev/null 2>&1 &
    fi
}

function fuzzy_ranger() {
    selection="$(echo "$directories" | rofi -i -dmenu)"

    if [ ! -z "$selection" ]; then
        urxvt -e bash -c "ranger \"$selection\""
    fi
}

if [ "$action" = "nautilus" ]; then
    fuzzy_nautilus
    exit 0
elif [ "$action" = "ranger" ]; then
    fuzzy_ranger
    exit 0
fi

echo "ERROR: Unknown action \"$action\"" 1>&2
exit 1

