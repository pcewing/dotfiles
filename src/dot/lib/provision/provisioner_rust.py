#!/usr/bin/env python

import shutil
import subprocess

from dot.lib.common.log import Log
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

RUSTUP_INSTALL_URL = "https://sh.rustup.rs"


class RustProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        if shutil.which("rustup") is not None and not self._args.force:
            Log.info("rustup is already installed, nothing to do")
            return

        Log.info("installing rustup")
        if self._args.dry_run:
            Log.info("skipping rustup install due to --dry-run")
            return

        cmd = (
            f"curl --proto '=https' --tlsv1.2 -sSf {RUSTUP_INSTALL_URL} "
            "| sh -s -- -y --no-modify-path"
        )
        if subprocess.call(cmd, shell=True) != 0:
            raise Exception("Failed to install rustup")
