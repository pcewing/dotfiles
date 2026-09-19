#!/usr/bin/env python

from dot.lib.common.pip import Pip
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs
from dot.lib.provision.tag import Tags

# fmt: off
PIP_PACKAGES = {
    "core": [
        "argcomplete",
        "json5",
        "black",
        "mypy",
        "isort",
        "flake8",
        "autoflake",
        "ruff",
        "pynvim",
        "python-mpd2",
        "jedi-language-server",
    ],
    "x11": [
        "py3status",
    ],
}
# fmt: on


class PipProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        packages = list(PIP_PACKAGES["core"])

        if self._args.tags.has(Tags.x11):
            packages += PIP_PACKAGES["x11"]

        Pip.install(packages, upgrade=True, dry_run=self._args.dry_run)
