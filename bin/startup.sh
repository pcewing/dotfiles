#!/usr/bin/env bash

logdir="$HOME/.logs"
mkdir -p "$logdir"

logfile="$logdir/startup.log"

start_process() {
    local procname="$1"
    local procargs="$2"
    local kill="$3"
    local notify="$4"

    if [[ ! -z "$(which $procname)" ]]; then
        if [[ "$kill" = "1" ]]; then
            killall -q "$procname"
            while pgrep -x "$procname" >/dev/null; do sleep 0.1; done
        fi

        $procname $procargs >> "$logfile" 2>&1 &
    else
        if [[ "$notify" = "1" ]]; then
            notify-send \
                -u normal \
                -t 5000 \
                "Failed to start $procname" \
                "Ensure that the program \"$procname\" is installed"
        fi
    fi
}

echo "Starting up user processes $(date)" >> "$logfile" 2>&1
start_process "insync"      "start" "1" "0"
start_process "wpr"         ""      "1" "0"
start_process "nm-applet"   ""      "1" "1"

