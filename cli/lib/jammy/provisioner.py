#!/usr/bin/env python

from typing import List

from ..common.provisioner import ISystemProvisioner, ProvisionerArgs
from ..common.log import Log
from .provisioner_docker import DockerProvisioner
from .provisioner_flavours import FlavoursProvisioner
from .provisioner_apt_init import AptInitProvisioner


class UbuntuJammyProvisioner(ISystemProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

        # As of Python 3.7:
        # > The insertion-order preservation nature of dict objects has been
        # > declared to be an official part of the Python language spec.
        #
        # So, these will remain in order when iterating through the map which
        # is important because some component provisioners may depend on others
        # having already run, such as an apt update. We could enforce this more
        # explicitly through a dependency system but that seems like overkill.
        # fmt: off
        self._component_provisioners = {
            "apt-init": AptInitProvisioner(args),
            "docker":   DockerProvisioner(args),
            "flavours": FlavoursProvisioner(args),
        }
        # fmt: on

    def get_component_provisioners(self) -> List[str]:
        return list(self._component_provisioners.keys())

    def provision_components(self, components: List[str]) -> None:
        for component in components:
            if component not in self._component_provisioners:
                raise Exception(f"Specified component not supported: {component}")

        for component in components:
            self._provision_component(component)

    def provision_all_components(self) -> None:
        for component in self._component_provisioners:
            self._provision_component(component)

    def _provision_component(self, component: str) -> None:
        Log.info(f"Running {component} provisioner")
        component_provisioner = self._component_provisioners[component]
        component_provisioner.provision()
