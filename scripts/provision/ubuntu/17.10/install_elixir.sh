#!/usr/bin/env bash

source "$DOTFILES/scripts/provision/ubuntu/utils.sh"

section "Installing Elixir"

echo "Downloading the Erlang/Elixir package"
try wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb

echo "Installing the Erlang/Elixir package"
try sudo dpkg -i erlang-solutions_1.0_all.deb

apt_update
apt_install esl-erlang
apt_install elixir

echo "Removing the Erlang/Elixir package"
rm erlang-solutions_1.0_all.deb

