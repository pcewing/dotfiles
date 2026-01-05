# Dotfiles CLI Tool

This is a Python CLI tool for various dotfiles operations.

## Bash Auto-Completion (Requires Python 3.7+)

The CLI supports auto-completion via `argcomplete` and it should be configured
automatically by Nix home-manager.

## Code Formatting

The Python files in this repository are all formatted using a few tools:

- [autoflake](https://github.com/PyCQA/autoflake): Removes unused imports
- [isort](https://github.com/PyCQA/isort): Sorts imports
- [black](https://black.readthedocs.io/en/stable/): Formats code

The `dot tidy` CLI command will run these on the Python files in the
repository.
