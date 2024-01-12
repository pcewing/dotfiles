#!/usr/bin/env python

from ..common.provisioner import IComponentProvisioner, ProvisionerArgs
from .apt import Apt


class AptInitProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        Apt.update(self._args.dry_run)
        Apt.upgrade(self._args.dry_run)
