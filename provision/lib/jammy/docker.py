#!/usr/bin/env python

import os
import pwd
import subprocess
import urllib.request

from ..common.provisioner import IComponentProvisioner, ProvisionerArgs
from ..common.util import get_home_dir, mkdir_p, download_file, get_current_user
from ..common.log import Log
from ..common.apt import Apt


class DistroInformation:
    def __init__(self) -> None:
        self.distrib_id = None
        self.distrib_release = None
        self.distrib_codename = None
        self.distrib_description = None

        with open("/etc/lsb-release", "r") as f:
            for line in f:
                (var, val) = line.strip().split("=")
                if var == "DISTRIB_ID":
                    self.distrib_id = val
                elif var == "DISTRIB_RELEASE":
                    self.distrib_release = val
                elif var == "DISTRIB_CODENAME":
                    self.distrib_codename = val
                elif var == "DISTRIB_DESCRIPTION":
                    self.distrib_description = val

        if (
            self.distrib_id is None
            or self.distrib_release is None
            or self.distrib_codename is None
            or self.distrib_description is None
        ):
            raise Exception("Failed to construct DistroInformation")

    def __str__(self) -> str:
        return f"DISTRIB_ID = {self.distrib_id}, DISTRIB_RELEASE = {self.distrib_release}, DISTRIB_CODENAME = {self.distrib_codename}, DISTRIB_DESCRIPTION = {self.distrib_description}"


class DockerProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        if self._args.dry_run:
            Log.info("Dry run!")
        Apt.list_installed()

    # TODO This is the actual implementation of this provisioner but I'm
    # testing things to make this idempotent so moving it temporarily to avoid
    # accidentally running it
    def _provision_impl(self) -> None:
        distro_info = DistroInformation()
        Log.info(distro_info)

        base_url = f"https://download.docker.com/linux/ubuntu/dists/{distro_info.distrib_codename}/pool/stable/amd64"
        Log.info(base_url)

        # TODO: Automatically choose latest version
        packages = [
            "containerd.io_1.6.9-1_amd64.deb",
            "docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb",
            "docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb",
            "docker-buildx-plugin_0.11.2-1~ubuntu.22.04~jammy_amd64.deb",
            "docker-compose-plugin_2.6.0~ubuntu-jammy_amd64.deb",
        ]

        tmp_dir = os.path.join(get_home_dir(), ".tmp")
        mkdir_p(tmp_dir)

        for package in packages:
            Log.info(f"Downloading {package}")
            download_file(f"{base_url}/{package}", os.path.join(tmp_dir, package))

        cmd = ["sudo", "dpkg", "-i"] + [os.path.join(tmp_dir, pkg) for pkg in packages]

        Log.info("Installing packages:\n{}\n".format(" ".join(cmd)))
        if subprocess.call(cmd) != 0:
            raise Exception("Failed to install packages")

        user = get_current_user()
        cmd = ["sudo", "usermod", "-aG", "docker", user.pw_name]

        Log.info("Adding user to docker group")
        if subprocess.call(cmd) != 0:
            raise Exception("Failed to add user to docker group")
