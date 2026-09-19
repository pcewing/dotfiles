# Ubuntu Setup Instructions

## New Machine Bootstrapping

These are the typical steps to perform immediately after the initial Ubuntu
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

Add the SSH key to the agent:

```
chmod 600 ~/.ssh/id_ed25519*
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

If the SSH key was generated, log into GitHub in a browser and add the key in
Settings.

Clone the dotfiles repository:

```
git clone git@github.com:pcewing/dotfiles.git ~/dot
```

If necessary, check out the desired branch:

```
git checkout my-experimental-branch
```

Bootstrap the machine. This installs the prerequisites needed to run the `dot`
CLI and creates the `.venv` virtual environment:

```
cd ~/dot
./bootstrap.sh
```

Configure the host profile so `dot provision` knows which tags to use. For the
list of valid host profiles, see [hosts.json](../hosts.json). The easiest way is
to export a `DOT_HOST` variable in `~/.localrc`:

```
echo "export DOT_HOST=\"personal-desktop\"" >> ~/.localrc
```

Optionally add a snippet to `~/.bashrc` to activate the virtual environment on
new shells (you can also just run `source ~/dot/.venv/bin/activate` manually).

Provision the machine. This installs everything else (apt packages, Python
tools, Docker, version-tracked tools, system configuration, and dotfile links):

```
cd ~/dot
dot provision
```

You can preview the changes with `dot provision --dry-run` first.

## Daily Operations

After the initial setup, re-apply the dotfiles configuration with:

```
df_apply
```

which is an alias for `dot provision`. To only re-create the dotfile symlinks
after editing `links.json`, run:

```
dot provision links
```

## Manual Setup Steps

### Git

Create `~/.gitconfig_local` like:

```
[user]
	email = paul@foo.com
	name = Paul Ewing
```

### Desktop Wallpaper

#### Basic Wallpaper Setup

Put logic to apply a wallpaper in `~/set-bg.sh`. The provisioner installs a
default script there if one does not already exist. For example, download a
wallpaper to `~/Pictures/wallpaper.png` and set it via:

```
feh --bg-scale "$HOME/Pictures/wallpaper.png"
```

You can also set the wallpaper using `nitrogen` and then in the shell script, run:

```
nitrogen --restore &
```

#### Wallpaper Rotater

If using `wpr`, create `~/.config/wpr/config.json` like:

```json
{
    "WallpaperDir": "/home/username/Pictures/Wallpapers",
    "DisplayCount": 1,
    "Interval":120
}
```

### Screen Layout

When running a multi-monitor setup, set the screen layout by running `arandr`,
configuring the monitors as desired, and then saving the layout to
`~/.screenlayout/config.sh`.

### Dual Boot Clock Fix

If dual booting with Windows, set hardware clock to local time:

```bash
timedatectl set-local-rtc 1
```

Without this, clock time in Windows will be off.

### Applications to Manually Install

The following are not automated by the provisioners and should be installed
manually:

- Chrome
    - Reason: Proprietary browser; install from the official `.deb`.
- Beyond Compare
    - Reason: Proprietary and needs a license; install from the official `.deb`.
- Insync
    - Download URL: https://www.insynchq.com/downloads/linux
    - Setup:
        - `insync start`
        - Remember to set sync location to: `$HOME/box`
    - Reason: Requires authentication and manual folder mapping.
- Discord
    - Reason: Discord stops working as soon as an upstream update is available
      so it's easier to just install it via the official `.deb` and keep it
      updated that way.
- Visual Studio Code
    - Reason: Install from the official `.deb`/repository.
- RuneLite
    - Reason: Java application that needs a Jagex account; install manually.
- Ventoy
    - Reason: USB tool used infrequently; install from the official release.
