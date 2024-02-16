#!/usr/bin/env python

import argparse
import os
import sys
import subprocess

from lib.common.distro_info import DistroInformation
from lib.common.log import Log
from lib.common.provisioner import ProvisionerArgs, Provisioners
from lib.jammy.provisioner import UbuntuJammyProvisioner


def add_provision_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "provision", help="Run provisioners to configure components"
    )
    parser.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        help="Print provisioning actions without running them",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help=(
            "Provisioners may try to detect current state and skip "
            "unnecessery steps; this forces those steps to be run"
        ),
    )
    parser.add_argument(
        "-p",
        "--provisioner",
        default="jammy",
        help='The provisioner to use (I.E. "jammy" for Ubuntu 22.04)',
    )
    parser.add_argument(
        "-a",
        "--all",
        action="store_true",
        help="Provision all components",
    )
    parser.add_argument(
        "components",
        nargs="*",
        help="The components to provision",
    )
    parser.set_defaults(func=cmd_provision)

# TODO: Move the elevation stuff to lib?
def is_root():
    return os.getuid() == 0

def find_in_path(cmd):
    for dir in os.environ.get('PATH', '').split(':'):
        path = os.path.join(dir, cmd)
        if os.path.isfile(path):
            return path
    return None

def get_script_path():
    if isinstance(sys.argv[0], str) and len(sys.argv[0]) > 0:
        return
    raise Exception("Failed to identify script path")

def elevate():
    sudo = find_in_path("sudo")
    if sudo is None:
        raise Exception("Failed to find sudo executable in PATH")

    cmd = [
        sudo,
        "--preserve-env",
        os.path.abspath(sys.executable),
        os.path.abspath(sys.argv[0]),
        ] + sys.argv[1:]

    print("This script requires root access, elevating...")
    sys.exit(subprocess.call(cmd))


def cmd_provision(args: argparse.Namespace) -> None:
    if args.all and len(args.components) > 0:
        raise Exception(
            "Positional component arguments may not be specified when the --all "
            "option is used"
        )
    elif not args.all and len(args.components) == 0:
        raise Exception(
            "Positional component arguments must be specified when the --all "
            "option is not used"
        )

    # TODO: Revert this change and just runs commands with sudo as needed:
    # - Running as root means $HOME resolves to /root
    #     - Resolved by adding --preserve-env but not ideal
    # - Files written, downloaded, etc will be owned by root
    if not args.dry_run and not is_root():
        elevate()

    distro = DistroInformation.get()

    if distro.codename != args.provisioner:
        Log.warn(
            f"Running the {args.provisioner} provisioner but the current system is {distro.codename}"
        )

    Log.info(f"Provisioning {distro.id} {distro.release} ({distro.codename})")

    provisioner_args = ProvisionerArgs(args.dry_run)
    provisioner = Provisioners.get(args.provisioner, provisioner_args)

    if args.all:
        provisioner.provision_all_components()
    else:
        provisioner.provision_components(args.components)
