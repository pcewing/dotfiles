#!/usr/bin/env python

import os
import subprocess
import sys
from typing import Optional

from dot.lib.common.dir import Dir
from dot.lib.common.log import Log
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs


class DotProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        completion_path = os.path.join(
            Dir.home(), ".config", "bash", "completions", "dot"
        )

        if self._args.dry_run:
            Log.info("would generate dot CLI completion", {"path": completion_path})
            return

        content = self._generate_completion_script()
        if content is None:
            return

        os.makedirs(os.path.dirname(completion_path), exist_ok=True)
        with open(completion_path, "w") as f:
            f.write(content)
        Log.info("wrote dot CLI completion", {"path": completion_path})

    def _generate_completion_script(self) -> Optional[str]:
        # Prefer the register-python-argcomplete that lives next to the Python
        # interpreter running this CLI (i.e. in the dotfiles virtualenv).
        venv_script = os.path.join(
            os.path.dirname(sys.executable), "register-python-argcomplete"
        )
        if os.path.isfile(venv_script):
            cmd = [venv_script, "dot"]
        else:
            cmd = ["register-python-argcomplete", "dot"]

        Log.info("generating dot CLI completion script", {"command": " ".join(cmd)})

        try:
            p = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
        except FileNotFoundError:
            Log.warn("register-python-argcomplete not found; skipping completion")
            return None

        output, _ = p.communicate()
        if p.returncode != 0:
            Log.warn(
                "register-python-argcomplete returned non-zero",
                {"exit_code": p.returncode},
            )
            return None

        return output
