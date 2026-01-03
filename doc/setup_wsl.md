### WSL

**TODO:** Make a `config/wslrc` file that gets linked to `~/.wslrc` and then have `bashrc` conditionally source it if we are running in WSL. Put the stuff below into `wslrc` so this is all automatically set up by Nix.

**TODO:** Add a Nix activation script to download the `wezterm.sh` file.

Some useful things to add to `.localrc` in WSL.

Remove the background highlighting of folders in ls:

```bash
LS_COLORS=$LS_COLORS:'ow=1;34:' ; export LS_COLORS
```

WezTerm shell integration; this adds some useful features like having new tabs
open in the same directory as the previous:
```
if [ "$TERM_PROGRAM" = "WezTerm" ] && [ -f "$HOME/wezterm.sh" ]; then
    source "$HOME/wezterm.sh"
fi
```

For now just manually create and copy the `wezterm.sh` file from here:

https://raw.githubusercontent.com/wez/wezterm/main/assets/shell-integration/wezterm.sh

We could make this a bit nicer by automatically downloading it.
