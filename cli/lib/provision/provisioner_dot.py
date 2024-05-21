#!/usr/bin/env python

import os
import subprocess

from lib.common.dir import Dir
from lib.common.log import Log
from lib.common.util import write_file
from lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs


class DotProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        write_file(
            os.path.join(Dir.home(), ".bash_completion.d", "dot.bash"),
            self._generate_dot_cli_completion_script(),
            sudo=False,
            dry_run=self._args.dry_run,
        )

    def _generate_dot_cli_completion_script(self) -> str:
        cmd = [
            "register-python-argcomplete",
            "--external-argcomplete-script",
            os.path.join(Dir.dot(), "cli/dot.py"),
            "dot",
        ]

        Log.info("generating dot cli completion script", [("command", " ".join(cmd))])

        if self._args.dry_run:
            Log.info(
                "skipping dot cli completion script generation", [("reason", "dry run")]
            )
            return ""

        p = subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
        )
        output, _ = p.communicate()
        if p.returncode != 0:
            print(p)
            raise Exception("register-python-argcomplete script returned non-zero")
        return output
