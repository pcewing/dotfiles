#!/usr/bin/env python

import argparse
import os
from pathlib import Path

from lib.common.dir import Dir
from lib.common.distro_info import DistroInformation
from lib.common.log import Log
from lib.common.os import OperatingSystem
from lib.common.version_cache import VersionCache
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
        "--no-version-cache",
        dest="version_cache",
        action="store_false",
        default=True,
        help="Disable the version cache when checking for latest versions",
    )
    parser.add_argument(
        "--version-cache-max-age-days",
        type=int,
        default=7,
        metavar="DAYS",
        help=(
            "Maximum age (in days) for cached version entries. "
            "If the cached entry is older than this, the script will attempt "
            "to refresh it from the source (default: 7 days)."
        ),
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

    VersionCache.init(
        args.version_cache,
        Path(os.path.join(Dir.dot(), "version_cache.json5")),
        args.version_cache_max_age_days,
    )

    provisioner_args = ProvisionerArgs(args.dry_run, tags)
    provisioner = SystemProvisioner(provisioner_args, args.components)
    provisioner.provision()
