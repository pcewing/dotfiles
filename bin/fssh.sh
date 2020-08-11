#!/usr/bin/env bash

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }

fssh_hosts_file="$HOME/.fssh_hosts"

if [ ! -f "$fssh_hosts_file" ]; then
    die "ERROR: Hosts file \"$fssh_hosts_file\" does not exist!"
fi

fssh_hosts="$(cat "$HOME/.fssh_hosts" | grep -vP '(^ *$)|(^#.*)')"

selection="$(echo "$fssh_hosts" | fzf)"

if [ ! -z "$selection" ]; then
    ssh "$selection"
fi

