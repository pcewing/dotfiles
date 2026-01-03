#!/usr/bin/env bash

DOTFILES_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/logs"
LOG_FILE="run_vm_guest_additions_$(date +"%Y%m%d_%H%M%S").log"
LOG_PATH="${DOTFILES_LOG_DIR}/${LOG_FILE}"

log() {
    echo "$*" >> "$LOG_PATH"
}

# If spice-vdagent is installed, we're probably running in a Virtual Machine.
# Start it up because it enables clipboard sharing between host and guest.
if command -v spice-vdagent >/dev/null 2>&1; then
    log "Found spice-vdagent at: $(command -v spice-vdagent)"
    if pgrep -x spice-vdagent >/dev/null; then
        log "spice-vdagent already running; skipping"
    else
        log "Starting spice-vdagent"
        spice-vdagent >> "$LOG_PATH" 2>&1
    fi
else
    log "spice-vdagent command not found; skipping"
fi
