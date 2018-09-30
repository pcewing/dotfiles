# Dotfiles

This repository contains my dotfiles.

## Installation & Cleanup

To make setup easy, scripts are provided to create/remove symlinks. These can
be found in the root directory and should be self-explanatory.

## Manual Setup Steps

Some things require interactive user input and thus I didn't bother scripting.

### Set Default Terminal

Because `st` is built from source it won't be registered as an available
x-terminal-emulator alternative. Install `galternatives` and just do this
through the GUI.

### Setup gitconfig_local

To avoid putting email address in a publicly visible file
```bash
touch ~/.gitconfig_local
```

Make it look like:
```
[user]
    name = Paul Ewing
    email = paul@domain.com
```

