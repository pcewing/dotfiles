#!/usr/bin/env python

import json
import re
import subprocess

from lib.common.log import Log


def _execute_git_command(
    cmd: list[str], strip: bool = True, filter_empty: bool = True
) -> str:
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True)
    stdout, _ = p.communicate()
    if p.returncode != 0:
        raise Exception("Git command failed: {}".format(" ".join(cmd)))
    lines = stdout.split("\n")
    if strip:
        lines = [l.strip() for l in lines]
    if filter_empty:
        lines = [l for l in lines if l != ""]
    return lines


class GitStatus:
    def __init__(self) -> None:
        self.staged_modified: list[str] = []
        self.staged_added: list[str] = []
        self.unstaged_modified: list[str] = []
        self.untracked: list[str] = []

    def is_add_required(self) -> bool:
        return (len(self.unstaged_modified) + len(self.untracked)) > 0

    def is_commit_required(self) -> bool:
        return (
            self.is_add_required() or (len(self.staged_modified) + len(self.staged_added)) > 0
        )

    @staticmethod
    def parse(lines: list[str]) -> "GitStatus":
        status = GitStatus()
        for line in lines:
            status._parse_line(line)
        return status

    def _parse_line(self, line: str) -> None:
        file_status = line[:2]
        file_path = line[2:]

        if len(file_status) != 2 or file_status == "  ":
            raise Exception(f"Invalid file status: {file_status}")

        if file_status == "??":
            self.untracked.append(file_path)
            return

        staged_status = file_status[0]
        if staged_status == " ":
            pass
        elif staged_status == "M":
            self.staged_modified.append(file_path)
        elif staged_status == "A":
            self.staged_added.append(file_path)
        else:
            raise Exception(f"Unknown file status: {file_status}")

        unstaged_status = file_status[1]
        if unstaged_status == " ":
            pass
        elif unstaged_status == "M":
            self.unstaged_modified.append(file_path)
        else:
            raise Exception(f"Unknown file status: {file_status}")

    def to_dict(self):
        return {
            "staged_modified": self.staged_modified,
            "staged_added": self.staged_added,
            "unstaged_modified": self.unstaged_modified,
            "untracked": self.untracked,
        }

    def to_json(self):
        return json.dumps(self.to_dict(), indent=4)

    def __str__(self):
        return self.to_json()


class GitCommit:
    def __init__(self, hash: str, message: str) -> None:
        self.hash = hash
        self.message = message

    def to_dict(self):
        return {
            "hash": self.hash,
            "message": self.message,
        }

    def to_json(self):
        return json.dumps(self.to_dict(), indent=4)

    def __str__(self):
        return self.to_json()


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
        Log.debug("checking out git target", [("target", target)])

        if dry_run:
            Log.debug("skipping git checkout", [("reason", "dry run")])
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
        Log.debug("cloning git repository", [("url", url, "path", path)])
        if dry_run:
            Log.debug("skipping git clone", [("reason", "dry run")])
        else:
            if subprocess.call(["git", "clone", url, path]) != 0:
                raise Exception("Failed to clone git repository")
        return GitRepository(url, path)

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
            raise Exception("Git command failed: {}".format(" ".join(cmd)))
        branches = []
        for line in [l.strip() for l in stdout.split("\n")]:
            if line == "":
                continue
            is_current, name, tracking, hash = line.split(" ")
            branches.append(GitBranch(is_current == "true", name, tracking, hash))
        return branches

    @staticmethod
    def get_current_branch() -> GitBranch:
        Log.debug("getting current branch")
        branches = Git.get_branches()

        for branch in branches:
            if branch.is_current:
                return branch

        raise Exception("Failed to identify current branch")

    @staticmethod
    def get_commits(remote: str = None, limit: int = None) -> list[GitCommit]:
        fmt_hash = "%H"
        fmt_message = "%s"

        fmt = "|".join([fmt_hash, fmt_message])

        cmd = ["git", "log", f"--pretty=format:{fmt}"]

        if limit is not None:
            cmd += ["--max-count", str(limit)]

        if remote is not None:
            cmd.append(remote)

        commits = []
        lines = _execute_git_command(cmd)
        for line in lines:
            hash, message = line.split("|", 1)
            commits.append(GitCommit(hash, message))
        return commits

    @staticmethod
    def fetch_all() -> None:
        Log.debug("fetching all from remotes")
        subprocess.check_call(["git", "fetch", "--all"])

    @staticmethod
    def status() -> GitStatus:
        lines = _execute_git_command(["git", "status", "--short"], strip=False)
        return GitStatus.parse(lines)

    @staticmethod
    def add_all() -> None:
        Log.debug("staging all local changes")
        subprocess.check_call(["git", "add", "--all"])

    @staticmethod
    def commit(message: str) -> None:
        Log.debug("commiting staged changes")
        subprocess.check_call(["git", "commit", "--message", message])

    @staticmethod
    def push(remote: str, branch: str) -> None:
        Log.debug("pushing to remote", [("remote", remote), ("branch", branch)])
        cmd = ["git", "push", remote, branch]
        subprocess.check_call(cmd)

    @staticmethod
    def pull(remote: str, branch: str, rebase: bool = False) -> None:
        Log.debug("pulling from remote", [("remote", remote), ("branch", branch)])
        cmd = ["git", "pull"]
        if rebase:
            cmd.append("--rebase")
        cmd += [remote, branch]
        subprocess.check_call(cmd)

    @staticmethod
    def create_branch(name: str) -> None:
        Log.debug("creating a new branch", [("name", name)])
        subprocess.check_call(["git", "branch", name])

    @staticmethod
    def checkout(target: str) -> None:
        Log.debug("checking out target (branch/hash/tag)", [("target", target)])
        subprocess.check_call(["git", "checkout", target])

    @staticmethod
    def cherry_pick(hash: str) -> None:
        Log.debug("cherry-picking commit", [("hash", hash)])
        subprocess.check_call(["git", "cherry-pick", hash])
