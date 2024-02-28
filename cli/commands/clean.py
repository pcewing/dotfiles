#!/usr/bin/env python

import argparse
import os

from lib.common.log import Log
from lib.common.links import Links


def add_clean_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "clean",
        help="Clean up symbolic links to dotfiles",
    )
    parser.set_defaults(func=cmd_clean)


def cmd_clean(args: argparse.Namespace) -> None:
    Log.info("Removing symlinks")
    Log.info("==============================")

    links = Links.get()
    for link in links:
        link.delete()

    Log.info("Removing symlink for sway-user.desktop requires root priveleges; run:")
    Log.info('sudo rm "/usr/share/wayland-sessions/sway-user.desktop"')
