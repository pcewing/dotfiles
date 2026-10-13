#!/usr/bin/env python

from dot.lib.common.pipx import Pipx
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

# Python command line tools that need to be on PATH outside of the dotfiles
# virtualenv, for example language servers started by Neovim. pipx gives each
# one its own virtualenv and links its executables into ~/.local/bin.
#
# fmt: off
PIPX_PACKAGES = [
    "jedi-language-server",
]
# fmt: on


class PipxProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        Pipx.install(PIPX_PACKAGES, upgrade=True, dry_run=self._args.dry_run)
