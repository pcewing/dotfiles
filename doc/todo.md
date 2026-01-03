# To-Do List

Improvements I'd like to make to my dotfiles.

## Table of Contents

- [High Priority](#high-priority)
    - [UltiSnips Freezing Issue](#ultisnips-freezing-issue)
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
- [Neovim](#neovim)
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

### UltiSnips Freezing Issue

**Note:** I'm not sure if this is still a problem after switching to Nix. Maybe wait and see if we still encounter this.

UltiSnips freezes sometimes in Neovim which is really annoying and was marked as won't fix because it's specific to Neovim:

https://github.com/SirVer/ultisnips/issues/1381

We should switch to another snippet plugin, maybe `vim-vsnip` since I see that's what someone else did:

https://github.com/Sangdol/vimrc/commit/b6c5cf06b761b17d5b39c39a2ae9ad584f48761a

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

# Windows Support

- Get the `clean`/`link` commands to work on Windows
- One thing that would be handy is a command to diff the dotfiles against the
  copied locations to see if we updated anything and forgot to backport it into
  the repo
    - Especially now that we're using Nix on Linux so those could get out of sync too

## FZF Bash Integration

**Note:** This statement is not longer accurate since we install fzf via Nix
now; however, I still don't think bash integration is set up so this TODO item
is still valid.

`~/.fzf.bash` doesn't exist for me, maybe because I'm installing via apt. I'd
like that so I can get fzf `ctrl+r` functionality so update the provision
script to set that up correctly.

## Python Tidy/Lint

- [ ] Look into `ruff` since it may replace several other dependencies and also
      claims to be much faster

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

## Old

### I3WM "Virtual Desktops"

**Note:** I don't realistically think this is worth the effort. Even if we ever
get it working, it will probably be time to switch to Wayland shortly after.

10 workspaces isn't always enough. It would be nice to do something that
provides a similar workflow to virtual desktops on Windows. Like, 4 virtual
desktops that each have 10 workspaces. Maybe as an MVP, have a keyboard
shortcut that switches between the desktops and remaps keybindings accordingly.

I've started noodling on a hacky PoC for this in `bin/i3-util.sh`
