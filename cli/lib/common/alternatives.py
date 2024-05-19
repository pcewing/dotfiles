#!/usr/bin/env python

import subprocess

from .log import Log


class Alternatives:
    @staticmethod
    def install(
        link: str, name: str, path: str, priority: int, sudo: bool, dry_run: bool
    ):
        Log.info(
            "Adding alternative",
            [("link", link), ("name", name), ("path", path), ("priority", priority)],
        )
        if dry_run:
            Log.info("skip adding alternative due to --dry-run")
            return
        cmd = []
        if sudo:
            cmd.append("sudo")
        cmd += ["update-alternatives", "--install", link, name, path, str(priority)]
        if subprocess.call(cmd) != 0:
            raise Exception("update-alternatives failed")

    @staticmethod
    def set(name: str, path: str, sudo: bool, dry_run: bool):
        Log.info("setting alternative", [("name", name), ("path", path)])
        if dry_run:
            Log.info("skip setting alternative due to --dry-run")
            return
        cmd = []
        if sudo:
            cmd.append("sudo")
        cmd += ["update-alternatives", "--set", name, path]
        if subprocess.call(cmd) != 0:
            raise Exception("update-alternatives failed")
