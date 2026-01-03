# Dotfiles

This repository contains my dotfiles!

**TODO:** Add description of new Nix setup. Move manual setup into another doc
file(s) maybe?

## Manual Setup

A few things I haven't bothered to automate.

### Git

Create `~/.gitconfig_local` like:

```
[user]
	email = paul@foo.com
	name = Paul Ewing
```

### Wallpaper Rotater

If using `wpr`, create `~/.config/wpr/config.json` like:

```json
{
    "WallpaperDir": "/home/username/Pictures/Wallpapers",
    "DisplayCount": 1,
    "Interval":120
}
```

### Dual Boot Clock Fix

If dual booting with Windows, set hardware clock to local time:

```bash
timedatectl set-local-rtc 1
```

Without this, clock time in Windows will be off.

### Applications to Manually Install

The following aren't in apt and need to be installed manually:

- Chrome
- Insync
    - https://www.insynchq.com/downloads/linux
    - `insync start`
    - Set sync location to: `$HOME/box`
- Discord
- Visual Studio Code
- Beyond Compare*
- RuneLite*

**Note:** Chrome, Beyond Compare, and RuneLite are availabe in Nix so if we stick with our
Nix configs, those don't need to be manually installed. Discord is available
but given that it stops working the second an update is available, it's
probably easier to just download it via the official `.deb`. Similarly, Insync
is available but there's a known bug with the tray icon not rendering correctly
and since this already requires manual configuration the first time it runs
anyways, installing it manually isn't a big deal.

Alacritty is not yet in the default Ubuntu apt repositories:

```bash
sudo add-apt-repository ppa:mmstick76/alacritty
sudo apt update
```

I rarely use Alacritty due to issues that the developers refuse to fix due to
strange philosophies so eh, maybe just don't install it.

## Theming

**NOTE:** This is not quite accurate after switching to Nix and home-manager.
Now, dotfiles are effectively copied to their target location instead of
symlinked so when `set-theme` updates them, the changes won't take affect until
the next time Nix configuration is applied.

To make it easier to re-theme everything at once, I use
[base16](https://github.com/chriskempson/base16) and
[flavours](https://github.com/Misterio77/flavours). See:

The tl;dr of `base16` is that it is a system for designing color schemes.
`base16` schemes consists of a palette of 16 colors - 8 shades and 8 accents.
Templates can then be created to render the base16 scheme into various config
formats for different applications.

Due to some [turbulence](https://github.com/tinted-theming/home/issues/51) in
the `base16` project, I've added my most used schemes directly to my dotfiles
to avoid things breaking if repositories are ever moved or taken down. I've
also created my own templates rather than using the defaults.

- [schemes](./config/flavours/schemes/custom)
- [templates](./config/flavours/templates/custom/templates)

Using the `flavours` application, these templates are rendered directly into my
dotfiles based on the `flavours` config:

- [flavours/config.toml](./config/flavours/config.toml)

To apply a new color scheme, download and install
[flavours](https://github.com/Misterio77/flavours/releases/latest).

The first time running, update sources. Even if using schemes/templates
committed to my dotfiles, this still appears to be necessary:

```bash
flavours update all
```

**Note:** We should add flavours installation to the provision script.

Once flavours is installed, set the theme using the
[set-theme](./bin/set-theme) script. This not only executes `flavours` but also
reloads config across various applications to smoothly transition themes.

```bash
set-theme <theme-name>
```

The name should match the corresponding base16 scheme yaml file without the
extension. For example:

```bash
flavours apply outrun-dark
```

The official lists of templates and schemes supported by flavours live here:

- https://github.com/chriskempson/base16-schemes-source/blob/main/list.yaml
- https://github.com/chriskempson/base16-templates-source/blob/master/list.yaml

Manual steps after changing themes:

- Reload tmux config
    - `:source-file ~/.tmux.conf`
    - We should figure out how to automate this

### TODO

Some remaining items to tackle in regards to theming:
- Add templates for
    - sway

## Windows 10

**TODO**: This doesn't exist anymore? Fix link...

For setup steps on Windows 10, see:

[windows_setup.md](./windows_setup.md)

### WSL

Some useful things to add to `.localrc` in WSL.

Remove the background highlighting of folders in ls:

```bash
LS_COLORS=$LS_COLORS:'ow=1;34:' ; export LS_COLORS
```

WezTerm shell integration; this adds some useful features like having new tabs
open in the same directory as the previous:
```
if [ "$TERM_PROGRAM" = "WezTerm" ] && [ -f "$HOME/wezterm.sh" ]; then
    source "$HOME/wezterm.sh"
fi
```

For now just manually create and copy the `wezterm.sh` file from here:

https://raw.githubusercontent.com/wez/wezterm/main/assets/shell-integration/wezterm.sh

We could make this a bit nicer by automatically downloading it.
