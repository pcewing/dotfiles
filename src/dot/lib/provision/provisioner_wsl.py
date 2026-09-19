#!/usr/bin/env python

import os

from dot.lib.common.dir import Dir
from dot.lib.common.log import Log
from dot.lib.common.shell import Shell
from dot.lib.common.util import download_file
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs
from dot.lib.provision.tag import Tags

WEZTERM_SH_URL = (
    "https://raw.githubusercontent.com/wez/wezterm/main/"
    "assets/shell-integration/wezterm.sh"
)


class WslProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        if not self._args.tags.has(Tags.wsl):
            Log.info("skipping wsl provisioner", {"reason": "wsl tag not present"})
            return

        self._install_wezterm_shell_integration()

    def _install_wezterm_shell_integration(self) -> None:
        dest = os.path.join(Dir.home(), "wezterm.sh")

        if os.path.isfile(dest) and not self._args.force:
            Log.info("wezterm.sh already exists, skipping download", {"path": dest})
            return

        Log.info("downloading wezterm shell integration")
        download_file(WEZTERM_SH_URL, dest, False, True, self._args.dry_run)
        Shell.chmod("+x", dest, False, self._args.dry_run)
