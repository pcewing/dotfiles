# Dotfiles
This repository contains my dotfiles.

My environment looks like:
![Screenshot](./Screenshot.png)

## Software
For a complete list of the software configured it is best to just look in the **scripts/provision/ubuntu.sh** provisioning script as the list in the README would likely become outdated. That being said, my primary development stack isn't likely to change and it looks like:  

**Local (Graphical) Environment**  
`i3wm` -> `urxvt` -> `zsh` -> `neovim`

**Remote Environment**  
`ssh`-> `tmux` -> `zsh` -> `neovim`

## Setup
The *setup* script in the root directory is designed to help clean existing configuration files, create symbolic links to the configuration files in this repository, and provision necessary software/packages. For usage information:
```bash
git clone https://github.com/pcewing/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup -h
```

The most common use of the script will look as follows:
```bash
git clone https://github.com/pcewing/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup -lpd ubuntu
```
This will link the configuration files and provision all necessary software/packages for an Ubuntu system.

### Supported Platforms
Currently Ubuntu is the only Linux distro supported by a provision script. I don't want to maintain a script for Arch as it would be specific to my hardware and very seldom used.

### Remote Systems
The majority of the development tools I use are terminal based, which is awesome given that I commonly work on remote systems or Vagrant VMs via SSH. However, there are a few pieces of software that are unnecessary on remote systems such as *urxvt* and *i3wm*.

The *setup* script supports configuring and provisioning systems that do not need any of the graphical components by specifying the `-r` option.

For example, to configure and provision an Ubuntu system intended for remote use:
```bash
ssh user@remote.com
git clone https://github.com/pcewing/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup -lprd ubuntu
```

### Manual Steps
I can't (gracefully) automate everything and certain steps require user input or are machine-specific, so the following should be performed manually.

#### Set Default Shell
```bash
chsh -s $(which zsh)
```

#### Set Default Terminal
```bash
sudo update-alternatives --config x-terminal-emulator
```

#### Install Neovim Plugins
This can be done after launching Neovim by executing the command:
```
:PlugInstall
```
...or from the command line via:
```bash
nvim +PlugInstall +qa
```

#### Setup Screen Configuration
**WARNING**: The screen layout file in this repo is catered to my home machine! This file is hardware-specific.

To generate your own, download the arandr package (A front-end for xrandr), run it, and save the desired configuration to `~/.screenlayout/config.sh`. If that file exists, it will be sourced in the *i3* config.
```bash
mkdir -p ~/.screenlayout
ln -s ~/.dotfiles/config/screenlayout ~/.screenlayout/config.sh
```

#### Setup Wallpaper
Use the `nitrogen` package, which is basically just a GUI frontend for `feh`. Set the desired wallpapers for each screen and then save the configuration. This configuration is restored every time X starts in the i3config.

### WSL (Windows Subsystem for Linux)
**Warning** I haven't worked in WSL for quite some time because it was so clunky before. This section is out-of-date and may be inaccurate.
A bit of extra setup is necessary for working with Ubuntu on Windows.

#### 1. Get a better terminal window because the built in one sucks.

Mintty (For WSL) should be installed from https://github.com/mintty/wsltty

#### 2. Set up solarized colors.

The *WSL/minttyrc* file in this repo should be copied to %LOCALAPPDATA%\\wsltty\\home\\%USERNAME%\\.minttyrc

#### 3. Set the correct terminal type and automatically start *zsh*.

The following lines should be added to ~/.bashrc:
```bash
# Add this at the beginning
export TERM=xterm-256color

# Add this at the very end
$(which zsh)
```

