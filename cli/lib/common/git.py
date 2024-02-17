#!/usr/bin/env python

class GitRepository:
    def __init__(self):
        raise Exception("not yet implement")
        self._root = "TODO"
        pass

    def checkout(self, target: str) -> None:
        raise Exception("not yet implement")
        cmd = [
            "git",
                f"--git-dir={self._root}/.git",
                f"--work-tree={self._root}",
                "checkout",
                target,
        ]

class Git:
    @staticmethod
    def clone() -> GitRepository:
        raise Exception("not yet implement")
        return GitRepository(TODO)

