#!/usr/bin/env python

import os
import re
import subprocess
from typing import Optional, Tuple

from dot.lib.common.apt import Apt
from dot.lib.common.dir import Dir
from dot.lib.common.github import Github
from dot.lib.common.log import Log
from dot.lib.common.semver import Semver
from dot.lib.common.version_cache import VersionCache
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

RIPGREP_GITHUB_ORG = "BurntSushi"
RIPGREP_GITHUB_REPO = "ripgrep"


class RipgrepProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        latest_release, _ = RipgrepProvisioner._get_target_version()

        current_version = RipgrepProvisioner._get_current_version()
        if current_version is None:
            Log.info("ripgrep is not installed")
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
    def _get_current_version() -> Optional[Semver]:
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
            m = re.match(r"ripgrep ([0-9]+\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError:
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
            version = Semver.parse(cached_version["version"])
            if version is None:
                raise Exception(
                    f"Failed to parse cached ripgrep version {cached_version['version']}"
                )
            return cached_version["version"], version

        try:
            latest_release = Github.get_latest_release(
                RIPGREP_GITHUB_ORG, RIPGREP_GITHUB_REPO
            )
            latest_version = Semver.parse(latest_release)
            if latest_version is None:
                raise Exception(f"Failed to parse ripgrep version {latest_release}")
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
