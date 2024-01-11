#!/usr/bin/env python


import os
import argparse

from lib.common.log import Log 


from lib.commands import add_command_parsers

SCRIPT_PATH = os.path.realpath(__file__)
SCRIPT_DIR = os.path.dirname(SCRIPT_PATH)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="CLI with utilities for provisioning Linux machines")
    parser.add_argument(
        "-l",
        "--log-level",
        default="info",
        help="Logging level to run with (debug, info, warn, error, crit)",
    )

    add_command_parsers(parser)

    args = parser.parse_args()
    if "func" not in args:
        parser.print_help()
        exit(1)
    return args


def main() -> None:
    args = parse_args()

    Log.init(args.log_level)

    args.func(args)


if __name__ == "__main__":
    main()
