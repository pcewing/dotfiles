# Dotfiles
My dotfiles.

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
./setup -lpd arch
```
This will link the configuration files and provision all necessary software/packages for an Arch system.

### Supported Platforms
Currently only Arch Linux and Ubuntu are supported, although I wouldn't recommend using the Arch script yourself (At least not without grooming it first). Given that Debian uses the same package manager, you may be able to use the Ubuntu script on Debian systems; however, I have not tested this nor do I currently have any plans for supporting that platform.

The Arch provisioning script installs some packages specific to the hardware on my home PC such as the Nvidia graphics driver as well as some additional packages that may not be necessary for everyone.

### Remote Systems
The majority of the development tools I use are terminal based, which is awesome given that I commonly work on remote systems via SSH. However, there are a pieces of software that are unnecessary on remote systems such as *urxvt* and *i3wm*.

The *setup* script supports configuring and provisioning systems that do not need any of the graphical components by specifying the `-r` option.

For example, to configure and provision an Ubuntu system intended for remote use:
```bash
ssh user@remote.com
git clone https://github.com/pcewing/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup -lprd ubuntu
```

### Manual Steps
I can't (gracefully) automate everything and certain steps require user input, so the following should be performed manually.

#### Set Default Shell
```bash
chsh -s $(which zsh)
```

#### Set Default Terminal (Ubuntu)
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

# Screenshots

This is what my environment looks like:
![Screenshot](./Screenshot.png)
