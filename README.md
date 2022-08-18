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
