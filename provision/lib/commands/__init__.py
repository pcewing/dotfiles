#!/usr/bin/env python

import argparse

from .list import add_list_parser
from .provision import add_provision_parser


def add_command_parsers(parser: argparse.ArgumentParser) -> None:
    subparsers = parser.add_subparsers(help="commands")

    add_list_parser(subparsers)
    add_provision_parser(subparsers)
