#!/usr/bin/env bash

# Set background wallpaper to the default
if command -v feh >/dev/null 2>&1; then
    if [ -f "$HOME/Pictures/default_wallpaper.png" ]; then
        feh --bg-scale "$HOME/Pictures/default_wallpaper.png"
    fi
fi
