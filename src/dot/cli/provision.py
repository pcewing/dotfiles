#!/usr/bin/env python

import argparse
import json
import os
from pathlib import Path

from dot.lib.common.dir import Dir
from dot.lib.common.distro_info import DistroInformation
from dot.lib.common.log import Log
from dot.lib.common.os import OperatingSystem
from dot.lib.common.version_cache import VersionCache
from dot.lib.provision.provisioner import ProvisionerArgs
from dot.lib.provision.system_provisioner import SystemProvisioner
from dot.lib.provision.tag import Tags


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
            "unnecessary steps; this forces those steps to be run"
        ),
    )
    parser.add_argument(
        "--host",
        default=os.getenv("DOT_HOST"),
        help=(
            "Host profile from hosts.json; defaults to the DOT_HOST "
            "environment variable"
        ),
    )
    parser.add_argument(
        "-t",
        "--tags",
        default=None,
        help="Comma delimited list of tags that influence provisioning [x11|wsl|gaming]",
    )
    parser.add_argument(
        "--no-update",
        dest="update",
        action="store_false",
        default=True,
        help="Skip the apt-get update step",
    )
    parser.add_argument(
        "--upgrade",
        action="store_true",
        help="Also run apt-get dist-upgrade",
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


def load_host_tags(host: str) -> list[str]:
    path = os.path.join(Dir.dot(), "hosts.json")
    if not os.path.isfile(path):
        raise Exception(f"hosts.json not found at {path}")

    with open(path, "r") as f:
        data = json.load(f)

    hosts = data.get("hosts", {})
    if host not in hosts:
        available = ", ".join(sorted(hosts.keys()))
        raise Exception(f"Unknown host '{host}'. Available hosts: {available}")

    return list(hosts[host].get("tags", []))


def resolve_tags(args: argparse.Namespace) -> Tags:
    if args.tags is not None:
        return Tags.parse(args.tags)
    if args.host:
        return Tags.from_names(load_host_tags(args.host))
    return Tags.default()


def cmd_provision(args: argparse.Namespace) -> None:
    if OperatingSystem.get().is_linux():
        if os.getuid() == 0:
            raise Exception("do not run as root")

        distro = DistroInformation.get()
        if distro is not None:
            Log.info(
                "provisioning system",
                {
                    "distro.id": distro.id,
                    "distro.release": distro.release,
                    "distro.codename": distro.codename,
                },
            )

    tags = resolve_tags(args)
    Log.info("using tags", {"tags": [tag.name for tag in tags.tags]})

    VersionCache.init(
        args.version_cache,
        Path(os.path.join(Dir.dot(), "version_cache.json5")),
        args.version_cache_max_age_days,
    )

    provisioner_args = ProvisionerArgs(
        dry_run=args.dry_run,
        tags=tags,
        force=args.force,
        update=args.update,
        upgrade=args.upgrade,
    )
    provisioner = SystemProvisioner(provisioner_args, args.components)
    provisioner.provision()
