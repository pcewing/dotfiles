#!/usr/bin/env python

import argparse
import os

from lib.common.log import Log
from lib.common.links import Links

def add_link_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "link",
        help="Create symbolic links to dotfiles",
    )
    parser.set_defaults(func=cmd_link)

def cmd_link(args: argparse.Namespace) -> None:
    Log.info("Creating symlinks")
    Log.info("=================")

    links = Links.get()
    for link in links:
        link.create()
