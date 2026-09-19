#!/usr/bin/env python

import subprocess

from dot.lib.common.apt import Apt
from dot.lib.common.log import Log
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs
from dot.lib.provision.tag import Tags

# fmt: off
APT_PACKAGES = {
    "core": [
        "apt-file",
        "jq",
        "plocate",
        "fzf",
        "net-tools",
        "uchardet",
        "dos2unix",
        "cmake",
        "meson",
        "ninja-build",
        "htop",
        "iotop",
        "universal-ctags",
        "ranger",
        "tmux",
        "neofetch",
        "id3v2",
        "calcurse",
        "vim",
        "clang",
        "clangd",
        "fd-find",
    ],
    "gui-tools": [
        "fonts-font-awesome",  # Used for media buttons on polybar
        "rofi",                # Fuzzy application launcher
        "dunst",               # Desktop notifications
        "feh",                 # Set wallpaper
        "sxiv",                # Image viewer
        "nitrogen",            # Set wallpaper
        "pavucontrol",         # Pulse Audio frontend
        "picom",               # Window compositor
        "scrot",               # Screen capture
        "gucharmap",           # Useful for debugging font issues
        "keepassxc",           # Credential manager
        "remmina",             # RDP session manager
        "i3lock",              # Lock screen
        "meld",                # Diff tool
        "xclip",               # Clipboard for X11
        "wl-clipboard",        # Clipboard for Wayland
        "xdotool",             # X11 automation tool
        "webp",                # Command line support for webp image files
        "arandr",              # Screen layout editor
        "librsvg2-bin",        # rsvg-convert for wallpaper generation
        "rxvt-unicode",        # Backup terminal emulator
        "i3",                  # Window manager (gaps are mainline as of 4.22)
        "i3status",            # i3 status bar
    ],
    "media": [
        "inkscape",            # Vector graphics editor
        "mpv",                 # Minimal media player
        "vlc",                 # General purpose FOSS media player
        "easytag",             # Edit ID3 Tags on MP3 files
        "blueman",             # Bluetooth device support
        "mpd",                 # Music Player Daemon
        "ncmpcpp",             # mpd client
        "cava",                # Console audio visualizer
        "yt-dlp",              # Video downloader
    ],
    "gaming": [
        "steam",
    ],
    "wsl": [
        "wslu",                # Provides wslview
    ],
}
# fmt: on


class AptProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        if self._args.update:
            Apt.update(self._args.dry_run)

        if self._args.upgrade:
            Apt.upgrade(self._args.dry_run)

        packages = list(APT_PACKAGES["core"])

        if self._args.tags.has(Tags.x11):
            packages += APT_PACKAGES["gui-tools"]
            packages += APT_PACKAGES["media"]

        if self._args.tags.has(Tags.gaming):
            self._enable_multiverse()
            packages += APT_PACKAGES["gaming"]

        if self._args.tags.has(Tags.wsl):
            packages += APT_PACKAGES["wsl"]

        Apt.install(packages, self._args.dry_run)

    def _enable_multiverse(self) -> None:
        # The steam package lives in the multiverse repository.
        Log.info("enabling the multiverse apt repository")
        if self._args.dry_run:
            Log.info("skipping add-apt-repository due to --dry-run")
            return
        cmd = ["sudo", "add-apt-repository", "-y", "multiverse"]
        if subprocess.call(cmd) != 0:
            raise Exception("Failed to enable the multiverse repository")
