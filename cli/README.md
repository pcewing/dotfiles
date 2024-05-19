# Dotfiles CLI Tool

This is a Python CLI tool for various dotfiles operations.

## Bash Auto-Completion (Requires Python 3.7+)

The `DotProvisioner` in the CLI automatically sets up Bash auto-completion so just run:

```bash
dot provision
```

Or:

```bash
dot provision dot
```

### Manual Setup

Install the `argcomplete` python package:

```bash
python -m pip install argcomplete
```

Generate the auto-completion script:

```bash
export DOT_BASH_COMPLETION="1"
mkdir -p ~/.bash_completion.d
echo "$(
    register-python-argcomplete --external-argcomplete-script $DOTFILES/cli/dot.py dot
)" &>~/.bash_completion.d/dot.bash
```

Add this to `.bashrc` or similar:

```bash
export DOT_BASH_COMPLETION="1"
source "$HOME/.bash_completion.d/dot.bash"
```

Reload shell config and the auto-completion script should be sourced into the
shell automatically.

## Code Formatting

The Python files in this repository are all formatted using a few tools:

- [autoflake](https://github.com/PyCQA/autoflake): Removes unused imports
- [isort](https://github.com/PyCQA/isort): Sorts imports
- [black](https://black.readthedocs.io/en/stable/): Formats code

The `dot tidy` CLI command will run these on the Python files in the
repository.
