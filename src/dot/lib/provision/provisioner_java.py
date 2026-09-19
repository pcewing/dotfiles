#!/usr/bin/env python

from dot.lib.common.apt import Apt
from dot.lib.common.distro_info import DistroInformation
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs


class JavaProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        # openjdk-21 is only in the 24.04+ repositories; fall back to 17 for
        # older releases.
        jdk_version = "17"
        distro = DistroInformation.get()
        if distro is not None and distro.release:
            try:
                if float(distro.release) >= 24.04:
                    jdk_version = "21"
            except ValueError:
                pass

        Apt.install([f"openjdk-{jdk_version}-jdk"], self._args.dry_run)
