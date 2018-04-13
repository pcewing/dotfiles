#!/usr/bin/env bash

source "$DOTFILES/scripts/provision/ubuntu/utils.sh"

section "Installing .NET Core"

echo "Downloading the Microsoft GPG key"
try sudo sh -c 'curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg'
echo "Registering the Microsoft GPG key"
try sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
echo "Registering the package source"
try sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-artful-prod artful main" > /etc/apt/sources.list.d/dotnetdev.list'

apt_update
apt_install dotnet-sdk-2.1.4

