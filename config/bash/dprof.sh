#!/usr/bin/env bash

# "dprof" is just short for dotfile profiler. This script provides a primitive
# way to benchmark bash. I recently had an issue where new bash shells were
# taking a long time to start up in WSL and had to dig into what was causing
# the slow down. I decided to save this stuff in case I need to debug similar
# issues in the future.
#
# Usage:
#
#     - Execute `dprof_start "label"` to record a timestamp associated with the
#       string "label"
#     - Execute `dprof_since "label"` to print the duration in milliseconds
#       since the initial timestamp was recorded
#
# Example:
#
#     source "$HOME/dot/config/bash/dprof.sh"
#     dprof_start "Load ~/.foorc"
#     source ~/.foorc
#     dprof_since "Load ~/.foorc"

if [ -z "$DOT_DPROF_SOURCED" ]; then
    DOT_DPROF_SOURCED=1

    declare -A DPROF_ENTRIES=()

    function dprof_timestamp() {
        echo "$(date +%s%N | cut -b1-13)"
    }

    function dprof_start() {
        local label="$1"
        DPROF_ENTRIES["$label"]="$(dprof_timestamp)"
        echo "[START - $label]"
    }

    function dprof_since() {
        local label="$1"
        since="${DPROF_ENTRIES["$label"]}"
        now="$(dprof_timestamp)"
        echo "[END   - $label] Duration = $(( $now - $since ))ms"
    }
fi
