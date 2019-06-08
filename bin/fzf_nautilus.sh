#!/usr/bin/env bash

directories="$HOME
$HOME/box/pic/screenshots
$HOME/src"

selection="$(echo "$directories" | rofi -dmenu)"

if [ ! -z "$selection" ]; then
    nautilus "$selection" > /dev/null 2>&1 &
fi

