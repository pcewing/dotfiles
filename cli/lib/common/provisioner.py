#!/usr/bin/env python

from abc import ABC, abstractmethod

from typing import List


class ProvisionerArgs:
    def __init__(self, dry_run):
        self.dry_run = dry_run


class IComponentProvisioner(ABC):
    @abstractmethod
    def provision(self) -> None:
        pass


class ISystemProvisioner(ABC):
    @abstractmethod
    def provision_components(self, components: List[str]) -> None:
        pass

    @abstractmethod
    def provision_all_components(self) -> None:
        pass

    @abstractmethod
    def get_component_provisioners(self) -> List[str]:
        pass

class Provisioners:
    _registry = {}

    @staticmethod
    def register(name: str, provisioner: ISystemProvisioner) -> None:
        Provisioners._registry[name] = provisioner

    @staticmethod
    def get(name: str, args: ProvisionerArgs) -> ISystemProvisioner:
        return Provisioners._registry[name](args)
