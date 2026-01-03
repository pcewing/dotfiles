# Ubuntu Setup Instructions

## New Machine Bootstrapping

These are the typical steps to perform immediately after the inital Ubuntu
installation.

Update the system and reboot:
```
sudo apt update -y && sudo apt upgrade -y
shutdown -r now
```

Install Git:
```
sudo apt install -y git
```

Set up an SSH key for Git. There are multiple ways to do this, such as:
- **Option 1:** Generate a new SSH key, log into GitHub in a browser, and add the new key
- **Option 2:** Transfer SSH key from another computer using a flash drive
- **Option 3:** Get SSH key from credential manager

If generating a new SSH key:
```
ssh-keygen -t ed25519 -C "git@pcewing.com"
```

If copying from a flash drive or credential manager, create the files and paste
them in:
```
vi ~/.ssh/id_ed25519
vi ~/.ssh/id_ed25519.pub
```

Add the the SSH key to the agent:
```
chmod 600 ~/.ssh/id_ed25519*
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

If the SSH key was generated, log into GitHub in a browser and add the key in
Settings.

Clone the dotfiles repository:
```
# Clone dotfiles
git clone git@github.com:pcewing/dotfiles.git ~/dot
```

If necessary, check out the desired branch:
```
git checkout my-experimental-branch
```

Configure the host type of the machine so Nix knows how to provision it. For the list of valid host types, see [hosts.json](../nix/hosts.json). The easiest way is to export a `NIX_HOST` variable in `~/.localrc` as follows:
```
echo "export NIX_HOST=\"personal-desktop\"" >> ~/.localrc
```

Apply the dotfiles configuration:
```
cd ~/dot
./apply.sh
```

**Note:** The first time `apply.sh`, nix profile won't be sourced in the active shell. The easiest workaround is to just open a new shell.

**TODO:** We should add a message to the end of the output instructing user to restart shell. We could write a file on the first run and check for its existence on subsequent runs. If it does not exist, prompt the user to restart the computer. Probably not a bad idea on the first bootstrap to make sure everything propogates.

## Daily Operations

After the initial setup, modifications made to dotfiles can be applied via the following alias:
```
df_apply
```

## Manual Setup Steps

### Git

Create `~/.gitconfig_local` like:

```
[user]
	email = paul@foo.com
	name = Paul Ewing
```

### Wallpaper Rotater

If using `wpr`, create `~/.config/wpr/config.json` like:

```json
{
    "WallpaperDir": "/home/username/Pictures/Wallpapers",
    "DisplayCount": 1,
    "Interval":120
}
```

### Dual Boot Clock Fix

If dual booting with Windows, set hardware clock to local time:

```bash
timedatectl set-local-rtc 1
```

Without this, clock time in Windows will be off.

### Applications to Manually Install

The following should be installed manually:

- Chrome
    - Reason: This is in Nix but when I tried using the Nix package, it just
      crashes immediately and I didn't feel like debugging it. Most likely 3D
      acceleration issues like i3wm and kitty had.
- Insync
    - Download URL: https://www.insynchq.com/downloads/linux
    - Setup:
        - `insync start`
        - Remember to set sync location to: `$HOME/box`
    - Reason: Insync is available in Nix but there's a known bug with the tray
      icon not rendering correctly. Given this already requires a fair amount
      of manual setup to authenticate and map desired folders, installing it
      manually is fine.
- Discord
    - Reason: Discord stops working as soon as an upstream update is available
      so it's easier to just install it via the official `.deb` and keep it
      updated that way
- Visual Studio Code
    - Probably could get this from Nix, I just didn't give it a proper go
