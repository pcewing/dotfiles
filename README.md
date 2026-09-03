# Dotfiles

This repository contains my dotfiles and uses Nix and Home Manager for
declarative configuration across my machines.

## Getting Started

- **Ubuntu Setup Instructions:**
    - [setup_ubuntu.md](./doc/setup_ubuntu.md)
- **Windows Setup Instructions:**
    - [setup_windows.md](./doc/setup_windows.md)

## CLI

The `dot` CLI is a Python package (src layout). Install it locally with:

```bash
pip install -e ".[dev]"
```

This installs the `dot` console script (`[project.scripts]` in `pyproject.toml`)
plus `argcomplete` for tab-completion. On Linux, Home Manager also provides
`~/.local/bin/dot`.

## Theme

For details on how theming is set up and how to modify a theme or change the
current theme, see:

[theme.md](./doc/theme.md)
