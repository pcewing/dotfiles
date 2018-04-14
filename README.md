# Dotfiles
This repository contains my dotfiles.

## Setup
The *setup* script in the root directory will clean existing configuration
files and create symbolic links to the configuration files in this repository.

For usage information:
```bash
./setup -h
```

### Remote Systems
The *setup* script supports configuring systems that do not need any of the
graphical components by specifying the `-r` option. With this option specified:
* The `link` action will not link non-GUI configuration files
* The `clean` action will not remove non-GUI configuration files

### Manual Environment Setup Steps
Some things require interactive user input.

#### Set Default Shell
```bash
chsh -s $(which zsh)
```

#### Set Default Terminal
```bash
sudo update-alternatives --config x-terminal-emulator
```

#### Setup gitconfig_local
To avoid putting email address in a publicly visible file
```bash
touch ~/.gitconfig_local
```

Make it look like:
```
[user]
    name = Paul Ewing
    email = paul@cooldomain.com
```

#### Setup Screen Configuration
The `i3config` file will source `~/.screenlayout/config.sh` if it exists; put
`xrandr` configuration there if necessary.

