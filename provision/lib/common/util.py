#!/usr/bin/env python

import grp
import os
import pwd
import subprocess
import urllib.request
from typing import Dict, List

from .typing import StringOrNone

from ..common.log import Log


def sh(cmd) -> None:
    Log.debug(f"Executing shell command: {' '.join(cmd)}")
    return subprocess.call(cmd)


def get_home_dir() -> str:
    home: StringOrNone = os.getenv("HOME")
    if home is None:
        raise Exception("HOME environment variable is missing")
    return home


def mkdir_p(path: str, dry_run: bool) -> None:
    Log.info("Creating directory:", [("path", path)])

    if dry_run:
        Log.info("Skipping directory creation due to --dry-run")
    else:
        os.makedirs(path, exist_ok=True)


def sudo_mkdir_p(path: str, dry_run: bool) -> None:
    Log.info("Creating directory:", [("path", path)])

    if dry_run:
        Log.info("Skipping directory creation due to --dry-run")
    else:
        if sh(["sudo", "mkdir", "-p", path]) != 0:
            raise Exception("Failed to create directory")


def sudo_rmdir(path: str, dry_run: bool) -> None:
    Log.info("Deleting directory:", [("path", path)])

    if dry_run:
        Log.info("Skipping directory deletion due to --dry-run")
    else:
        if sh(["sudo", "rm", "-rf", path]) != 0:
            raise Exception("Failed to delete directory")

def sudo_mvdir(src: str, dst: str, dry_run: bool) -> None:
    Log.info("Moving directory:", [("from", src), ("to", dst)])

    if dry_run:
        Log.info("Skipping directory move due to --dry-run")
    else:
        if sh(["sudo", "mv", src, dst]) != 0:
            raise Exception("Failed to move directory")

def download_file(url: str, dst: str, dry_run: bool) -> None:
    Log.info("Downloading file:")
    Log.info(f"- URL = {url}")
    Log.info(f"- Path = {dst}")

    if dry_run:
        Log.info("Skipping download due to --dry-run")
    else:
        urllib.request.urlretrieve(url, dst)


def get_current_user() -> pwd.struct_passwd:
    return pwd.getpwuid(os.getuid())


def get_user_groups(user: pwd.struct_passwd) -> List[str]:
    # Get the groups that the user is in
    groups = [g.gr_name for g in grp.getgrall() if user.pw_name in g.gr_mem]

    # Append the user's default group
    gid = pwd.getpwnam(user.pw_name).pw_gid
    groups.append(grp.getgrgid(gid).gr_name)
    return groups


def add_user_to_group(group: str, dry_run: bool) -> None:
    user = get_current_user()

    groups = set(get_user_groups(user))
    if group in groups:
        Log.info(f'User {user.pw_name} is already in group "{group}", skipping add')
        return

    Log.info(f'Adding user {user} to group "{group}"')
    if dry_run:
        Log.info("Skipping adding to group due to --dry-run")
    else:
        cmd = ["sudo", "usermod", "-aG", "docker", user.pw_name]
        if subprocess.call(cmd) != 0:
            raise Exception("Failed to add user to docker group")
