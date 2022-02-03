#!/usr/bin/env bash

# This script will set Google Chrome as the default browser for the mime types
# specified below. These will be saved in: ~/.config/mimeapps.list
#
# If a certain file type isn't opening in Chrome and it should be, check if
# there is already an entry for it in the mimeapps.list file and then use the
# xdg-mime tool to update or add the entry so that it defaults to Chrome.
# Consider adding it to the list below.

function yell () { >&2 echo "$*";  }
function die () { yell "$*"; exit 1; }
function try () { "$@" || die "Command failed: $*"; }

chrome="/usr/share/applications/google-chrome.desktop"
#firefox="/usr/share/applications/firefox.desktop"

# To change the default browser, change this:
default_browser="$chrome"

mimetypes=(
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
    "x-scheme-handler/webcal"
    "x-scheme-handler/chrome"
    "application/x-extension-htm"
    "application/x-extension-html"
    "application/x-extension-shtml"
    "application/xhtml+xml"
    "application/x-extension-xhtml"
    "application/x-extension-xht"
)

for mimetype in "${mimetypes[@]}"; do
    try xdg-mime default "$default_browser" "$mimetype"
done
