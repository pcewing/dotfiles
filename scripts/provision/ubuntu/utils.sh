#!/usr/bin/env bash

try()
{
    "$@" > ~/.command_log 2>&1
    local ret_val=$?
  
    if [ $ret_val -eq 0 ]; then
        echo "SUCCESS"
    else
        echo "FAILURE"
        echo "Command: $*"
        echo "Output:"
        cat ~/.command_log
        exit 1
    fi
}

apt_update(){ echo "Updating package lists... "; try sudo apt-get -y update; }
apt_upgrade(){ echo "Upgrading packages... "; try sudo apt-get -y upgrade; }
apt_install(){ echo "Installing $1... "; try sudo apt-get -y install "$1"; }
apt_add_repo(){ echo "Adding $1 repository... "; try sudo add-apt-repository -y "ppa:$1"; }

