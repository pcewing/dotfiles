#!/usr/bin/env python

from abc import ABC, abstractmethod

from typing import List

from .log import Log
from .provisioner import ProvisionerArgs, ISystemProvisioner

from .provisioner_docker import DockerProvisioner
from .provisioner_flavours import FlavoursProvisioner
from .provisioner_apt import AptProvisioner
from .provisioner_kitty import KittyProvisioner
from .provisioner_neovim import NeovimProvisioner
from .provisioner_treesitter import TreeSitterProvisioner
from .provisioner_ripgrep import RipgrepProvisioner
from .provisioner_i3 import I3Provisioner
from .provisioner_nodejs import NodeJSProvisioner


# As of Python 3.7:
# > The insertion-order preservation nature of dict objects has been declared
# > to be an official part of the Python language spec.
#
# So, these will remain in order when iterating through the map which is
# important because some component provisioners may depend on others having
# already run, such as an apt update. We could enforce this more explicitly
# through a dependency system but that seems like overkill.
#
# TODO: I don't love how this is setup up. Right now this file shouldn't need
# to import all of the component provisioner types. Maybe we can make like a
# ComponentProvisionerRegistry and all of them can register themselves and then
# this class can just grab them from the registry.
#
# fmt: off
_COMPONENT_PROVISIONERS = {
    "apt":          AptProvisioner,
    "docker":       DockerProvisioner,
    "kitty":        KittyProvisioner,
    "flavours":     FlavoursProvisioner,
    "neovim":       NeovimProvisioner,
    "tree-sitter":  TreeSitterProvisioner,
    "ripgrep":      RipgrepProvisioner,
    "i3":           I3Provisioner,
    "nodejs":       NodeJSProvisioner,
    # TODO: install_cava        "$cache_dir"
    # TODO: install_youtube-dl  "$cache_dir" "$bin_dir"
    # TODO: install_wpr         "$cache_dir" "$bin_dir"
    # TODO: install_mpd
    # TODO: install_ncmpcpp
}
# fmt: on


def _all_components() -> list[str]:
    return _COMPONENT_PROVISIONERS.keys()


class SystemProvisioner(ISystemProvisioner):
    def __init__(self, args: ProvisionerArgs, components: list[str]) -> None:
        self._args = args
        self._components = components if len(components) > 0 else _all_components()

    def provision(self) -> None:
        component_provisioners = {}
        for component in self._components:
            if component not in _COMPONENT_PROVISIONERS:
                raise Exception(f"component not supported: {component}")
            component_provisioners[component] = _COMPONENT_PROVISIONERS[component](
                self._args
            )

        for component in component_provisioners:
            Log.info("provisioning component", [("component", component)])
            component_provisioners[component].provision()

    @staticmethod
    def get_provisioner_list() -> list[str]:
        return _all_components()
