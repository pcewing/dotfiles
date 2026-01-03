# To-Do List

Improvements I'd like to make to my dotfiles.

## Table of Contents

- [High Priority](#high-priority)
- [Misc](#misc)
- [Python CLI](#python-cli)
    - [Bootstrapper](#bootstrapper)
    - [Provisioner Groups or Tags](#provisioner-groups-or-tags)
    - [Provisioner Command Logging](#provisioner-command-logging)
    - [Check for Updates Feature](#check-for-updates-feature)
    - [Code Cleanup](#code-cleanup)
    - [Necessary Pip Packages](#necessary-pip-packages)
- [FZF Bash Integration](#fzf-bash-integration)
- [Windows support in Python CLI](#windows-support-in-python-cli)
- [wezterm shell integration](#wezterm-shell-integration)
- [I3WM "Virtual Desktops"](#i3wm-"virtual-desktops")
- [Python Tidy/Lint](#python-tidy/lint)
- [Don't symlink vim to neovim](#don't-symlink-vim-to-neovim)
- [Neovim Healtheck](#neovim-healtheck)
- [Errors](#errors)
    - [nvim-lua/completion-nvim](#nvim-lua/completion-nvim)
    - [nvim-telescope/telescope.nvim](#nvim-telescope/telescope.nvim)
- [Warnings](#warnings)
    - [glepnir/lspsaga.nvim](#glepnir/lspsaga.nvim)
    - [nvim-treesitter/nvim-treesitter](#nvim-treesitter/nvim-treesitter)
    - [Providers](#providers)
    - [nvim-telescope/telescope.nvim](#nvim-telescope/telescope.nvim)
    - [neovim/nvim-lspconfig](#neovim/nvim-lspconfig)

**IMPORTANT NOTE:** A lot of the items in this file may be obsolete with the new Nix setup. Basically everything provisioner related is and I'm sure some other things are as well. We should go through and clean this up so that it's up-to-date.

## High Priority

UltiSnips freezes sometimes in Neovim which is really annoying and was marked as won't fix because it's specific to Neovim:

https://github.com/SirVer/ultisnips/issues/1381

We should switch to another snippet plugin, maybe `vim-vsnip` since I see that's what someone else did:

https://github.com/Sangdol/vimrc/commit/b6c5cf06b761b17d5b39c39a2ae9ad584f48761a

## Misc

- [ ] Clean up Neovim Healthcheck (**Neovim Healtheck** section)
- [ ] Change path address bar behavior in Nautilus?
    - `dconf write /org/gnome/nautilus/preferences/always-use-location-entry true`
    - Not sure if I actually like this, just need to remember the `Ctrl + l` hotkey

## XP Submodule

Use `xp` as a submodule to DRY our Python.

## Python CLI

### Git Sync Command

Implement a simple `dot git-sync` command and a git alias to it like `git sync`
that does something like:

```
- Check if there are commits missing from upstream
- If there are, pull
- If there are merge conflicts, abort and print an error
    - These should be handled manually
- If the merge is clean, continue on
- Add all local changes
- Commit local changes
- Push
```

This is for repositories like my notes where I basically just always want to
keep everything in sync and don't use branches. Optionally, accept a parameter
for commit message.

#### Progress

I started on this but it probably isn't bullet-proof yet. What it does:

- If there are local changes that need to be committed
    - Create a temporary branch and resolve/commit the changes in it
    - This is a bit complicated and might be bug prone
- Fetch from all remotes
- Detect the most recent matching commit between the local and remote
- Get the number of commits the local repository is missing from remote and
  vice versa
- Pull remote commits if there are any missing from local
- If there were local changes, cherry-pick them from the temp branch
- If remote is missing any local commits, push

One thing I might want to change is to push the temporary branch to remote. I
just encountered an issue where I ran the sync command on my desktop PC and I
think it errored and I forgot to go back and resolve it. Now, working on my
laptop, I'm missing those changes. Had I at least pushed the temp branch, I
could have pulled it down and fixed it on my laptop but since I'm travelling
I'm just out of luck.

### Provisioner Output

Better display which provisioners passed, failed, or didn't run because right
now if something fails half-way through it's very annoying to figure out where
to start again. GitHub's rate limiting seems pretty aggressive so re-running
the whole thing fails due to 403 errors.

### Implement More Provisioners

Add a "proprietary" tag for:

- Insync
- Beyond Compare 4 / 5
- Parsec

### Logging Noise

We should change most of the logs to debug to reduce noise in the output.

### Bootstrapper

- Write a shell script to bootstrap so that `dot` can be run.
    - [ ] Maybe put bootstrapper in a Gist so it's easier to grab on a new
          system and have it set up git ssh keys, clone the dotfiles repo, etc?

- Things it needs:
    - Install Python and pip packages
        - `python -m pip install --user --upgrade argcomplete`

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

### Windows Support

- Don't need to implement full provisioning but at least get clean/link commands to work on Windows
- Might be nice to have a script to provision WezTerm on Windows
- Remove dot.sh and Makefile (Except maybe for bootstrapping)

- Make sure the following is added to path before running `dot provision cli`
    - `C:\Users\pewing\AppData\Roaming\Python\Python310\Scripts`
    - Update version in the path as necessary
    - Tools install via Pip aren't automatically added to PATH like they are on Linux
    - TODO: Actually this is just broken altogether, the following fails when run directly in Git Bash:
        - `register-python-argcomplete --external-argcomplete-script $HOME/dot/cli/dot.py dot`
        - So it may just not play nicely with windows
        - For now, maybe just copy it from Linux and update the paths?


## FZF Bash Integration

`~/.fzf.bash` doesn't exist for me, maybe because I'm installing via apt. I'd
like that so I can get fzf `ctrl+r` functionality so update the provision
script to set that up correctly.

## wezterm shell integration

Automatically download wezterm.sh and source it in ~/.localrc or at least document this for WSL setup

## I3WM "Virtual Desktops"

10 workspaces isn't always enough. It would be nice to do something that
provides a similar workflow to virtual desktops on Windows. Like, 4 virtual
desktops that each have 10 workspaces. Maybe as an MVP, have a keyboard
shortcut that switches between the desktops and remaps keybindings accordingly.

I've started noodling on a hacky PoC for this in `bin/i3-util.sh`

## Python Tidy/Lint

- [ ] Look into `ruff` since it may replace several other dependencies and also
      claims to be much faster
- [ ] Set up a pre-commit hook to ensure files are always linted?
    - [ ] Probably can't do this without significant work to fix all static
          typing

## Don't symlink vim to neovim

Now that we've split our configs let's not link `vi` and `vim` to Neovim.

## Neovim Healtheck

- In nvim, run `:healthcheck` and go through the errors/warnings:

### Errors

#### nvim-lua/completion-nvim

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

#### nvim-telescope/telescope.nvim

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

### Warnings

#### glepnir/lspsaga.nvim

```
==============================================================================
lspsaga: require("lspsaga.health").check()

Lspsaga.nvim report ~
- WARNING `tree-sitter` executable not found 
- OK tree-sitter `markdown` parser found
- OK tree-sitter `markdown_inline` parser found
```

#### nvim-treesitter/nvim-treesitter

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

#### Providers

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

#### nvim-telescope/telescope.nvim

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

#### neovim/nvim-lspconfig

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

# Other TODOs (From 2025-01-03)

- On multi-monitor setups, run arandr and set up a TODO.sh file
- Set up background wallpaper or whatever will manage it
    - Maybe just `nitrogen --restore &` ?
    - Can we put an svg in github repo and convert it to png or something?
        - So it's text on disk and small in size but then we have a default wallpaper everywhere
- Move base16-shell installation out of bashrc maybe?
    - Have nix do this? With current system, it will never update after first installation and it feels weird to have shell init scripts cloning git repositories
- nixfmt
- Maybe we can merge some of the shell scripts i3 executes into a single shell script so they can all share the same logging and debugging facilities?
- bcompare in nix is Beyond Compare 4, is it possible to get 5?
- Are we forgetting to execute gtk stuff on i3 startup? Keyring, etc.
    - Notice how long it takes `gnome-text-editor` to run; maybe it's a snap?
    - Also look at some errors in terminal when running Firefox, Nitrogen, etc.

- Rust App ideas
    - Wallpaper setter?
    - Cheat sheet viewer
    - Tray icon with reminders about pending local git changes

- .gitconfig_local
    - Can we just make a new email solely for git that we can put in the public repo?
        - Like, `git@pcewing.com`?
