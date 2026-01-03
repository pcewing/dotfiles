#!/usr/bin/env python

from lib.common.pip import Pip
from lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

_PIP_PACKAGES = {
    "core": [
        "black",
        "mypy",
        "isort",
        "flake8",
        "autoflake",
        "ruff",
        "argcomplete",
    ],
}


class PipProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        # TODO: This breaks on Ubuntu 24.04 because Pip packages installed system-wide need to be installed via:
        # apt install python3-foo
        return
        packages = _PIP_PACKAGES["core"]
        Pip.install(
            packages=packages,
            upgrade=True,
            sudo=False,
            dry_run=self._args.dry_run,
        )
