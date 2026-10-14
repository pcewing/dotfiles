#!/usr/bin/env python

from dot.lib.common.dir import Dir
from dot.lib.common.pip import Pip
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs
from dot.lib.provision.tag import Tags

# Packages installed into the dotfiles virtualenv in addition to the dot
# package itself. The dot package's dependencies and its "dev" extras (the
# Python formatters, linters, and test tools) are declared in pyproject.toml.
#
# fmt: off
PIP_PACKAGES = {
    "core": [
        "pynvim",
        "python-mpd2",
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
        # Re-install the dot package editable so the "dev" extras are installed
        # and kept up to date along with the rest of the packages.
        packages = ["-e", f"{Dir.dot()}[dev]"] + PIP_PACKAGES["core"]

        if self._args.tags.has(Tags.x11):
            packages += PIP_PACKAGES["x11"]

        Pip.install(packages, upgrade=True, dry_run=self._args.dry_run)
