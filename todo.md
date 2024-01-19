# To-Do List

Improvements I'd like to make to my dotfiles.

## Python CLI

### Bootstrapper

Write a shell script to bootstrap so that `dot` can be run.

### Provisioner Groups or Tags

It would be nice to have "groups" of provisioners so it's easy to
include/exclude a set of features. For example, a group for all of the X11
applications so that they can be excluded when installing on a system without a
DE/WM. Or a group for WSL.

Maybe it would be better to just have tags? So for example I could say:

```
dot provision --tags=wsl ...
```

And then the provisioners could just respect those tags. That's probably easier
actually.

We could also default those tags intelligently by detecting whether or not
we're running in WSL, X11, etc.

Maybe we could even just use tags for distro? Like rather than having separate
library folders for `jammy`, etc. In many cases the distro isn't going to
matter, especially when the only difference is version. If we ever want to
write a provisioner for an entirely different distro like Manjaro, we can
tackle that then but realistically, YAGNI.

Instead of just tags, maybe we expand slightly to "attributes" which are
effectively key-value pairs instead of just values. So we could have attributes
like:

```
distro_family = "ubuntu", "centos"
distro_version = "20.04", 7.9
wsl = true, false
window_manager = "i3", None
desktop_environment = "i3", None
graphical_environment = true, false
```

Then when running, these are all auto-detected but can be overriden via command
line options like so:

```
dot provision --attr "wsl=true"
```

I'll need to make sure `argparse` supports specifying options multiple times
but if not, we can just make the option `--attributes` and expect the value to
be a comma-delimited list.

There are some attributes that we won't be able to default. Like say we want
one that dictates whether or not to install gaming software like `steam`. That
would just have to default to `False` and then if we want that installed we
could either do it manually afterwards by specifying the provisioner:

```
dot provision steam
```

Or add that attribute when provisioning everything:

```
dot provision --all --attr "gaming=true"
```

I think this is the approach I like the best so far.

### Provisioner Command Logging

When provisioners run external commands like `apt update` that generate a lot
of output, it makes the CLI output confusing. Maybe we can dump command output
to a log file so it's hidden during execution and then link to it in the case
of an exception/error?

### Check for Updates Feature

Dry-run is nice for seeing what will happen when I run the script but it would
be even better to have a "Check for updates" command. So I could see if there's
a new version of Neovim for example.

Maybe like a `status` command? So it could be used like:

```
dot provision --status neovim
```

And would output something like:

```
Status:
- Neovim: Up-to-Date (0.9.5)   <-- In green
```

Or:

```
Status:
- Neovim: Update available (0.9.4 -> 0.9.5)  <-- In yellow
```

And could be run for multiple (Or `--all` provisioners):

```
$ dot provision --status --all

Status:
- Neovim: Up-to-Date (0.9.5)   <-- In green
- Flavours: Update available (v0.7.1 -> v0.7.2)   <-- In yellow
```

### Code Cleanup

- Remove the functions like `mkdir_p` in `util.py` and use the alternatives in
  `shell.py`
- Use Python native facilities instead of the functions in `shell.py`
    - These were used so that we could use `sudo` but now the tool just
      elevates itself to root

### Necessary Pip Packages

python3 -m pip install typing_extensions

Also needs to be installed as root if the script elevates
sudo python3 -m pip install typing_extensions

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
