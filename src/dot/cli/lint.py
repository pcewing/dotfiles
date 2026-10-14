#!/usr/bin/env python

import argparse
import sys

from dot.lib.common.linter import Linter, LinterError
from dot.lib.common.log import Log
from dot.lib.common.python_files import PythonFilesError


def add_lint_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "lint",
        help="Lint Python files",
    )
    parser.add_argument(
        "files",
        nargs="*",
        metavar="PATH",
        help=(
            "Files or directories to lint; directories are expanded to the git-tracked Python files they contain; "
            "if omitted, all tracked Python files in the dotfiles repo are linted"
        ),
    )
    parser.set_defaults(func=cmd_lint)


def cmd_lint(args: argparse.Namespace) -> None:
    try:
        passed = Linter.lint(args.files)
    except (LinterError, PythonFilesError) as e:
        Log.error(str(e))
        sys.exit(2)
    if not passed:
        sys.exit(1)
