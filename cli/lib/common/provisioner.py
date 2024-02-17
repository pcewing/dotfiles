#!/usr/bin/env python

from abc import ABC, abstractmethod

class ProvisionerArgs:
    def __init__(self, dry_run):
        self.dry_run = dry_run

class IProvisioner(ABC):
    @abstractmethod
    def provision(self) -> None:
        pass

class IComponentProvisioner(IProvisioner):
    pass

class ISystemProvisioner(IProvisioner):
    pass
