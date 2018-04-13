#!/usr/bin/env bash

source "$DOTFILES/scripts/provision/ubuntu/utils.sh"

golang_version=1.9

section "Installing Golang"
echo "Downloading golang v$golang_version tarball"
try wget "https://storage.googleapis.com/golang/go$golang_version.linux-amd64.tar.gz"

echo "Extracting the golang tarball"
try sudo tar -C /usr/local -xzf go$golang_version.linux-amd64.tar.gz

echo "Removing golang tarball"
try rm go$golang_version.linux-amd64.tar.gz

echo "Setting up golang directory structure"
try mkdir -p "$HOME/go/bin"
try mkdir -p "$HOME/go/pkg"
try mkdir -p "$HOME/go/src/github.com/pcewing"

