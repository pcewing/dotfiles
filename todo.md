# To-Do List

Improvements I'd like to make to my dotfiles.

## Install ripgrep

This is a requirement for live grep in the Telescope Neovim plugin so we should
make sure it's always installed.

Just download the `.deb` from the latest release and install it in `/opt` like
we do for other tools:

```
https://github.com/BurntSushi/ripgrep/releases/tag/14.1.0
```

```
ripgrep_14.1.0-1_amd64.deb
```

## FZF Bash Integration

`~/.fzf.bash` doesn't exist for me, maybe because I'm installing via apt. I'd
like that so I can get fzf `ctrl+r` functionality so update the provision
script to set that up correctly.
