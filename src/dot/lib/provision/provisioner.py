#!/usr/bin/env python

from abc import ABC, abstractmethod

from dot.lib.provision.tag import Tags


class ProvisionerArgs:
    def __init__(
        self,
        dry_run: bool,
        tags: Tags,
        force: bool = False,
        update: bool = True,
        upgrade: bool = False,
    ) -> None:
        self.dry_run: bool = dry_run
        self.tags: Tags = tags
        self.force: bool = force
        # Whether the apt provisioner should run `apt-get update`
        self.update: bool = update
        # Whether the apt provisioner should run `apt-get dist-upgrade`
        self.upgrade: bool = upgrade


class IProvisioner(ABC):
    @abstractmethod
    def provision(self) -> None:
        pass


class IComponentProvisioner(IProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args


class ISystemProvisioner(IProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args
