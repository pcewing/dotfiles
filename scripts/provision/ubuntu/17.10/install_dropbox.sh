#!/usr/bin/env bash

source "$DOTFILES/scripts/provision/ubuntu/utils.sh"

section "Installing Dropbox"

apt_install python-gpgme
apt_install libxslt1-dev

echo "Adding dropbox to apt sources list"
try sudo sh -c 'echo "deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu xenial main" >> /etc/apt/sources.list'

echo "Adding gpg key... "
try sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E

apt_update
apt_install dropbox

