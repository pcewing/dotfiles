#!/usr/bin/env python

import os
import subprocess

from lib.common.log import Log


# I originally used these instead of Python's native facilities because it was
# easier to deal with elevating to root this way. I think instead I'm going to
# just have the script elevate itself which simplifies things a bit.
class Shell:
    @staticmethod
    def mkdir(path: str, exist_ok: bool, sudo: bool, dry_run: bool) -> None:
        Log.info("creating directory", {"path": path})

        if dry_run:
            Log.info("skipping directory creation", {"reason": "dry run"})
            return

        cmd = []
        if sudo:
            cmd.append("sudo")
        cmd.append("mkdir")
        if exist_ok:
            cmd.append("-p")
        cmd.append(path)
        if Shell._exec(cmd) != 0:
            raise Exception("Failed to create directory")

    @staticmethod
    def rm(path: str, recursive: bool, force: bool, sudo: bool, dry_run: bool) -> None:
        Log.info("removing file or directory", {"path": path})
        if dry_run:
            Log.info("skipping removal due to --dry-run")
            return

        cmd = ["sudo"] if sudo else []
        cmd.append("rm")
        if force:
            cmd.append("--force")
        if recursive:
            cmd.append("--recursive")
        cmd.append(path)
        if Shell._exec(cmd) != 0:
            raise Exception("Failed to remove file or directory")

    @staticmethod
    def mv(src: str, dst: str, sudo: bool, dry_run: bool) -> None:
        Log.info("moving file or directory", {"from": src, "to": dst})

        if dry_run:
            Log.info("skipping directory move due to --dry-run")
            return

        cmd = ["sudo"] if sudo else []
        cmd += ["mv", src, dst]
        if Shell._exec(cmd) != 0:
            raise Exception("Failed to move file or directory")

    @staticmethod
    def ln(source: str, target: str, sudo: bool, dry_run: bool) -> None:
        Log.info("creating symbolic link", {"source": source, "target": target})

        if dry_run:
            Log.info("skipping symbolic link creation due to --dry-run")
            return

        cmd = ["sudo"] if sudo else []
        cmd += ["ln", "-s", source, target]
        if Shell._exec(cmd) != 0:
            raise Exception("Failed to create symbolic link")

    @staticmethod
    def chmod(mod: str, file: str, sudo: bool, dry_run: bool) -> None:
        Log.info("changing file permissions", {"file": file, "permissions": mod})

        if dry_run:
            Log.info("skipping file permission update creation due to --dry-run")
            return

        cmd = ["sudo"] if sudo else []
        cmd += ["chmod", mod, file]
        if Shell._exec(cmd) != 0:
            raise Exception("Failed to update file permissions")

    @staticmethod
    def cd(path: str, dry_run: bool) -> None:
        Log.info("changing directory", {"path": path})
        if dry_run:
            Log.info("skipping directory change", {"reason": "dry run"})
            return
        os.chdir(path)

    @staticmethod
    def _exec(cmd: list[str]) -> int:
        Log.debug("executing shell command", {"command": " ".join(cmd)})
        return subprocess.call(cmd)
