#!/usr/bin/env bash

if [[ "$DOTFILES" = "" ]]; then echo "Please ensure the DOTFILES environment variable is set"; exit 1; fi
source "$DOTFILES/scripts/provision/ubuntu/17.10/utils.sh"

antigen_version=2.2.3

print_header "Installing Antigen"

echo "Creating the $HOME/.zsh directory if it doesn't exist...  "
try mkdir -p "$HOME/.zsh"

echo "Downloading antigen version ${antigen_version}..."
try eval $(curl https://cdn.rawgit.com/zsh-users/antigen/v${antigen_version}/bin/antigen.zsh > "$HOME/.zsh/antigen.zsh")

