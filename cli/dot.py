#!/usr/bin/env python

import argparse
import os

from commands import add_command_parsers
from lib.common.log import Log


def parse_args():
    parser = argparse.ArgumentParser(description="Dotfiles CLI")
    parser.add_argument(
        "-l",
        "--log-level",
        default="info",
        help="Logging level to run with (debug, info, warn, error, crit)",
    )

    add_command_parsers(parser)

    if os.getenv("DOT_BASH_COMPLETION") == "1":
        import argcomplete

        argcomplete.autocomplete(parser)

    args = parser.parse_args()
    if "func" not in args:
        parser.print_help()
        exit(1)
    return args


def main():
    args = parse_args()

    Log.init("dot", args.log_level)

    args.func(args)


if __name__ == "__main__":
    main()
