#!/usr/bin/env python

import argparse


from .clean import add_clean_parser
from .link import add_link_parser
from .list import add_list_parser
from .provision import add_provision_parser
from .fd import add_fd_parser


def add_command_parsers(parser: argparse.ArgumentParser) -> None:
    subparsers = parser.add_subparsers(help="commands")

    add_clean_parser(subparsers)
    add_link_parser(subparsers)
    add_list_parser(subparsers)
    add_provision_parser(subparsers)
    add_fd_parser(subparsers)
