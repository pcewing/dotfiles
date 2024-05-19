#!/usr/bin/env python

import argparse

from lib.common.linter import Linter


def add_tidy_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "tidy",
        help="Tidy Python files",
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="The files to tidy; if omitted, all files are tidied",
    )
    parser.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        help="Print tidy actions without running them",
    )
    parser.set_defaults(func=cmd_tidy)


def cmd_tidy(args: argparse.Namespace) -> None:
    Linter.tidy(args.files, args.dry_run)
