#!/usr/bin/env python

# Walk a directory tree and look for Git repositories that may have changes
# that are either not committed or not pushed.

import argparse
import os
import subprocess
import sys
from typing import Optional

DOTFILES_DIR = os.getenv("DOTFILES")
if DOTFILES_DIR is None:
    raise Exception("DOTFILES environment variable not specified")
sys.path.append(os.path.join(DOTFILES_DIR, "cli"))

from lib.common.file_walker import FileWalker
from lib.common.log import Log


def run_command(cmd: list[str]) -> list[str]:
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    stdout, stderr = p.communicate()
    if p.returncode != 0:
        raise Exception(f"Command returned non-zero: returncode = {p.returncode}")

    return list(
        filter(
            lambda line: line != "",
            [line.strip() for line in stdout.split("\n")],
        )
    )


class GitRepoStatus:
    def __init__(self, dir: str) -> None:
        self._dir = dir

        # TODO: Differentiate between staged and unstaged and add other file
        # statuses
        self.modified_files: list[str] = []
        self.untracked_files: list[str] = []

        self.deleted_files: list[str] = []

        lines = run_command(["git", "-C", self._dir, "status", "--short"])

        for line in lines:
            file_status, file_path = line.split(" ", 1)
            file_status = file_status.strip().lower()
            file_path = file_path.strip().lower()

            if file_status == "m":
                self.modified_files.append(file_path)
            elif file_status == "d":
                self.deleted_files.append(file_path)
            elif file_status == "??":
                self.untracked_files.append(file_path)
            else:
                raise Exception(
                    f"Unknown file status; dir = {self._dir}, file_status = {file_status}"
                )

    def print_full_status(self) -> None:
        subprocess.call(["git", "-C", self._dir, "status"])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="TODO")
    parser.add_argument(
        "directory",
        default=".",
        nargs="?",
        help="Top level directory to start scanning from",
    )
    return parser.parse_args()


def is_git_repository(dir: str) -> bool:
    return os.path.isdir(os.path.join(dir, ".git"))


def has_uncommitted_changes(status: GitRepoStatus) -> bool:
    if len(status.modified_files) > 0:
        return True
    if len(status.untracked_files) > 0:
        return True
    return False


def get_status(dir: str) -> GitRepoStatus:
    return GitRepoStatus(dir)


def handle_git_repository(dir: str) -> None:
    status = get_status(dir)
    if not has_uncommitted_changes(status):
        return

    print("\n================================================================================")
    print("Repository: " + dir + "\n")
    status.print_full_status()


def handle_dir(
    dir: FileWalker.Directory,
) -> Optional[FileWalker.DirectoryHandlerResult]:
    dir_path = dir.get_absolute_path()
    if not is_git_repository(dir_path):
        return None

    handle_git_repository(dir_path)

    # Don't recurse into Git repositories
    return FileWalker.DirectoryHandlerResult(skip=True)


def main() -> None:
    args = parse_args()

    log_level = Log.parse_level("info")
    Log.init("git_pending_changes.py", log_level)

    FileWalker.walk(
        os.path.realpath(args.directory),
        file_handler=None,
        directory_handler=handle_dir,
    )


if __name__ == "__main__":
    main()
