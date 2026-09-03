# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A dotfiles management system declaratively configured with Nix and Home Manager.
It supports Linux host types (desktop, server, WSL) plus a Windows bootstrap
path. App configs live in `config/` and are linked into the home directory by
Home Manager on Linux, or copied (marked read-only) on Windows.

There is no test suite, so "run a single test" does not apply.

## Common Commands

### Fresh Install (bootstrap)

```bash
./apply.sh --nix-host <host-name>
# e.g. ./apply.sh --nix-host personal-desktop
```

Installs Nix, enables flakes, and applies Home Manager. It also handles
system-level tasks intentionally left out of Nix (apt bootstrap packages,
Docker + group, session desktop files, `update-alternatives`). Options:
`--dir`, `--no-upgrade`, `--no-apt`, `--reset-state`. Host names come from
`nix/hosts.json`.

### Apply Config Changes

```bash
home-manager switch --flake ~/dot/nix#<host-name>
```

### Deprovision Pre-Nix Hosts

```bash
./unprovision.sh
```

Removes packages the old (now-deleted) shell/Python provisioners installed, so
a host can be re-provisioned with Nix. See `doc/nix_todos.md` for migration
parity status.

### Python CLI (`dot`)

Home Manager generates `~/.local/bin/dot`, a wrapper that runs `cli/dot.py`
with the unified Python environment. Subcommands:

- `dot link` / `dot clean` — create/remove symlinks from `links.json` (legacy)
- `dot tidy [FILES]` — format Python (black + isort + autoflake); `-d/--dry-run`
- `dot lint [FILES]` — lint Python
- `dot git-sync` — sync the current repo with a remote (`-d/--dry-run`, `-v`)
- `dot status` — print dotfile repo status
- `dot fd <choose|add|edit|update>` — fzf directory registry
- Global `-l/--log-level debug|info|warn|error|crit`

### Type Checking / Formatting

```bash
make mypy      # type-check all Python files
make nixfmt    # format all .nix files (runs in a nix-shell)
make link|clean|windows   # legacy dot.sh targets
```

### Theming

```bash
flavours update all   # required first-time setup
set-theme <scheme>    # apply a base16 scheme, e.g. outrun-dark
```

Full details in `doc/theme.md`.

## Architecture

### Nix configuration (`nix/`)

`flake.nix` is the entry point: it reads `hosts.json` and, for each host, maps
its `roles` list to modules at `home/roles/<role>.nix` (`core`, `desktop`,
`gaming`, `wsl`). Adding a host or role means editing `hosts.json` and creating
a role file — the flake picks it up automatically.

- `home/lib/` — shared modules imported by roles:
  - `dotfiles-links.nix` — **source of truth** for mapping `config/` files into
    the home directory (via `home.file` / `xdg.configFile`). `links.json` is the
    legacy equivalent still used by `dot link`/`dot clean`; they can drift.
  - `python-environment.nix` — builds a unified Python env from the
    `myPython.packageFns` option. To add Python deps, add a `ps: with ps; [ ... ]`
    function to a role's `myPython.packageFns` list (see `core.nix`).
- `home/features/` — optional modules enabled by roles (e.g. `development.nix`).
- `home/packages/` — custom derivations pulled in via `pkgs.callPackage`.

`core.nix` also declares the `dot` wrapper, argcomplete, and a
`home.activation.flavoursUpdate` hook.

### Config files (`config/`)

Application configs that Home Manager links into the home directory: `bash/`,
`nvim/`, `i3`, `sway`, `kitty.conf`, `wezterm.lua`, `flavours/` (base16 schemes
and templates). The names here map to destinations in `dotfiles-links.nix`.

### Python CLI (`cli/`)

`dot.py` is the argparse entry point; `commands/__init__.py` registers each
subcommand. Each subcommand is a module exposing `add_<name>_parser(subparsers)`
that sets a `func` default. Shared logic lives in `cli/lib/common/` (git, log,
links, linter, shell, etc.).

### Utility scripts (`bin/`)

Standalone scripts not managed by Nix: `set-theme`, `i3-util.sh`, `startup.sh`,
`fuzzy-fm`, and assorted helpers. Some are Python.

### Bootstrap / docs

- `apply.sh` — bootstrap for fresh Linux installs; the pre-Nix and root-requiring
  half of provisioning (see `doc/nix_todos.md` for exactly what stays here).
- `dot.sh` — legacy `windows` path: copies `config/` files read-only instead of
  symlinking (Windows symlinks need admin rights).
- `doc/` — `setup_ubuntu.md`, `setup_windows.md`, `theme.md`, `todo.md`,
  `nix_todos.md` (Nix migration status).

## Code Style

Python uses black, isort, and autoflake — run `dot tidy` before committing Python
changes. Type hints are encouraged; validate with `make mypy`. Nix files are
formatted with `make nixfmt`.
