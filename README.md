# Dotfiles

This repository contains my dotfiles!

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
- Beyond Compare
- Insync
- Discord
- RuneLite

Alacritty is not yet in the default Ubuntu apt repositories:

```bash
sudo add-apt-repository ppa:mmstick76/alacritty
sudo apt update
```

## Theming

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

For setup steps on Windows 10, see:

[windows_setup.md](./windows_setup.md)
