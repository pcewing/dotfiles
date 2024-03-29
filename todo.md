# To-Do List

Improvements I'd like to make to my dotfiles.

- [ ] Detect WSL in Neovim/provisionar/etc
    - [ ] Just look for a `WSL_DISTRO_NAME` environment variable
- [ ] Python CLI with shell bootstrapper
    - [ ] Maybe put bootstrapper in a Gist so it's easier to grab on a new
          system and have it set up git ssh keys, clone the dotfiles repo, etc?
- [ ] Split Vim and Neovim configs and make Neovim all lua
- [ ] Clean up Neovim Healthcheck (**Neovim Healtheck** section)

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

## Neovim Healtheck

- In nvim, run `:healthcheck` and go through the errors/warnings:

## Errors

### nvim-lua/completion-nvim

```
completion: require("completion.health").check()

- ERROR Failed to run healthcheck for "completion" plugin. Exception:
  function health#check, line 25
  Vim(eval):E5108: Error executing lua [string "luaeval()"]:1: attempt to call field 'check' (a nil value)
  stack traceback:
  [string "luaeval()"]:1: in main chunk

==============================================================================
completion_nvim: health#completion_nvim#check

general ~
- OK neovim version is supported

completion source ~
- OK all completion sources are valid

snippet source ~
- ERROR Your snippet source is not available! Possible values are: UltiSnips, Neosnippet, vim-vsnip, snippets.nvim
```

### nvim-telescope/telescope.nvim

```
==============================================================================
telescope: require("telescope.health").check()

Checking for required plugins ~
- OK plenary installed.
- OK nvim-treesitter installed.

Checking external dependencies ~
- ERROR rg: not found. `live-grep` finder will not function without [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) installed.
- WARNING fd: not found. Install [sharkdp/fd](https://github.com/sharkdp/fd) for extended capabilities

===== Installed extensions ===== ~
```

## Warnings

### glepnir/lspsaga.nvim

```
==============================================================================
lspsaga: require("lspsaga.health").check()

Lspsaga.nvim report ~
- WARNING `tree-sitter` executable not found 
- OK tree-sitter `markdown` parser found
- OK tree-sitter `markdown_inline` parser found
```

### nvim-treesitter/nvim-treesitter

```
==============================================================================
nvim-treesitter: require("nvim-treesitter.health").check()

Installation ~
- WARNING `tree-sitter` executable not found (parser generator, only needed for :TSInstallFromGrammar, not required for :TSInstall)
- WARNING `node` executable not found (only needed for :TSInstallFromGrammar, not required for :TSInstall)
- OK `git` executable found.
- OK `cc` executable found. Selected from { vim.NIL, "cc", "gcc", "clang", "cl", "zig" }
  Version: cc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0
- OK Neovim was compiled with tree-sitter runtime ABI version 14 (required >=13). Parsers must be compatible with runtime ABI.
```

### Providers

Is there a way we can say we intentionally don't want these providers to get
the warnings to go away?

```
==============================================================================
provider: health#provider#check

Ruby provider (optional) ~
- WARNING `ruby` and `gem` must be in $PATH.
  - ADVICE:
    - Install Ruby and verify that `ruby` and `gem` commands work.

Node.js provider (optional) ~
- WARNING `node` and `npm` (or `yarn`, `pnpm`) must be in $PATH.
  - ADVICE:
    - Install Node.js and verify that `node` and `npm` (or `yarn`, `pnpm`) commands work.

Perl provider (optional) ~
- WARNING "Neovim::Ext" cpan module is not installed
  - ADVICE:
    - See :help |provider-perl| for more information.
    - You may disable this provider (and warning) by adding `let g:loaded_perl_provider = 0` to your init.vim
```

### nvim-telescope/telescope.nvim

```
==============================================================================
telescope: require("telescope.health").check()

Checking for required plugins ~
- OK plenary installed.
- OK nvim-treesitter installed.

Checking external dependencies ~
- ERROR rg: not found. `live-grep` finder will not function without [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) installed.
- WARNING fd: not found. Install [sharkdp/fd](https://github.com/sharkdp/fd) for extended capabilities

===== Installed extensions ===== ~
```

### neovim/nvim-lspconfig

```
==============================================================================
vim.lsp: require("vim.lsp.health").check()

- LSP log level : TRACE
- WARNING Log level TRACE will cause degraded performance and high disk usage
- Log path: /home/pewing/.local/state/nvim/lsp.log
- Log size: 333 KB

vim.lsp: Active Clients ~
- No active clients
```
## win32yank-wsl

Add this to provision scripts?

## Add utils to provision python 

Install `black` in provision script

## fzf_cached_wsl -> Python

Convert this to Python which will make killing existing processes easier

## Windows support in Python CLI

Don't need to implement provisioning but at least get clean/link commands to work on Windows

## wezterm shell integration

Automatically download wezterm.sh and source it in ~/.localrc or at least document this for WSL setup

## Pip packages

- Install:
    - `black`
    - `argcomplete`
        - For `dot` CLI auto-completion

## I3WM "Virtual Desktops"

10 workspaces isn't always enough. It would be nice to do something that
provides a similar workflow to virtual desktops on Windows. Like, 4 virtual
desktops that each have 10 workspaces. Maybe as an MVP, have a keyboard
shortcut that switches between the desktops and remaps keybindings accordingly.

I've started noodling on a hacky PoC for this in `bin/i3-util.sh`
