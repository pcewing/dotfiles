#!/usr/bin/env python

import getpass
import os
import shutil
import subprocess

from dot.lib.common.apt import Apt
from dot.lib.common.dir import Dir
from dot.lib.common.distro_info import DistroInformation
from dot.lib.common.group import Group
from dot.lib.common.log import Log
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

DOCKER_GPG_URL = "https://download.docker.com/linux/ubuntu/gpg"
DOCKER_KEYRING_PATH = "/etc/apt/keyrings/docker.asc"
DOCKER_SOURCES_PATH = "/etc/apt/sources.list.d/docker.sources"
DOCKER_PACKAGES = [
    "docker-ce",
    "docker-ce-cli",
    "containerd.io",
    "docker-buildx-plugin",
    "docker-compose-plugin",
]


class DockerProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        if shutil.which("docker") is not None and not self._args.force:
            Log.info("docker is already installed, nothing to do")
            return

        distro = DistroInformation.get()
        codename = distro.codename if distro is not None else ""
        if not codename:
            raise Exception("Failed to determine the Ubuntu codename for Docker")

        if self._args.dry_run:
            Log.info(
                "would add the Docker repository and install",
                {"packages": DOCKER_PACKAGES},
            )
            return

        self._add_repository(codename)
        Apt.update(self._args.dry_run)
        Apt.install(DOCKER_PACKAGES, self._args.dry_run)
        self._add_user_to_group()

    def _add_repository(self, codename: str) -> None:
        Log.info("adding the Docker apt repository")

        if (
            subprocess.call(
                ["sudo", "install", "-m", "0755", "-d", "/etc/apt/keyrings"]
            )
            != 0
        ):
            raise Exception("Failed to create /etc/apt/keyrings")

        gpg_cmd = ["sudo", "curl", "-fsSL", DOCKER_GPG_URL, "-o", DOCKER_KEYRING_PATH]
        if subprocess.call(gpg_cmd) != 0:
            raise Exception("Failed to download the Docker GPG key")

        subprocess.call(["sudo", "chmod", "a+r", DOCKER_KEYRING_PATH])

        contents = "\n".join(
            [
                "Types: deb",
                "URIs: https://download.docker.com/linux/ubuntu",
                f"Suites: {codename}",
                "Components: stable",
                f"Signed-By: {DOCKER_KEYRING_PATH}",
                "",
            ]
        )

        staging_dir = Dir.staging("docker", "repo")
        os.makedirs(staging_dir, exist_ok=True)
        staging_path = os.path.join(staging_dir, "docker.sources")
        with open(staging_path, "w") as f:
            f.write(contents)

        install_cmd = [
            "sudo",
            "install",
            "-m",
            "0644",
            staging_path,
            DOCKER_SOURCES_PATH,
        ]
        if subprocess.call(install_cmd) != 0:
            raise Exception("Failed to install the Docker apt source")

    def _add_user_to_group(self) -> None:
        # The group may already exist.
        subprocess.call(["sudo", "groupadd", "docker"])
        Group.add_user("docker", getpass.getuser(), self._args.dry_run)
        Log.info(
            "Docker was installed; log out and back in (or reboot) for the "
            "docker group membership to take effect"
        )
