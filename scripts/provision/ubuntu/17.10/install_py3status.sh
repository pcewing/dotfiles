#!/usr/bin/env bash

if [[ "$DOTFILES" = "" ]]; then echo "Please ensure the DOTFILES environment variable is set"; exit 1; fi
source "$DOTFILES/scripts/provision/ubuntu/17.10/utils.sh"

print_header "Installing py3status"

try pip install py3status

