#!/usr/bin/env bash

function destroy_containers() {
    containers="$(docker ps -a \
        | grep -Ev '^CONTAINER' \
        | awk '{print $1}')"

    if [ ! -z "$containers" ]; then
        echo "$containers" | xargs docker rm -f
    fi
}

function destroy_images() {
    images="$(docker images \
        | grep -Ev '^REPOSITORY' \
        | awk '{print $3}')"
    
    if [ ! -z "$images" ]; then
        echo "$images" | xargs docker rmi
    fi
}

destroy_containers
destroy_images
