#!/usr/bin/env python

import argparse
import sys

from dot.lib.common.linter import Linter, LinterError
from dot.lib.common.log import Log
from dot.lib.common.python_files import PythonFilesError


def add_tidy_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "tidy",
        help="Tidy Python files",
    )
    parser.add_argument(
        "files",
        nargs="*",
        metavar="PATH",
        help="Files or directories to tidy; directories are expanded to the git-tracked Python files they contain",
    )
    parser.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        help="Print tidy actions without running them",
    )
    parser.set_defaults(func=cmd_tidy)


def cmd_tidy(args: argparse.Namespace) -> None:
    try:
        Linter.tidy(args.files, args.dry_run)
    except (LinterError, PythonFilesError) as e:
        Log.error(str(e))
        sys.exit(2)
