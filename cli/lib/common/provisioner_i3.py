#!/usr/bin/env python

import os
import subprocess
import re
from typing import Union, Tuple

from .github import Github
from .log import Log
from .provisioner import IComponentProvisioner, ProvisionerArgs
from .semver import Semver
from .shell import Shell
from .dir import Dir
from .apt import Apt
from .pip import Pip
from .alternatives import Alternatives
from .git import Git


I3_GITHUB_ORG = "i3"
I3_GITHUB_REPO = "i3"

class I3Provisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        latest_tag_name, latest_tag_version = I3Provisioner._get_latest_tag()
        current_version = I3Provisioner._get_current_version()
        print(current_version)
        if current_version is None:
            Log.info(f"i3 is not installed")
        elif current_version < latest_tag_version:
            Log.info(
                f"i3 {current_version} is installed but {latest_tag_version} is available"
            )
        else:
            Log.info(f"i3 {latest_tag_version} is already installed, nothing to do")
            return

        # TODO: i3-gaps was merged into i3 as of release 4.22 but the version
        # in Apt in Ubuntu 22.04 is still 4.20 so build it from source for now.
        # Once we move to 24.04 we can probably just install the apt package
        # and remove this whole provisioner.

        # Install pre-requisite packages needed to compile i3 from source
        Apt.install([
            "libxcb1-dev",
            "libxcb-keysyms1-dev",
            "libpango1.0-dev",
            "libxcb-util0-dev",
            "libxcb-icccm4-dev",
            "libyajl-dev",
            "libstartup-notification0-dev",
            "libxcb-randr0-dev",
            "libev-dev",
            "libxcb-cursor-dev",
            "libxcb-xinerama0-dev",
            "libxcb-xkb-dev",
            "libxkbcommon-dev",
            "libxkbcommon-x11-dev",
            "autoconf",
            "libxcb-xrm0",
            "libxcb-xrm-dev",
            "libxcb-shape0",
            "libxcb-shape0-dev",
            "automake",
        ], self._args.dry_run)

        # TODO: Clone the i3 repository
        #try git clone "https://www.github.com/Airblader/i3" "$i3gaps_dir"
        url = f"https://www.github.com/{I3_GITHUB_ORG}/{I3_GITHUB_REPO}"
        path = "/home/pewing/.tmp/TODO"

        Shell.rm(path, True, True, False, self._args.dry_run)
        repo = Git.clone(url, path, self._args.dry_run)

        # TODO: Checkout the desired release tag
        repo.checkout(latest_tag_name, self._args.dry_run)

        # TODO: Build i3 from source


    @staticmethod
    def _get_latest_tag() -> Tuple[str, Semver]:
        tags = Github.get_tags(I3_GITHUB_ORG, I3_GITHUB_REPO)
        semver_tags = {}
        for tag in tags:
            tag_name = tag["name"]
            m = re.match("[0-9]+\.[0-9]+(\.[0-9]){0,1}", tag_name)
            if m is not None:
                semver_tags[tag_name] = Semver.parse(tag_name)
        return sorted(semver_tags.items(), reverse=True)[0]


    @staticmethod
    def _get_current_version() -> Union[str, None]:
        try:
            p = subprocess.Popen(
                ["i3", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("i3 returned non-zero exit code")
            m = re.match("i3 version ([0-9]+\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError as e:
            return None
