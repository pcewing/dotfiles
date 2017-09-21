#!/usr/bin/env bash

distro=$1
remote=$2

source $DOTFILES/scripts/provision/$distro.sh

install_all $remote

