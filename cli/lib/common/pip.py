#!/usr/bin/env python

import subprocess

from typing import List
from ..common.log import Log


class Pip:
    @staticmethod
    def install(packages: List[str], upgrade: bool, sudo: bool, dry_run: bool) -> None:
        Log.info("installing pip packages")
        if dry_run:
            Log.info("skipping pip install due to --dry-run")
            return

        cmd = []
        if sudo:
            cmd.append("sudo")
            # TODO
        cmd += ["python3", "-m", "pip", "install"]
        if upgrade:
            cmd.append("--upgrade")
        if subprocess.call(cmd + packages) != 0:
            raise Exception("Pip install failed")
