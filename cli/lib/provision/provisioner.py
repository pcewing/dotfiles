#!/usr/bin/env python

from abc import ABC, abstractmethod

from lib.provision.tag import Tags


class ProvisionerArgs:
    def __init__(self, dry_run: bool, tags: Tags) -> None:
        self.dry_run: bool = dry_run
        self.tags: Tags = tags


class IProvisioner(ABC):
    @abstractmethod
    def provision(self) -> None:
        pass


class IComponentProvisioner(IProvisioner):
    def __init__(self) -> None:
        pass


class ISystemProvisioner(IProvisioner):
    def __init__(self) -> None:
        pass
