#!/usr/bin/env python

from .log import Log
from .util import sh

# I originally used these instead of Python's native facilities because it was
# easier to deal with elevating to root this way. I think instead I'm going to
# just have the script elevate itself which simplifies things a bit.
class Shell:
    @staticmethod
    def mkdir(path: str, exist_ok: bool, sudo: bool, dry_run: bool) -> None:
        Log.info("Creating directory", [("path", path)])

        if dry_run:
            Log.info("Skipping directory creation due to --dry-run")
            return

        cmd = []
        if sudo:
            cmd.append("sudo")
        cmd.append("mkdir")
        if exist_ok:
            cmd.append("-p")
        cmd.append(path)
        if sh(cmd) != 0:
            raise Exception("Failed to create directory")

    @staticmethod
    def rm(path: str, recursive: bool, force: bool, sudo: bool, dry_run: bool) -> None:
        Log.info("Removing file or directory", [("path", path)])
        if dry_run:
            Log.info("Skipping removal due to --dry-run")
            return

        cmd = ["sudo"] if sudo else []
        cmd.append("rm")
        if force:
            cmd.append("--force")
        if recursive:
            cmd.append("--recursive")
        cmd.append(path)
        if sh(cmd) != 0:
            raise Exception("Failed to remove file or directory")

    @staticmethod
    def mv(src: str, dst: str, sudo: bool, dry_run: bool) -> None:
        Log.info("Moving file or directory", [("from", src), ("to", dst)])

        if dry_run:
            Log.info("Skipping directory move due to --dry-run")
            return

        cmd = ["sudo"] if sudo else []
        cmd += ["mv", src, dst]
        if sh(cmd) != 0:
            raise Exception("Failed to move file or directory")

    @staticmethod
    def ln(src: str, dst: str, sudo: bool, dry_run: bool) -> None:
        Log.info("Creating symbolic link", [("source", src), ("target", dst)])

        if dry_run:
            Log.info("Skipping symbolic link creation due to --dry-run")
            return

        cmd = ["sudo"] if sudo else []
        cmd += ["ln", "-s", src, dst]
        if sh(cmd) != 0:
            raise Exception("Failed to create symbolic link")
