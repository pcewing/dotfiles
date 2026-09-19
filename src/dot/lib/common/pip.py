#!/usr/bin/env python

import subprocess
import sys
from typing import List

from dot.lib.common.log import Log


class Pip:
    @staticmethod
    def install(
        packages: List[str],
        upgrade: bool = False,
        dry_run: bool = False,
    ) -> None:
        Log.info("installing pip packages", {"packages": packages})
        if dry_run:
            Log.info("skipping pip install due to --dry-run")
            return

        # Always install into the Python environment that is running the CLI.
        # The provisioners are expected to run from the dotfiles virtual
        # environment so this keeps packages out of the system Python.
        cmd = [sys.executable, "-m", "pip", "install"]

        if upgrade:
            cmd.append("--upgrade")

        if subprocess.call(cmd + packages) != 0:
            raise Exception("Pip install failed")
