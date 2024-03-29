#!/usr/bin/env bash

# This is a primitive prototype of a "virtual desktop" feature for i3wm. The
# idea is similar to virtual desktops in Gnome or on Windows. I currently only
# use 10 workspaces in my typical i3 setup which is normally plenty but there
# are times when I want more and managing more than 10 is cumbersome.
#
# Virtual desktops in this context are effectively just isolated buckets of
# workspaces. Setting the current virtual desktop will influence all commands
# that operate on workspaces to prepend the virtual desktop name to the
# workspace name. So, if the user is in virtual desktop `a` and activates
# workspace `1`, they are actually activating workspacing `a:1`. If they move
# to virtual desktop b, the same keybinding will activate workspace `b:1`.
#
# If this were a first class feature of i3wm, the i3bar would ideally show the
# current virtual desktop and hide the prefix on the workspace names. Something
# like:
#
# | ( a - [1][2*][3] ) ( b ) ( c )           .... |
#
# In the above example, 'a' is the active virtual desktop, 1,2,3 are the
# workspaces within that desktop, and 2 is the active workspace. `b` and `c`
# are other existing but inactive virtual desktops.


# Killswitch to disable this easily so I can commit the changes to my i3 config
# but easily turn them on/off.
DESKTOPS_ENABLED="false"
#DESKTOPS_ENABLED="true"

# Could optimize and only read this if the command being activated will
# actually need it but this is just a prototype and ideally a real
# implementation wouldn't be reading it from a file which is already slow.
CURRENT_DESKTOP_FILE="/tmp/i3_current_desktop.txt"
CURRENT_DESKTOP="a"
if [ "$DESKTOPS_ENABLED" = "true" ] && [ -f "$CURRENT_DESKTOP_FILE" ]; then
    CURRENT_DESKTOP="$(cat "$CURRENT_DESKTOP_FILE")"
fi

function usage() {
    1>&2 echo "Usage: i3-util.sh <command> <args>"
}

function cmd_desktop() {
    local desktop_name="$1"
    [ -n "$desktop_name" ] || return 1
    
    echo "Setting current desktop: '$desktop_name'"
    echo "$desktop_name" > "$CURRENT_DESKTOP_FILE"
    CURRENT_DESKTOP="$desktop_name"
}

function cmd_workspace() {
    local workspace_name="$1"
    [ -n "$workspace_name" ] || return 1

    if [ "$DESKTOPS_ENABLED" = "true" ]; then
        workspace_name="$CURRENT_DESKTOP:$workspace_name"
    fi

    echo "Switching to workspace: $workspace_name"
    i3-msg workspace "$workspace_name"
}

function cmd_move_container() {
    local workspace_name="$1"
    [ -n "$workspace_name" ] || return 1

    if [ "$DESKTOPS_ENABLED" = "true" ]; then
        workspace_name="$CURRENT_DESKTOP:$workspace_name"
    fi

    echo "Moving container to workspace: $workspace_name"
    i3-msg move container to workspace "$workspace_name"
}

COMMAND="$1"
shift

case "$COMMAND" in
    "desktop")        cmd_desktop        "$@" ;;
    "workspace")      cmd_workspace      "$@" ;;
    "move-container") cmd_move_container "$@" ;;
    *)                usage              "$@" ;;
esac
