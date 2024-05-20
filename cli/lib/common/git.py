#!/usr/bin/env python

import subprocess

from lib.common.log import Log


class GitRepository:
    def __init__(self, url, path):
        self._url = url
        self._path = path

    def checkout(self, target: str, dry_run: bool) -> None:
        Log.info("checking out git target", [("target", target)])

        if dry_run:
            Log.info("skipping git checkout", [("reason", "dry run")])
            return

        cmd = [
            "git",
            f"--git-dir={self._path}/.git",
            f"--work-tree={self._path}",
            "checkout",
            target,
        ]

        if subprocess.call(cmd) != 0:
            raise Exception("Failed to check out git target")


class Git:
    @staticmethod
    def clone(url: str, path: str, dry_run: bool) -> GitRepository:
        Log.info("cloning git repository", [("url", url, "path", path)])
        if dry_run:
            Log.info("skipping git clone", [("reason", "dry run")])
        else:
            if subprocess.call(["git", "clone", url, path]) != 0:
                raise Exception("Failed to clone git repository")
        return GitRepository(url, path)
