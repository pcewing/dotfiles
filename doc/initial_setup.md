# Notes taken while setting up Laptop on 2026-01-01

```
# Install Git
sudo apt install -y git

# Paste in SSH key
vi ~/.ssh/id_ed25519
vi ~/.ssh/id_ed25519.pub

# Add SSH key to agent
chmod 700 ~/.ssh/id_ed25519*
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Clone dotfiles
git clone git@github.com:pcewing/dotfiles.git dot

# Export NIX_HOST variable in .localrc file. Replace personal-desktop with the
# appropriate host type.
echo "export NIX_HOST=\"personal-desktop\"" >> ~/.localrc
```

# Notes from fresh install of Ubuntu 24.04 on main gaming desktop on 2026-01-03

sudo apt -y update && sudo apt -y upgrade

# [Get SSH key]
# Option 1) Generate a new SSH key, log into GitHub in a browser, and add the new key
# Option 2) Transfer SSH key from another computer using a flash drive
# Option 3) (Not set up yet) Get SSH key from either Google Drive or KeePass

# For this run, I went with option 2
# Add ssh key to agent
eval "$(ssh-agent -s)"
chmod 600 ~/.ssh/id_ed*
ssh-add ~/.ssh/id_ed25519

# Install git
sudo apt install -y git

# Clone dotfiles
git clone git@github.com:pcewing/dotfiles.git ~/dot

# Checkout branch if necessary
git checkout nix-noble

# Apply dotfiles (TODO: Change "bootstrap.sh" to "apply.sh")
echo "export NIX_HOST=\"personal-desktop\"" >> ~/.localrc
cd ~/dot
./bootstrap.sh

# On the first time this is run, nix profile won't be sourced. The bootstrap.sh script can't source it for the user so a TODO is either:
# 1) Add a message to the end of the output telling user to start a new terminal emulator
# 2) We could write a file on the first run and check for its existence on subsequent runs. If it does not exist, prompt the user to restart the computer. Probably not a bad idea on the first bootstrap to make sure everything propogates.




# Other TODOs:
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

- .gitconfig_local
    - Can we just make a new email solely for git that we can put in the public repo?
        - Like, `git@pcewing.com`?
