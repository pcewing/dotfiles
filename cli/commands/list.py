#!/usr/bin/env python

import argparse

from lib.common.log import Log
from lib.common.provisioner import ProvisionerArgs
from lib.common.system_provisioner import SystemProvisioner


def add_list_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser("list", help="List the available provisioners")
    parser.set_defaults(func=cmd_list)


def cmd_list(args: argparse.Namespace) -> None:
    provisioner = SystemProvisioner(ProvisionerArgs(False))
    component_provisioners = provisioner.get_component_provisioners()

    Log.info(f"Component provisioners: [ {', '.join(component_provisioners)} ]")
