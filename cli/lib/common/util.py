#!/usr/bin/env python

import os
import shutil
import subprocess
import urllib.request

from lib.common.log import Log
from lib.common.shell import Shell


def sh(cmd: list[str], check: bool = False) -> int:
    Log.debug(f"Executing shell command: {' '.join(cmd)}")
    if check:
        subprocess.check_call(cmd)
        return 0
    else:
        return subprocess.call(cmd)


def mkdir_p(path: str, dry_run: bool) -> None:
    Log.info("creating directory:", {"path": path})

    if dry_run:
        Log.info("skipping directory creation due to --dry-run")
    else:
        os.makedirs(path, exist_ok=True)


def sudo_mkdir_p(path: str, dry_run: bool) -> None:
    Log.info("creating directory:", {"path": path})

    if dry_run:
        Log.info("skipping directory creation due to --dry-run")
    else:
        if sh(["sudo", "mkdir", "-p", path]) != 0:
            raise Exception("Failed to create directory")


def sudo_rmdir(path: str, dry_run: bool) -> None:
    Log.info("deleting directory:", {"path": path})

    if dry_run:
        Log.info("skipping directory deletion due to --dry-run")
    else:
        if sh(["sudo", "rm", "-rf", path]) != 0:
            raise Exception("Failed to delete directory")


def sudo_mvdir(src: str, dst: str, dry_run: bool) -> None:
    Log.info("moving directory:", {"from": src, "to": dst})

    if dry_run:
        Log.info("skipping directory move due to --dry-run")
    else:
        if sh(["sudo", "mv", src, dst]) != 0:
            raise Exception("Failed to move directory")


def download_file(url: str, path: str, sudo: bool, force: bool, dry_run: bool) -> None:
    Log.info("downloading file", {"url": url, "path": path})

    if os.path.isfile(path) and not force:
        Log.info(
            "skipping download", [("path", path), ("reason", "file already exists")]
        )
        return

    # Make sure the directory we are downloading to exists
    Shell.mkdir(os.path.dirname(path), True, sudo, dry_run)

    if dry_run:
        Log.info("skipping download", {"path": path, "reason": "dry run"})
    else:
        urllib.request.urlretrieve(url, path)


def write_file(path: str, content: str, sudo: bool, dry_run: bool) -> None:
    Shell.mkdir(
        path=os.path.dirname(path),
        exist_ok=True,
        sudo=sudo,
        dry_run=dry_run,
    )

    Log.info("creating file", {"path": path, "sudo": sudo})

    if dry_run:
        Log.info("skipping file creation", {"reason": "dry run"})
        return

    # TODO: Handle sudo
    with open(path, "w") as f:
        f.write(content)


# TODO: Remove and use Dir.home() everywhere instead
_HOME = None


def home() -> str:
    global _HOME
    if _HOME is None:
        _HOME = os.getenv("HOME")
        if _HOME is None:
            raise Exception("Missing HOME environment variable")
    return _HOME


class Util:
    @staticmethod
    def rmdir(path: str, ignore_missing: bool = True) -> None:
        try:
            shutil.rmtree(path)
        except FileNotFoundError:
            if not ignore_missing:
                raise
