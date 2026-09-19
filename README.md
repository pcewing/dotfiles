# Dotfiles

This repository contains my dotfiles and a hybrid Bash + Python provisioning
system. A small `bootstrap.sh` installs just enough to run the `dot` CLI, and
the Python provisioners in `src/dot/lib/provision/` install everything else.

## Getting Started

On a fresh Ubuntu (or WSL) machine, clone the repo and run:

```bash
./bootstrap.sh
source .venv/bin/activate
dot provision --host <host-name>
```

`bootstrap.sh` installs the prerequisites needed to run the `dot` CLI and
creates the `.venv` virtualenv with the `dot` package installed. `dot provision`
installs everything else (apt packages, Python tools, Docker, version-tracked
tools, system configuration, dotfile links).

Host profiles live in [hosts.json](./hosts.json). Set `DOT_HOST` in
`~/.localrc` to avoid passing `--host` each time:

```bash
echo 'export DOT_HOST="personal-desktop"' >> ~/.localrc
```

- **Ubuntu Setup Instructions:** [setup_ubuntu.md](./doc/setup_ubuntu.md)
- **Windows Setup Instructions:** [setup_windows.md](./doc/setup_windows.md)

## Provisioning

| Command | Purpose |
|---------|---------|
| `./bootstrap.sh` | Install prerequisites and the `dot` CLI into `.venv` |
| `dot provision` | Install/configure everything else |
| `dot provision --dry-run` | Show what provisioning would do |
| `dot provision --host <name>` | Use the tags from a `hosts.json` profile |
| `dot provision -t x11,gaming` | Use explicit tags instead of a host |
| `dot provision --upgrade` | Also run `apt-get dist-upgrade` |
| `dot links init` | Create the dotfile symlinks described by `links.json` |

`dot provision` is idempotent: components detect what is already installed and
skip it. Available components are listed by:

```bash
dot provision --help
```

## CLI

The `dot` CLI is a Python package (src layout). `bootstrap.sh` installs it
editable into `.venv`; to do it manually:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

This installs the `dot` console script (`[project.scripts]` in
`pyproject.toml`) plus `argcomplete` for tab-completion.

## Theme

For details on how theming is set up and how to modify a theme or change the
current theme, see:

[theme.md](./doc/theme.md)
