# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A dotfiles management system with a hybrid provisioning approach:

- `bootstrap.sh` — plain Bash. Installs the minimum needed to run the `dot`
  CLI and creates the `.venv` virtualenv.
- `dot provision` — Python provisioners that install everything else
  (apt packages, pip tools, Docker, version-tracked binaries, system config,
  and dotfile links).

It supports Linux host types (desktop, server, WSL) plus a Windows bootstrap
path. App configs live in `config/` and are linked into the home directory by
the `links` provisioner from `links.json`, or copied (marked read-only) on
Windows.

There is no test suite, so "run a single test" does not apply.

## Common Commands

### Fresh Install

```bash
./bootstrap.sh
source .venv/bin/activate
dot provision --host <host-name>
# e.g. dot provision --host personal-desktop
```

Host names and their tags come from `hosts.json`. `DOT_HOST` may be set in
`~/.localrc` to avoid passing `--host`.

### Apply Config Changes

```bash
dot provision links        # only re-create symlinks
```

### Deprovision a Nix Host

```bash
./deprovision-nix.sh
```

Removes the Home Manager generated files and replaces store symlinks with links
into this repository. See `provision_analysis.md` for the migration analysis.

### Python CLI (`dot`)

`bootstrap.sh` installs the package editable into `.venv`. Subcommands:

- `dot provision [components]` — run provisioners (`--dry-run`, `--host`, `-t/--tags`, `--upgrade`, `--no-update`, `--no-version-cache`)
- `dot links <init|clean|diff|backport>` — manage dotfile links from `links.json`; `diff`/`backport` are Windows-only
- `dot tidy [FILES]` — format Python (black + isort + autoflake); `-d/--dry-run`
- `dot lint [FILES]` — lint Python
- `dot git-sync` — sync the current repo with a remote (`-d/--dry-run`, `-v`)
- `dot status` — print dotfile repo status
- `dot fd <choose|add|edit|update|remove|prune>` — fzf directory registry
- Global `-l/--log-level debug|info|warn|error|crit`

### Type Checking / Formatting

```bash
make mypy      # type-check all Python files
make bootstrap # run ./bootstrap.sh
make provision # run .venv/bin/dot provision
```

Python uses black, isort, and autoflake — run `dot tidy` before committing
Python changes. Type hints are encouraged; validate with `make mypy`.

## Architecture

### Bootstrap (`bootstrap.sh`)

Installs the prerequisite apt packages (Python, build tools, download tools),
creates `${DOTFILES}/.venv`, and installs the `dot` package editable into it.
Keep this list small; everything else belongs in a provisioner. Options:
`--dir`, `--venv`, `--no-update`, `--provision`.

### Provisioners (`src/dot/lib/provision/`)

- `provisioner.py` — `ProvisionerArgs` and the provisioner interfaces.
- `tag.py` — `x11`, `wsl`, and `gaming` tags plus auto-detection.
- `system_provisioner.py` — component registry and ordered execution.
- `provisioner_*.py` — one module per component.

`dot provision` runs components in registry order, so dependencies are honored:
`apt` first (installs packages other components need), then `pip`, development
toolchains, version-tracked tools, `links`, `dot` completion, `wsl`, `system`
(sets `update-alternatives` for the `neovim`/`kitty` binaries), `docker`, and
`win32yank`.

Components use the shared helpers in `src/dot/lib/common/` (`apt.py`,
`pip.py`, `github.py`, `archive.py`, `shell.py`, `alternatives.py`,
`version_cache.py`, etc.). The version-tracked components cache the latest
release in `version_cache.json5` (gitignored) so GitHub lookups are not
repeated on every run.

To add a component: create `provisioner_<name>.py` implementing
`IComponentProvisioner`, then register it in `_COMPONENT_PROVISIONERS` in
`system_provisioner.py`.

### Host profiles (`hosts.json`)

Maps each machine name to a list of tags. `dot provision --host <name>` (or
`DOT_HOST`) resolves those tags; `-t/--tags` overrides them, and with neither
the tags are auto-detected.

### Dotfile links (`links.json`)

Source of truth for mapping `config/` files into the home directory. The
`links` provisioner and `dot links init/clean` both use it. Add new dotfiles
here and run `dot provision links`.

### Config files (`config/`)

Application configs that get linked into the home directory: `bash/`, `nvim/`,
`i3`, `sway`, `kitty.conf`, `wezterm.lua`, `alacritty/`, `flavours/` (base16
schemes and templates). The names here map to destinations in `links.json`.

### Python CLI (`src/dot/`)

`cli/cli.py` is the argparse entry point (`dot = "dot.cli.cli:main"` in
`pyproject.toml`) and registers each subcommand. Each subcommand is a module or
subpackage in `src/dot/cli/` exposing `add_<name>_parser(subparsers)` that sets
a `func` default. Shared logic lives in `src/dot/lib/common/`.

### Utility scripts (`bin/`)

Standalone scripts not managed by provisioning: `set-theme`, `i3-util.sh`,
`startup.sh`, `fuzzy-fm`, and assorted helpers. Some are Python.

### Docs

- `doc/` — `setup_ubuntu.md`, `setup_windows.md`, `theme.md`, `todo.md`.
- `provision_analysis.md` — inventory and analysis of the former Nix/Home
  Manager setup (historical reference for the migration).
