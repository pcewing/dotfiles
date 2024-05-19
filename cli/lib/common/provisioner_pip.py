#!/usr/bin/env python

from .provisioner import IComponentProvisioner, ProvisionerArgs
from .pip import Pip

_PIP_PACKAGES = {
    "core": [
        "black",
        "mypy",
        "isort",
        "flake8",
        "autoflake",
        "ruff",
    ],
}


class PipProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        packages = _PIP_PACKAGES["core"]
        Pip.install(
            packages=packages,
            upgrade=True,
            sudo=False,
            dry_run=self._args.dry_run,
        )
