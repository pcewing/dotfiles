# Dotfiles
My dotfiles.

## My Environment
Over the course of the last year or so I've been making the transition from being heavily reliant on Windows and IDEs for software development. I started off by using VsVim in Visual Studio to familiarize with Vim commands, then moved to Ubuntu and Atom/VsCode for everything but C# .NET development. Fairly recently, I gave up those editors in favor of learning Tmux/Neovim and I've been happy with the decision. Now that I've become (somewhat) more proficient with working my way around Linux via the terminal, I've given up Ubuntu and moved to Arch Linux.

My "development stack" looks like:
* i3wm (With dmenu) - My window manager; I don't use a full desktop environment
* Urxvt - My terminal emulator
* Zsh - My preferred shell
* Tmux - A terminal multiplexer
* Neovim - Text editor

Other software that I use:
* Firefox (With Vimperator) - Best mouse-free browser experience
* Fzf - Fuzzy file finder is awesome
* Ack - A developer-centric grep replacement
* Cmus - A console music player
* Mutt - Text based email client

## Initial Setup and Installation (Arch Linux)
First things first, install a base image of Arch Linux. I can't automate this for you but the [Arch Wiki][ArchWikiInstall] will walk you through it. If you aren't on Arch Linux, you're out of luck and will have to install everything manually.

Once you have an Arch install, the install and link scripts will do most of the work for you. The install script is what I use when I'm imaging a system and thus it will install additional packages I need that you may not want. Use it at your own discretion.

CAUTION: The install script installs the graphics drivers that match my graphics card at home; remove/edit those lines if your card requires a different driver!
```bash
sudo pacman -S git
git clone https://github.com/pcewing/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
scripts/install.sh
```

### Manual Steps
I can't (gracefully) automate everything, so the following steps should be performed manually.

#### Install Neovim Plugins
This can be done after launching Neovim by executing the command:
```
:PlugInstall
```
...or from the command line via:
```bash
nvim +PlugInstall +qa
```

## TODOs

* Learn how to use cmus better then commit a cmus config file
* Learn how to use mutt email client better

# Screenshots

This is what my environment looks like:
![Screenshot](./Screenshot.png)

# Credits
Big thanks to Nick Nisi as I learned a lot from [his dotfiles repo][NickNisiDotfiles] and made some of it my own!

[NickNisiDotfiles]: <https://github.com/nicknisi/dotfiles>
[ArchWikiInstall]: <https://wiki.archlinux.org/index.php/installation_guide>
[DiffSoFancy]: <https://github.com/so-fancy/diff-so-fancy>
[NpmGlobal]: <https://docs.npmjs.com/getting-started/fixing-npm-permissions>
