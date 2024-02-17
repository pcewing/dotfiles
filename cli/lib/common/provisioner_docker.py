#!/usr/bin/env python

import os

from .distro_info import DistroInformation
from .provisioner import IComponentProvisioner, ProvisionerArgs
from .util import download_file, get_current_user
from .dir import Dir
from .apt import Apt
from .group import Group
from .shell import Shell


class DockerProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        distro_info = DistroInformation.get()

        base_url = f"https://download.docker.com/linux/ubuntu/dists/{distro_info.codename}/pool/stable/amd64"

        # TODO: Automatically choose latest version
        packages = [
            "containerd.io_1.6.9-1_amd64.deb",
            f"docker-ce_24.0.7-1~ubuntu.22.04~{distro_info.codename}_amd64.deb",
            f"docker-ce-cli_24.0.7-1~ubuntu.22.04~{distro_info.codename}_amd64.deb",
            f"docker-buildx-plugin_0.11.2-1~ubuntu.22.04~{distro_info.codename}_amd64.deb",
            f"docker-compose-plugin_2.6.0~ubuntu-{distro_info.codename}_amd64.deb",
        ]

        # TODO: Make this a common directory like Dir.tmp()
        tmp_dir = os.path.join(Dir.home(), ".tmp")
        Shell.mkdir(tmp_dir, True, False, self._args.dry_run)

        for package in packages:
            download_file(
                f"{base_url}/{package}",
                os.path.join(tmp_dir, package),
                False,
                False,
                self._args.dry_run,
            )

        Apt.install_deb_files(packages, self._args.dry_run)

        Group.add_user("docker", get_current_user().pw_name, self._args.dry_run)
