#!/usr/bin/env python

import subprocess

from .log import Log


class Group:
    @staticmethod
    def add_user(group: str, user: str, dry_run: bool) -> None:
        Log.info("adding user to group", [("user", user), ("group", group)])

        if Group._is_user_in_group(group, user):
            Log.info("skipping adding user", [("reason", "already a member")])
            return

        if dry_run:
            Log.info("skipping adding user", [("reason", "dry run")])
        else:
            cmd = ["sudo", "usermod", "-aG", group, user]
            if subprocess.call(cmd) != 0:
                raise Exception("failed to add user to group")

    @staticmethod
    def _is_user_in_group(group: str, user: str):
        try:
            groups_output = subprocess.check_output(["groups", user])
            groups = groups_output.decode("utf-8").strip().split(":")[-1].split()
            return group in groups
        except subprocess.CalledProcessError:
            # If the 'groups' command fails (for example, if the user doesn't exist), return False
            return False
