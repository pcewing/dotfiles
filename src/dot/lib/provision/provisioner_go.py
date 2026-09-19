#!/usr/bin/env python

import os
import shutil
import subprocess

from dot.lib.common.apt import Apt
from dot.lib.common.log import Log
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

GO_PACKAGES = [
    "golang-go",
]

GO_TOOLS = [
    "golang.org/x/tools/gopls@latest",
    "github.com/go-delve/delve/cmd/dlv@latest",
]


class GoProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        Apt.install(GO_PACKAGES, self._args.dry_run)

        if self._args.dry_run:
            Log.info("would install go tools", {"tools": GO_TOOLS})
            return

        if shutil.which("go") is None:
            raise Exception("go is not installed")

        gobin = os.path.join(os.path.expanduser("~"), "go", "bin")
        os.makedirs(gobin, exist_ok=True)

        env = {**os.environ, "GOBIN": gobin}

        for tool in GO_TOOLS:
            Log.info("installing go tool", {"tool": tool})
            if subprocess.call(["go", "install", tool], env=env) != 0:
                raise Exception(f"Failed to install go tool {tool}")
