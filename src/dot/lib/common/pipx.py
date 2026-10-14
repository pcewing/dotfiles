#!/usr/bin/env python

import subprocess

from dot.lib.common.log import Log


class Pipx:
    @staticmethod
    def install(
        packages: list[str],
        upgrade: bool = False,
        dry_run: bool = False,
    ) -> None:
        Log.info("installing pipx packages", {"packages": packages})
        if dry_run:
            Log.info("skipping pipx install due to --dry-run")
            return

        for package in packages:
            # `pipx install` exits successfully without changing anything when
            # the package is already installed, so upgrading is a separate step.
            if subprocess.call(["pipx", "install", package]) != 0:
                raise Exception(f"Pipx install failed for {package}")

            if upgrade and subprocess.call(["pipx", "upgrade", package]) != 0:
                raise Exception(f"Pipx upgrade failed for {package}")
