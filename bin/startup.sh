#!/usr/bin/env bash

logdir="$HOME/.logs"
mkdir -p "$logdir"

logfile="$logdir/startup.log"

start_process() {
    local procname="$1"
    local procargs="$2"

    if [[ ! "$(which $procname)" = "" ]]; then
        killall -q "$procname"

        while pgrep -x "$procname" >/dev/null; do sleep 0.1; done

        $procname $procargs >> "$logfile" 2>&1 &
    else
        notify-send \
            -u critical \
            -t 5000 \
            "Failed to start $procname" \
            "Ensure that the program \"$procname\" is installed"
    fi
}

echo "Starting up user processes $(date)" >> "$logfile" 2>&1
start_process "polybar" "top"
start_process "insync" "start"
start_process "wpr" ""

