#!/usr/bin/env python

import os
import shutil
import subprocess

from dot.lib.common.apt import Apt
from dot.lib.common.dir import Dir
from dot.lib.common.distro_info import DistroInformation
from dot.lib.common.log import Log
from dot.lib.common.util import download_file
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

DOTNET_SDK_VERSION = "8.0"


class DotnetProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        if shutil.which("dotnet") is not None and not self._args.force:
            Log.info("dotnet is already installed, nothing to do")
            return

        release = "24.04"
        distro = DistroInformation.get()
        if distro is not None and distro.release:
            release = distro.release

        deb_url = (
            f"https://packages.microsoft.com/config/ubuntu/{release}/"
            "packages-microsoft-prod.deb"
        )
        staging_dir = Dir.staging("dotnet", "repo")
        deb_path = os.path.join(staging_dir, "packages-microsoft-prod.deb")

        download_file(deb_url, deb_path, False, True, self._args.dry_run)

        if self._args.dry_run:
            Log.info(
                "would add the Microsoft package repository and install dotnet",
                {"package": f"dotnet-sdk-{DOTNET_SDK_VERSION}"},
            )
            return

        if subprocess.call(["sudo", "dpkg", "-i", deb_path]) != 0:
            raise Exception("Failed to add the Microsoft package repository")

        Apt.update(self._args.dry_run)
        Apt.install([f"dotnet-sdk-{DOTNET_SDK_VERSION}"], self._args.dry_run)
