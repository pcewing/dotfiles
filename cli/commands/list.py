#!/usr/bin/env python

import argparse

from lib.common.log import Log
from lib.common.provisioner import ProvisionerArgs
from lib.common.system_provisioner import SystemProvisioner


def add_list_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser("list", help="List the available provisioners")
    parser.set_defaults(func=cmd_list)


def cmd_list(args: argparse.Namespace) -> None:
    component_provisioners = SystemProvisioner.get_provisioner_list()

    Log.info(f"Component provisioners: [ {', '.join(component_provisioners)} ]")
