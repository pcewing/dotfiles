#!/usr/bin/env python

import os
import subprocess

from lib.common.provisioner import IComponentProvisioner, ProvisionerArgs
from lib.common.shell import Shell
from lib.common.dir import Dir
from lib.common.log import Log

# TODO: Move this to somewhere in lib
def _write_file(path: str, content: str, sudo: bool, dry_run: bool) -> None:
    Shell.mkdir(
        path=os.path.dirname(path),
        exist_ok=True,
        sudo=sudo,
        dry_run=dry_run,
    )

    Log.info("creating file", [("path", path), ("sudo", sudo)])

    if dry_run:
        Log.info("skipping file creation", [("reason", "dry run")])
        return

    # TODO: Handle sudo
    with open(path, "w") as f:
        f.write(content)

class DotProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        _write_file(
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
            Log.info("skipping dot cli completion script generation", [("reason", "dry run")])
            return ""

        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        output, _ = p.communicate()
        if p.returncode != 0:
            print(p)
            raise Exception("register-python-argcomplete script returned non-zero")
        return output
