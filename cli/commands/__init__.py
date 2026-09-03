#!/usr/bin/env python

import argparse

from .fd import add_fd_parser
from .git_sync import add_git_sync_parser
from .links import add_links_parser
from .lint import add_lint_parser
from .status import add_status_parser
from .tidy import add_tidy_parser


def add_command_parsers(parser: argparse.ArgumentParser) -> None:
    subparsers = parser.add_subparsers(help="commands")

    add_fd_parser(subparsers)
    add_git_sync_parser(subparsers)
    add_links_parser(subparsers)
    add_lint_parser(subparsers)
    add_status_parser(subparsers)
    add_tidy_parser(subparsers)
