#!/usr/bin/env bash

if pidof wpr; then
    echo "Killing wpr"
    killall wpr
fi

$HOME/go/bin/wpr &

