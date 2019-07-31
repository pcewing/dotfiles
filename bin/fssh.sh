#!/usr/bin/env bash

known_hosts="$(cat "$HOME/.ssh/known_hosts" | sed -e 's/,.*$//')"

selection="$(echo "$known_hosts" | fzf)"

if [ ! -z "$selection" ]; then
    ssh "$selection"
fi

