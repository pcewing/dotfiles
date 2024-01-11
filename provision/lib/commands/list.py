#!/usr/bin/env python

import argparse

from ..common.log import Log
from ..common.provisioner import ProvisionerArgs, Provisioners


def add_list_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser("list", help="List the available provisioners")
    parser.add_argument(
        "-p",
        "--provisioner",
        default="jammy",
        help='The provisioner to use (I.E. "jammy" for Ubuntu 22.04)',
    )
    parser.set_defaults(func=cmd_list)


def cmd_list(args: argparse.Namespace) -> None:
    provisioner = Provisioners.get(args.provisioner, ProvisionerArgs(False))
    component_provisioners = provisioner.get_component_provisioners()

    Log.info(f"Component provisioners: [ {', '.join(component_provisioners)} ]")
