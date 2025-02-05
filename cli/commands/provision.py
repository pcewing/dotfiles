#!/usr/bin/env python

import argparse
import os

from lib.common.distro_info import DistroInformation
from lib.common.log import Log
from lib.common.os import OperatingSystem
from lib.provision.provisioner import ProvisionerArgs
from lib.provision.system_provisioner import SystemProvisioner
from lib.provision.tag import Tags


def add_provision_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "provision", help="Run provisioners to configure components"
    )
    # TODO: Implement a confirmation
    # parser.add_argument(
    #    "-y",
    #    "--yes",
    #    action="store_true",
    #    help="Don't ask for confirmation",
    # )
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
        "-t",
        "--tags",
        default=Tags.default(),
        help="Comma delimited list of tags that influence provisioner behavior [x11|wsl]",
    )
    parser.add_argument(
        "components",
        nargs="*",
        help="The components to provision; if omitted, all components are provisioned",
    )
    parser.set_defaults(func=cmd_provision)


def cmd_provision(args: argparse.Namespace) -> None:
    if OperatingSystem.get().is_linux():
        if os.getuid() == 0:
            raise Exception("do not run as root")

        distro = DistroInformation.get()
        Log.info(
            "provisioning system",
            {
                "distro.id": distro.id,
                "distro.release": distro.release,
                "distro.codename": distro.codename,
            },
        )

    tags = Tags.parse(args.tags) if isinstance(args.tags, str) else args.tags

    provisioner_args = ProvisionerArgs(args.dry_run, tags)
    provisioner = SystemProvisioner(provisioner_args, args.components)
    provisioner.provision()
