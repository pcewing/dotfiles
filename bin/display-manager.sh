#!/usr/bin/env bash

action="$1"
if [ "$action"="d" -o "$action"="disable" ]; then
    # Disable the graphical display manager and boot to TTY
    sudo systemctl set-default multi-user.target
elif [ "$action"="e" -o "$action"="enable" ]; then
    # Enable the graphical display manager
    sudo systemctl set-default graphical.target
fi

