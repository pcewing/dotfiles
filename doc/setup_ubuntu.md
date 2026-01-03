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

The following aren't in apt and need to be installed manually:

- Chrome
- Insync
    - https://www.insynchq.com/downloads/linux
    - `insync start`
    - Set sync location to: `$HOME/box`
- Discord
- Visual Studio Code
- Beyond Compare*
- RuneLite*

**Note:** Chrome, Beyond Compare, and RuneLite are availabe in Nix so if we stick with our
Nix configs, those don't need to be manually installed. Discord is available
but given that it stops working the second an update is available, it's
probably easier to just download it via the official `.deb`. Similarly, Insync
is available but there's a known bug with the tray icon not rendering correctly
and since this already requires manual configuration the first time it runs
anyways, installing it manually isn't a big deal.

Alacritty is not yet in the default Ubuntu apt repositories:

```bash
sudo add-apt-repository ppa:mmstick76/alacritty
sudo apt update
```

I rarely use Alacritty due to issues that the developers refuse to fix due to
strange philosophies so eh, maybe just don't install it.

## WSL

See [setup_wsl.md][./setup_wsl.md].
