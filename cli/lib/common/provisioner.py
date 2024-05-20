#!/usr/bin/env python

from abc import ABC, abstractmethod


class ProvisionerArgs:
    def __init__(self, dry_run, tags):
        self.dry_run = dry_run
        self.tags = tags


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
