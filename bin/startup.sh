#!/usr/bin/env bash

start_process() {
    local procname="$1"
    local procargs="$2"

    if [[ ! "$(which $procname)" = "" ]]; then
        killall -q "$procname"

        while pgrep -x "$procname" >/dev/null; do sleep 0.1; done

        $procname $procargs &
    else
        notify-send \
            -u critical \
            -t 5000 \
            "Failed to start $procname" \
            "Ensure that the program \"$procname\" is installed"
    fi
}

start_process "polybar" "top"
start_process "insync" "start"
start_process "wpr" ""

