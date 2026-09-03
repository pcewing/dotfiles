#!/usr/bin/env python

import argparse
from typing import Sequence

import argcomplete

from dot import __version__
from dot.cli.commands import add_command_parsers
from dot.lib.common.log import Log


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Dotfiles CLI")
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        default="info",
        help="Logging level to run with (debug, info, warn, error, crit)",
    )

    add_command_parsers(parser)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    argcomplete.autocomplete(parser)

    args = parser.parse_args(argv)
    if "func" not in args:
        parser.print_help()
        return 2

    Log.init("dot", Log.parse_level(args.log_level))
    args.func(args)
    return 0
