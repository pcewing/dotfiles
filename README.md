# Dotfiles
This repository contains my dotfiles.

## Setup
The *setup* script in the root directory is designed to help clean existing
configuration files, create symbolic links to the configuration files in this
repository, and provision necessary software/packages. For usage information:
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
This will link the configuration files and provision all necessary
software/packages for an Ubuntu system.

### Supported Platforms
Ubuntu is the only Linux distro supported by a provision script.

### Remote Systems
The *setup* script supports configuring and provisioning systems that do not
need any of the graphical components by specifying the `-r` option.

To configure and provision an Ubuntu system intended for remote use:
```bash
ssh user@remote.com
git clone https://github.com/pcewing/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup -lprd ubuntu
```

### Manual Steps
Some things require user input so I left them out of the provision script.

#### Set Default Shell
```bash
chsh -s $(which zsh)
```

#### Set Default Terminal
**This only necessary if more than one terminal emulator is installed.**
```bash
sudo update-alternatives --config x-terminal-emulator
```

#### Install Proprietary Graphics Driver
This isn't always necessary but some games (Like Minecraft) run like shit with
open source drivers.

```bash
# Check if this is still the latest available driver via:
# sudo apt search nvidia
sudo apt-get -y install nvidia-375
```

### Setup gitconfig_local
To avoid putting email address in a publicly visible file:
```bash
echo '[user]' >> ~/.gitconfig_local
echo -e '\tname = Paul Ewing' >> ~/.gitconfig_local
echo -e '\temail = paul@aol.com' >> ~/.gitconfig_local
ln -s ~/.dotfiles/config/gitconfig_local ~/.gitconfig_local
```

### Install Chromium Extensions
Just open up Chrome/Chromium log in.

#### Setup Screen Configuration
The `xrandr` application can be used to save screen configuration and load it
everytime i3 starts up. To do this, download the arandr package which is a GUI
front-end for xrandr. Run it via the `arandr` command, set up the desired screen
layout, and then save the configuration to `~/.screenlayout/config.sh`. If that
file exists, it will be sourced in the *i3* config.

*Note:* I don't think the *arandr* application exposes a way to mirror displays.
To mirror displays, open up the `~/.screenlayout/config.sh` file and manually
edit it as follows:
```bash
#!/bin/sh

# I have separated each output onto it's own line to help clarify the modifications.

xrandr \
  # My left 1080p DVI monitor.
  --output DVI-D-0 --mode 1920x1080 --pos 0x0 --rotate normal \

  # Here we are setting the HDMI TV to mirror the left DVI monitor.
  # We could use the `--auto` flag instead of `--mode 1920x1080` but when the
  # resolutions don't match it can cause odd behavior with other applications
  # such as feh.
  --output HDMI-0 --mode 1920x1080 --same-as DVI-D-0 \

  # My right 1152p DVI monitor.
  --output DVI-I-1 --primary --mode 2048x1152 --pos 1920x0 --rotate normal \

  --output DVI-I-0 --off \
  --output DP-1 --off \
  --output DP-0 --off
```

#### Wallpapers
The provision script will install my [wpr](https://github.com/pcewing/wpr) app
and it is executed in the `i3` config. It expects the `~/.config/wpr/wprrc.json`
file to exist and look as follows:
```json
{
  "WallpaperDir":"$HOME/Pictures/Wallpapers",
  "DisplayCount":2,
  "Interval":120
}
```
* *WallpaperDir*: Directory containing wallpapers (Or sub-directories)
* *DisplayCount*: The number of displays (Monitors)
* *Interval*: How many seconds to wait in between rotating the wallpapers

