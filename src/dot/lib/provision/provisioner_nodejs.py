#!/usr/bin/env python

import os
import subprocess
from typing import Optional, Tuple

from dot.lib.common.archive import Archive
from dot.lib.common.dir import Dir
from dot.lib.common.github import Github
from dot.lib.common.log import Log
from dot.lib.common.semver import Semver
from dot.lib.common.shell import Shell
from dot.lib.common.util import download_file
from dot.lib.common.version_cache import VersionCache
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

NODEJS_GITHUB_ORG = "nodejs"
NODEJS_GITHUB_REPO = "node"


class NodeJSProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        current_version = NodeJSProvisioner._get_current_version()
        Log.info(
            "identified current nodejs version",
            {"version": str(current_version)},
        )

        target_release, target_version = NodeJSProvisioner._get_target_version()

        if current_version is None:
            Log.info("nodejs is not installed")
        elif current_version < target_version:
            Log.info(
                f"nodejs {current_version} is installed but {target_version} is available"
            )
        else:
            Log.info(f"nodejs {target_version} is already installed, nothing to do")
            return

        self._install(target_release)

    def _install(self, version: str) -> None:
        staging_dir = Dir.staging("nodejs", version)
        install_dir = Dir.install("nodejs", version)

        nodejs_archive_name = f"node-{version}-linux-x64.tar.xz"
        nodejs_archive_url = f"https://nodejs.org/dist/{version}/{nodejs_archive_name}"
        nodejs_archive_path = os.path.join(staging_dir, nodejs_archive_name)

        download_file(
            nodejs_archive_url, nodejs_archive_path, False, False, self._args.dry_run
        )

        Log.info(
            "extracting nodejs release archive",
            {"archive": nodejs_archive_path, "dst": staging_dir},
        )
        Archive.extract(nodejs_archive_path, staging_dir, self._args.dry_run)

        Shell.mkdir(os.path.dirname(install_dir), True, True, self._args.dry_run)
        Shell.mv(
            os.path.join(staging_dir, f"node-{version}-linux-x64"),
            install_dir,
            True,
            self._args.dry_run,
        )

        nodejs_executables = ["corepack", "node", "npm", "npx"]

        Log.info(
            "creating nodejs executable symlinks", {"executables": nodejs_executables}
        )

        for exe in nodejs_executables:
            symlink_src_path = os.path.join(install_dir, "bin", exe)
            symlink_dst_path = os.path.join("/usr/local/bin", exe)
            Shell.rm(symlink_dst_path, False, True, True, self._args.dry_run)
            Shell.ln(symlink_src_path, symlink_dst_path, True, self._args.dry_run)

    @staticmethod
    def _get_current_version() -> Optional[Semver]:
        try:
            p = subprocess.Popen(
                ["node", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("node returned non-zero exit code")

            return Semver.parse(stdout.strip())
        except FileNotFoundError:
            return None

    @staticmethod
    def _get_target_version() -> Tuple[str, Semver]:
        cached_version = VersionCache.get_version("nodejs")
        if cached_version is not None:
            Log.info(
                "using cached nodejs version",
                {
                    "version": cached_version["version"],
                    "last_attempt": cached_version.get("last_attempt"),
                },
            )
            version = Semver.parse(cached_version["version"])
            if version is None:
                raise Exception(
                    f"Failed to parse cached nodejs version {cached_version['version']}"
                )
            return cached_version["version"], version

        try:
            latest_release = Github.get_latest_release(
                NODEJS_GITHUB_ORG, NODEJS_GITHUB_REPO
            )
            latest_version = Semver.parse(latest_release)
            if latest_version is None:
                raise Exception(f"Failed to parse nodejs version {latest_release}")
        except Exception as e:
            VersionCache.add_failed_attempt(
                "nodejs",
                str(e),
                source=f"github:{NODEJS_GITHUB_ORG}/{NODEJS_GITHUB_REPO}",
            )
            raise

        VersionCache.update_version(
            "nodejs",
            latest_release,
            f"github:{NODEJS_GITHUB_ORG}/{NODEJS_GITHUB_REPO}",
        )

        return latest_release, latest_version
