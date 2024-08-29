#!/usr/bin/env python

import subprocess
from typing import List

from lib.common.log import Log


class Pip:
    @staticmethod
    def install(
        packages: List[str],
        upgrade: bool = False,
        sudo: bool = False,
        dry_run: bool = True,
    ) -> None:
        Log.info("installing pip packages", {"packages": packages})
        if dry_run:
            Log.info("skipping pip install due to --dry-run")
            return

        cmd = []

        if sudo:
            cmd.append("sudo")

        cmd += ["python", "-m", "pip", "install"]

        if upgrade:
            cmd.append("--upgrade")

        if not sudo:
            cmd.append("--user")

        if subprocess.call(cmd + packages) != 0:
            raise Exception("Pip install failed")
