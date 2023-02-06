#!/usr/bin/env bash

rm -f "$HOME/.vimrc"
rm -f "$HOME/.gvimrc"

cp "$HOME/dot/config/vimrc" "$HOME/.vimrc"
cp "$HOME/dot/config/gvimrc" "$HOME/.gvimrc"
