#!/usr/bin/env python

import argparse

from lib.common.linter import Linter


def add_lint_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "lint",
        help="Lint Python files",
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="The files to lint; if omitted, all files are linted",
    )
    parser.set_defaults(func=cmd_lint)


def cmd_lint(args: argparse.Namespace) -> None:
    Linter.lint(args.files)
