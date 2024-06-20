#!/usr/bin/env python

import json
import re
import subprocess

from lib.common.log import Log

class GitBranch:
    def __init__(self, is_current: bool, name: str, tracking: str, hash: str) -> None:
        self.is_current = is_current
        self.name = name
        self.tracking = tracking
        self.hash = hash

    def to_dict(self):
        return {
            "name": self.name,
            "is_current": self.is_current,
            "tracking": self.tracking,
            "hash": self.hash,
        }

    def to_json(self):
        return json.dumps(self.to_dict(), indent=4)

    def __str__(self):
        return self.to_json()

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

    @staticmethod
    def get_current_branch() -> str:
        cmd = ["git", "branch", "--show-current"]
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True)
        stdout, _ = p.communicate()
        if p.returncode != 0:
            raise Exception("Git command failed: {}".format(' '.join(cmd)))
        return stdout.strip()

    @staticmethod
    def get_branches() -> list[GitBranch]:
        fmt_is_current = "%(if)%(HEAD)%(then)true%(else)false%(end)"
        fmt_name = "%(refname:short)"
        fmt_tracking = "%(upstream:short)"
        fmt_hash = "%(objectname)"

        fmt = " ".join([fmt_is_current, fmt_name, fmt_tracking, fmt_hash])

        cmd = ["git", "for-each-ref", "--format", fmt, "refs/heads/"]
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True)
        stdout, _ = p.communicate()
        if p.returncode != 0:
            raise Exception("Git command failed: {}".format(' '.join(cmd)))
        branches = []
        for line in [l.strip() for l in stdout.split("\n")]:
            if line == "":
                continue
            is_current, name, tracking, hash = line.split(" ")
            branches.append(GitBranch(is_current == "true", name, tracking, hash))
        return branches
