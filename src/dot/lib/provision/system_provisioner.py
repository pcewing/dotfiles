#!/usr/bin/env python

from dot.lib.common.log import Log
from dot.lib.provision.provisioner import (
    IComponentProvisioner,
    ISystemProvisioner,
    ProvisionerArgs,
)
from dot.lib.provision.provisioner_apt import AptProvisioner
from dot.lib.provision.provisioner_docker import DockerProvisioner
from dot.lib.provision.provisioner_dot import DotProvisioner
from dot.lib.provision.provisioner_dotnet import DotnetProvisioner
from dot.lib.provision.provisioner_flavours import FlavoursProvisioner
from dot.lib.provision.provisioner_go import GoProvisioner
from dot.lib.provision.provisioner_java import JavaProvisioner
from dot.lib.provision.provisioner_kitty import KittyProvisioner
from dot.lib.provision.provisioner_links import LinksProvisioner
from dot.lib.provision.provisioner_neovim import NeovimProvisioner
from dot.lib.provision.provisioner_nodejs import NodeJSProvisioner
from dot.lib.provision.provisioner_pip import PipProvisioner
from dot.lib.provision.provisioner_ripgrep import RipgrepProvisioner
from dot.lib.provision.provisioner_rust import RustProvisioner
from dot.lib.provision.provisioner_system import SystemConfigProvisioner
from dot.lib.provision.provisioner_treesitter import TreeSitterProvisioner
from dot.lib.provision.provisioner_win32yank import Win32YankProvisioner
from dot.lib.provision.provisioner_wpr import WprProvisioner
from dot.lib.provision.provisioner_wsl import WslProvisioner

# As of Python 3.7, dicts preserve insertion order. The order matters because
# some components depend on others having already run (for example, the system
# component sets update-alternatives for binaries installed by the neovim and
# kitty components).
#
# fmt: off
_COMPONENT_PROVISIONERS: dict[str, type[IComponentProvisioner]] = {
    "apt":          AptProvisioner,
    "pip":          PipProvisioner,
    "nodejs":       NodeJSProvisioner,
    "go":           GoProvisioner,
    "rust":         RustProvisioner,
    "java":         JavaProvisioner,
    "dotnet":       DotnetProvisioner,
    "neovim":       NeovimProvisioner,
    "kitty":        KittyProvisioner,
    "flavours":     FlavoursProvisioner,
    "ripgrep":      RipgrepProvisioner,
    "tree-sitter":  TreeSitterProvisioner,
    "wpr":          WprProvisioner,
    "links":        LinksProvisioner,
    "dot":          DotProvisioner,
    "wsl":          WslProvisioner,
    "system":       SystemConfigProvisioner,
    "docker":       DockerProvisioner,
    "win32yank":    Win32YankProvisioner,
}
# fmt: on


def _all_components() -> list[str]:
    return list(_COMPONENT_PROVISIONERS.keys())


class SystemProvisioner(ISystemProvisioner):
    def __init__(self, args: ProvisionerArgs, components: list[str]) -> None:
        super().__init__(args)
        self._components = components if len(components) > 0 else _all_components()

    def provision(self) -> None:
        component_provisioners = {}
        for component in self._components:
            if component not in _COMPONENT_PROVISIONERS:
                raise Exception(f"component not supported: {component}")
            component_provisioners[component] = _COMPONENT_PROVISIONERS[component](
                self._args
            )

        for component, provisioner in component_provisioners.items():
            Log.info("provisioning component", {"component": component})
            provisioner.provision()

    @staticmethod
    def get_provisioner_list() -> list[str]:
        return _all_components()
