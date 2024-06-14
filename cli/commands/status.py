#!/usr/bin/env python

import argparse
import os

from lib.common.dir import Dir
from lib.common.git import Git


def add_status_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "status",
        help="Print current dotfile status",
    )
    parser.set_defaults(func=cmd_status)


def cmd_status(args: argparse.Namespace) -> None:
    os.chdir(Dir.dot())

    branches = Git.get_branches()
    for branch in branches:
        if branch.is_current:
            print(f"On branch: {branch.name}")

    # TODO: Check if there are unstaged changes
    print("Unstaged changes: TODO")

    # TODO: Check if there are staged but uncommitted changes
    print("Uncommitted changes: TODO")

    # TODO: Check if local repository is missing commits from remote
    print("Behind upstream: TODO")

    # TODO: Check if remote repository is missing commits from local
    print("Ahead of upstream: TODO")
