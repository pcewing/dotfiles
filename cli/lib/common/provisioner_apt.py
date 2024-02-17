#!/usr/bin/env python

from .provisioner import IComponentProvisioner, ProvisionerArgs
from .apt import Apt

# fmt: off
APT_PACKAGES = {
    "core": [
        "apt-utils",
        "ca-certificates",
        "curl",
        "wget",
        "gnupg",
        "jq",
        "software-properties-common",
        "apt-file",
        "libfuse2",  # This is required to use AppImage
        "locate",
        "fzf", # TODO: Don't install fzf this way, shell integration broken
        "net-tools",
        "unzip",
        "uchardet",
        "dos2unix",
    ],
    "cli-tools": [
        "make",
        "build-essential",
        "cmake",
        "meson",
        "htop",
        "iotop",
        "git",
        "vim",
        "universal-ctags",  # I think this has better c++11 support
        "ranger",
        "tmux",
        "neofetch",
        "id3v2",
        "calcurse",
        "rxvt-unicode",
        "clang",
        "clangd",
    ],
    "python-3": [
        "python3",
        "python3-dev",
        "python3-pip"
    ],
    "gui-tools": [
        "fonts-font-awesome", # Used for media buttons on polybar
        "rofi",               # Fuzzy application launcher
        "dunst",              # Desktop notifications
        "feh",                # Set wallpaper
        "sxiv",               # Image viewer
        "nitrogen",           # Set wallpaper
        "pavucontrol",        # Pulse Audio frontend
        "compton",            # Window compositor
        "scrot",              # Screen capture
        "gucharmap",          # Useful for debugging font issues
        "keepassxc",          # Credential manager
        "remmina",            # RDP session manager
        "usb-creator-gtk",    # Easily flash bootable USBs
        "i3lock",             # Lock screen
        "meld",               # Diff tool
        "xclip",              # Clipboard for X11
        "wl-clipboard",       # Clipboard for Wayland
        "xdotool",            # X11 automation tool
        "kitty",              # Kitty terminal emulator
        "kitty-terminfo",     # Kitty TERMINFO
        "webp",               # Command line support for webp image files
    ],
    "media": [
        "inkscape" # Vector graphics editor
        "mpv"      # Minimal media player
        "vlc"      # General purpose FOSS media player
        "easytag"  # Edit ID3 Tags on MP3 files
        "blueman"  # Bluetooth device support
    ],
    "gaming": [
        "steam",
        "steam-devices",
    ],
}
# fmt: on


class AptProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        Apt.update(self._args.dry_run)
        Apt.upgrade(self._args.dry_run)

        packages = (
            APT_PACKAGES["core"]
            + APT_PACKAGES["cli-tools"]
            + APT_PACKAGES["python-3"]
            + APT_PACKAGES["gui-tools"]
            + APT_PACKAGES["media"]
            + APT_PACKAGES["gaming"]
        )

        Apt.install(packages, self._args.dry_run)
