"""Argparse front end for the dot CLI.

Each subcommand is a module or subpackage here that registers itself on the
top-level parser via its ``add_<name>_parser`` function; all logic lives in
:mod:`dot.lib`.
"""
