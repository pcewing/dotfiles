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

## Theming

Unfortunately there's not an easy way to retheme everything. When updating
theme, the following files should be considered:

- [config/Xresources](./config/Xresources)
    - This controls the colors in `urxvt` which will also affect all terminal
      applications such as `ncmpcpp`, `neovim`, and `tmux`
- [config/i3](./config/i3)
    - This controls the colors used in `i3` window manager and the default `i3`
      bar
- [config/vimrc](./config/vimrc)
    - This controls the color scheme in `vim` and `neovim`
- [config/dunstrc](./config/dunstrc)
    - This controls the colors used in `dunst` desktop notifications
- [config/py3status.conf](./config/py3status.conf)
    - This controls the colors used in `py3status`, the application that
      populates the `i3` status bar
- [config/tmux.conf](./config/tmux.conf)
    - This controls the color scheme in `tmux`
    - `tmux` uses terminal emulator colors but which color is used for each
      component needs to be configured
- [config/ncmpcpp/config](./config/ncmpcpp/config)
    - This controls the color scheme in `ncmpcpp`
    - `ncmpcpp` uses terminal emulator colors but which color is used for each
      component needs to be configured
- [config/rofi/config.rasi](./config/rofi/config.rasi)
    - This controls the color scheme in `rofi`
- [config/alacritty.yml](./config/alacritty.yml)
    - This controls the color scheme in `alacritty` (Terminal used on Windows)
- [config/polybar](./config/polybar)
    - Not currently necessary but if we switch from the default `i3` status bar
      to `polybar` this would configure its colors
- [config/sway](./config/sway)
    - Not currently necessary but if we switch from `i3` to `sway` this would
      configure its colors
    - Theoretically the config is identical to `i3`; however, we would also
      need to update peripheral applications that don't support Wayland such as Rofi
        - See: https://github.com/swaywm/sway/wiki/i3-Migration-Guide

## Windows 10

For setup steps on Windows 10, see:

[windows_setup.md](./windows_setup.md)
