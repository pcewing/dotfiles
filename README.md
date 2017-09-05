# Dotfiles
This repository contains my dotfiles.

My environment looks like:
![Screenshot](./Screenshot.png)

## Software
For a complete list of the software configured it is best to just look in the
**scripts/provision/ubuntu.sh** provisioning script as the list in the README
would likely become outdated. That being said, my primary development stack
isn't likely to change and it looks like:  

**Local (Graphical) Environment**  
`i3wm` -> `urxvt` -> `zsh` -> `neovim`

**Remote Environment**  
`ssh`-> `tmux` -> `zsh` -> `neovim`

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
Currently Ubuntu is the only Linux distro supported by a provision script. I
don't want to maintain a script for Arch as it would be specific to my hardware
and very seldom used.

### Remote Systems
The majority of the development tools I use are terminal based, which is awesome
given that I commonly work on remote systems or Vagrant VMs via SSH. However,
there are a few pieces of software that are unnecessary on remote systems such
as *urxvt* and *i3wm*.

The *setup* script supports configuring and provisioning systems that do not
need any of the graphical components by specifying the `-r` option.

For example, to configure and provision an Ubuntu system intended for remote
use:
```bash
ssh user@remote.com
git clone https://github.com/pcewing/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup -lprd ubuntu
```

### Manual Steps
I can't (gracefully) automate everything and certain steps require user input or
are machine-specific, so the following should be performed manually.

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
**Static**
To set the wallpaper with a simple GUI tool, install the  `nitrogen` package. It
will let you set the wallpaper for each display independently and save the
setup. You can restore the previously saved setup at any time with the `nitrogen
--restore` command.

**Rotating**
I recently implemented rotating wallpapers so I could take advantage of all of
the cool Blizzard artwork I have saved on my machine. In the *i3config*, if the
*$HOME/Dropbox/Pictures/Wallpapers/Blizzard* directory exists, my wallpaper
rotator tool gets launched with the following command:
```bash
$HOME/.dotfiles/tools/wpr/wpr \
    --wallpaperDir=$HOME/Dropbox/Pictures/Wallpapers/Blizzard \
    --displayCount=2 \
    --interval=300 &
```

That tool lives on Github [here](https://github.com/pcewing/wpr). It is a very
simple .NET core app that just selects random wallpapers from the specified
directory and sets the backgrounds for each display on a specified interval.

## Notes for Myself
* 09/03/2017: Discovered `shotwell`, which is now my favorite photo management
  software on Linux.

