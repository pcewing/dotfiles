#!/usr/bin/env bash

# IMPROVEMENT: Use docker's built-in filtering with -q flag instead of grep/awk parsing.
# This is more reliable as it avoids issues with column alignment or format changes.

function destroy_containers() {
    containers="$(docker ps -aq)"
    if [ -n "$containers" ]; then
        echo "$containers" | xargs docker rm -f
    fi
}

function destroy_images() {
    images="$(docker images -q)"
    if [ -n "$images" ]; then
        echo "$images" | xargs docker rmi
    fi
}

destroy_containers
destroy_images
