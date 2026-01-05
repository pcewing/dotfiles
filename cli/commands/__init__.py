#!/usr/bin/env python

import argparse

from .clean import add_clean_parser
from .fd import add_fd_parser
from .git_sync import add_git_sync_parser
from .link import add_link_parser
from .lint import add_lint_parser
from .status import add_status_parser
from .tidy import add_tidy_parser


def add_command_parsers(parser: argparse.ArgumentParser) -> None:
    subparsers = parser.add_subparsers(help="commands")

    add_clean_parser(subparsers)
    add_fd_parser(subparsers)
    add_git_sync_parser(subparsers)
    add_link_parser(subparsers)
    add_lint_parser(subparsers)
    add_status_parser(subparsers)
    add_tidy_parser(subparsers)
