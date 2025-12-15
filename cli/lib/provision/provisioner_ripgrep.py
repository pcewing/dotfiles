#!/usr/bin/env python

import os
import re
import subprocess
from typing import Tuple, Union

from lib.common.apt import Apt
from lib.common.dir import Dir
from lib.common.github import Github
from lib.common.log import Log
from lib.common.semver import Semver
from lib.common.version_cache import VersionCache
from lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

RIPGREP_GITHUB_ORG = "BurntSushi"
RIPGREP_GITHUB_REPO = "ripgrep"


class RipgrepProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        latest_release, _ = RipgrepProvisioner._get_target_version()

        # TODO: Standardize and share this behavior since it's the same in most provisioners
        # Maybe have like a `get_action` function on provisioners that returns one of three possible actions:
        # No-op, Update, Install, and a reason
        current_version = RipgrepProvisioner._get_current_version()
        if current_version is None:
            Log.info(f"ripgrep is not installed")
        elif current_version < Semver.parse(latest_release):
            Log.info(
                f"ripgrep {current_version} is installed but {latest_release} is available"
            )
        else:
            Log.info(f"ripgrep {latest_release} is already installed, nothing to do")
            return

        staging_dir = Dir.staging("ripgrep", latest_release)

        deb_name = f"ripgrep_{latest_release}-1_amd64.deb"
        deb_path = os.path.join(staging_dir, deb_name)

        Github.download_release_artifact(
            RIPGREP_GITHUB_ORG,
            RIPGREP_GITHUB_REPO,
            latest_release,
            deb_name,
            deb_path,
            True,
            False,
            False,
            self._args.dry_run,
        )

        Apt.install_deb_files([deb_path], self._args.dry_run)

    @staticmethod
    def _get_current_version() -> Union[str, None]:
        try:
            p = subprocess.Popen(
                ["rg", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("ripgrep returned non-zero exit code")
            m = re.match("ripgrep ([0-9]+\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError as e:
            return None

    @staticmethod
    def _get_target_version() -> Tuple[str, Semver]:
        cached_version = VersionCache.get_version("ripgrep")
        if cached_version is not None:
            Log.info(
                "using cached ripgrep version",
                {
                    "version": cached_version["version"],
                    "last_attempt": cached_version.get("last_attempt"),
                },
            )
            return cached_version["version"], Semver.parse(cached_version["version"])

        try:
            latest_release = Github.get_latest_release(
                RIPGREP_GITHUB_ORG, RIPGREP_GITHUB_REPO
            )
            latest_version = Semver.parse(latest_release)
        except Exception as e:
            VersionCache.add_failed_attempt(
                "ripgrep",
                str(e),
                source=f"github:{RIPGREP_GITHUB_ORG}/{RIPGREP_GITHUB_REPO}",
            )
            raise

        VersionCache.update_version(
            "ripgrep",
            latest_release,
            f"github:{RIPGREP_GITHUB_ORG}/{RIPGREP_GITHUB_REPO}",
        )

        return latest_release, latest_version
