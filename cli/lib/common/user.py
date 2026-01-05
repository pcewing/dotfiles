#!/usr/bin/env python

import os
import subprocess

from lib.common.log import Log
from lib.common.os import OperatingSystem


# TODO: Created this without realizing group.py already exists, merge the two
class Group:
    def __init__(self, name, id, members):
        self._name = name
        self._id = id
        self._members = members

    def get_name(self) -> str:
        return self._name

    def get_id(self) -> str:
        return self._id

    def get_members(self) -> list[str]:
        return self._members


class User:
    def __init__(self, name, uid, gid, home, shell):
        self._name = name
        self._uid = uid
        self._gid = gid
        self._home = home
        self._shell = shell

    def get_name(self) -> str:
        return self._name

    def get_uid(self) -> str:
        return self._uid

    def get_gid(self) -> str:
        return self._gid

    def get_home(self) -> str:
        return self._home

    def get_shell(self) -> str:
        return self._shell

    def get_groups(self) -> List[str]:
        operating_system = OperatingSystem.get()
        if operating_system.is_linux():
            return self._get_groups_linux()
        else:
            raise Exception(
                f"Operating system {operating_system.get_name()} not supported"
            )

    def _get_groups_linux(self) -> List[str]:
        import grp

        # Get the groups that the user is in
        groups = [g for g in grp.getgrall() if self._name in g.gr_mem]

        # Append the user's default group
        groups.append(grp.getgrgid(self._gid))

        # Convert to platform-agnostic Group type
        return [Group(g.gr_name, g.gr_gid, g.gr_mem) for g in groups]

    # TODO: Remove dry run stuff
    # TODO: I actually don't know if this was even used? I think we used group.py
    def add_to_group(self, group: str, dry_run: bool) -> None:
        groups = set(self.get_groups())
        if group in groups:
            Log.info(f'User {self._name} is already in group "{group}", skipping add')
            return

        Log.info(f'Adding user {self._name} to group "{group}"')
        if dry_run:
            Log.info("skipping adding to group due to --dry-run")
        else:
            cmd = ["sudo", "usermod", "-aG", group, user._name]
            if subprocess.call(cmd) != 0:
                raise Exception("Failed to add user to docker group")

    @staticmethod
    def get_current() -> "User":
        operating_system = OperatingSystem.get()
        if operating_system.is_linux():
            return User._get_current_linux()
        else:
            raise Exception(
                f"Operating system {operating_system.get_name()} not supported"
            )

    @staticmethod
    def _get_current_linux() -> "User":
        import pwd

        passwd = pwd.getpwuid(os.getuid())
        return User(
            passwd.pw_name,
            passwd.pw_uid,
            passwd.pw_gid,
            passwd.pw_dir,
            passwd.pw_shell,
        )
