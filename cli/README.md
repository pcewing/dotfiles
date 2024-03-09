# Dotfiles CLI Tool

This is a Python CLI tool for various dotfiles operations.

## Bash Auto-Completion (Requires Python 3.7+)

**TODO:** Add this stuff to provisioner so this is all automatic.

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

The Python files in this repository are all formatted to the PEP8 standard
using the [black](https://black.readthedocs.io/en/stable/).

**TODO:** Install this automatically via provisioner

Install `black` via:

```bash
python -m pip install black
```

Format files via:

```bash
find . -iname '*.py' | xargs black
```
