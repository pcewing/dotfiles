#!/usr/bin/env python

import os
import pwd
import subprocess
import urllib.request
from typing import Dict, List

from ..common.dir import Dir
from ..common.provisioner import IComponentProvisioner, ProvisionerArgs
from ..common.util import mkdir_p, download_file, add_user_to_group
from ..common.log import Log
from .apt import Apt
from ..common.distro_info import DistroInformation


class DockerProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        self._install_packages()

        # Note that group modifications won't take effect until
        add_user_to_group("docker", self._args.dry_run)

    def _install_packages(self):
        distro_info = DistroInformation.get()

        # TODO: Automatically infer latest versions

        # fmt: off
        packages_needed = {
            "containerd.io":            "1.6.9-1",
            "docker-ce":                "24.0.7-1~ubuntu.22.04~jammy",
            "docker-ce-cli":            "24.0.7-1~ubuntu.22.04~jammy",
            "docker-buildx-plugin":     "0.11.2-1~ubuntu.22.04~jammy",
            "docker-compose-plugin":    "2.6.0~ubuntu-jammy",
        }
        # fmt: on

        # Determine which of the above packages need to be installed
        required_packages = self._reconcile_required_packages(packages_needed)

        if len(required_packages) == 0:
            Log.info("Docker is already installed, skipping package installs")
            return

        tmp_dir = os.path.join(Dir.home(), ".tmp")
        mkdir_p(tmp_dir, self._args.dry_run)

        # Format the filenames for downloading/installing
        package_files = []
        for package in required_packages:
            version = packages_needed[package]
            package_filename = f"{package}_{version}_amd64.deb"
            package_files.append(os.path.join(tmp_dir, package_filename))

        Log.info("Downloading packages that need to be installed")
        base_url = f"https://download.docker.com/linux/ubuntu/dists/{distro_info.distrib_codename}/pool/stable/amd64"
        for package_file in package_files:
            url = f"{base_url}/{os.path.basename(package_file)}"
            download_file(url, package_file, self._args.dry_run)

        # Convert to absolute paths
        Apt.install_deb_files(package_files, self._args.dry_run)

    def _reconcile_required_packages(self, packages: Dict[str, str]) -> List[str]:
        installed_packages = Apt.get_installed_packages()

        # Convert this to a map for performance and readability
        installed_package_map = {}
        for p in installed_packages:
            installed_package_map[p.name] = p

        required_packages = []
        for p in packages:
            if p not in installed_package_map:
                Log.info(f"{p} is not installed")
                required_packages.append(p)
            elif packages[p] != installed_package_map[p].version:
                Log.info(
                    f"{p} is not the required version (Current = {packages[p]}, Required = {installed_package_map[p].version})"
                )
                required_packages.append(p)
        return required_packages
