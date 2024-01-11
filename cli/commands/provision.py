#!/usr/bin/env python

import argparse

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
