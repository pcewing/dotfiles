#!/usr/bin/env bash

logdir="$HOME/.logs"
mkdir -p "$logdir"

logfile="$logdir/startup.log"

function start_process() {
    local procname="$1"
    local procargs="$2"
    local kill="$3"
    local notify="$4"

    # Make sure the program is installed
    if [[ -z "$(which $procname)" ]]; then
        # If not, post a notification if desired
        if [[ "$notify" = "1" ]]; then
            notify-send \
                -u normal \
                -t 5000 \
                "Failed to start $procname" \
                "Ensure that the program \"$procname\" is installed"
        fi
        return
    fi

    # Check if the program is already running
    local running="1"
    [ -z "$(pgrep -x "$procname")" ] && running="0"

    # If it's not running just run it
    if [ "$running" = "0" ]; then
        $procname $procargs >> "$logfile" 2>&1 &
        return
    fi

    # If it is running, check if we should kill it and re-run
    if [[ "$kill" = "1" ]]; then
        killall -q "$procname"
        while pgrep -x "$procname" >/dev/null; do
            sleep 0.1
        done

        $procname $procargs >> "$logfile" 2>&1 &
    fi
}

echo "Starting up user processes $(date)" >> "$logfile" 2>&1
start_process "insync"         "start" "0" "0"
start_process "wpr"            ""      "1" "0"
start_process "nm-applet"      ""      "0" "1"
start_process "blueman-applet" ""      "0" "1"
