#!/usr/bin/env python

import os
import subprocess
import re
from typing import Union

from .github import Github
from .log import Log
from .provisioner import IComponentProvisioner, ProvisionerArgs
from .semver import Semver
from .shell import Shell
from .dir import Dir
from .pip import Pip
from .alternatives import Alternatives
from .git import Git


I3_GITHUB_ORG = "i3"
I3_GITHUB_REPO = "i3"

class I3Provisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        raise Exception("not yet implement")
        latest_release = Github.get_latest_release(I3_GITHUB_ORG, I3_GITHUB_REPO)
        latest_version = Semver.parse(latest_release)

        current_version = I3GapsProvisioner._get_current_version()
        if current_version is None:
            Log.info(f"i3 is not installed")
        elif current_version < latest_version:
            Log.info(
                f"I3Gaps {current_version} is installed but {latest_version} is available"
            )
        else:
            Log.info(f"I3Gaps {latest_version} is already installed, nothing to do")
            return

        # TODO: Install pre-requisite packages needed to compile i3 from source
        # apt_install "libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev autoconf libxcb-xrm0 libxcb-xrm-dev libxcb-shape0 libxcb-shape0-dev automake"

        # TODO: Clone the i3 repository
        #try git clone "https://www.github.com/Airblader/i3" "$i3gaps_dir"
        url = f"https://www.github.com/{I3_GITHUB_ORG}/{I3_GITHUB_REPO}"
        path = "/todo"
        repo = Git.clone(url, path, self._args.dry_run)

        # TODO: Checkout the desired release tag
        repo.checkout(latest_release, self._args.dry_run)

        # TODO: Build i3 from source


    @staticmethod
    def _get_current_version() -> Union[str, None]:
        try:
            p = subprocess.Popen(
                ["nvim", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("I3Gaps returned non-zero exit code")
            m = re.match("i3 version  ([0-9]+\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError as e:
            return None
