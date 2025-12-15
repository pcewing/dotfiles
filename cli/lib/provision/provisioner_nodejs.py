#!/usr/bin/env python

import os
import subprocess
from typing import Tuple

from lib.common.archive import Archive
from lib.common.dir import Dir
from lib.common.github import Github
from lib.common.log import Log
from lib.common.semver import Semver
from lib.common.shell import Shell
from lib.common.typing import StringOrNone
from lib.common.util import download_file
from lib.common.version_cache import VersionCache
from lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

NODEJS_GITHUB_ORG = "nodejs"
NODEJS_GITHUB_REPO = "node"


class NodeJSProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        # Get the currently installed nodejs version
        current_nodejs_version = NodeJSProvisioner._get_current_version()
        Log.info(
            "identified current nodejs version",
            {
                "version": current_nodejs_version,
            }
        )

        target_release, target_version = NodeJSProvisioner._get_target_version()

        # TODO: Make a utility function for this logic?
        if current_nodejs_version is None:
            Log.info(f"nodejs is not installed")
        elif current_nodejs_version < target_version:
            Log.info(
                f"nodejs {current_nodejs_version} is installed but {target_version} is available"
            )
        else:
            Log.info(
                f"nodejs {target_version} is already installed, nothing to do"
            )
            return

        self._install(target_version)

    def _install(self, version: str) -> None:
        staging_dir = Dir.staging("nodejs", str(version))
        install_dir = Dir.install("nodejs", str(version))

        nodejs_archive_name = f"node-{version}-linux-x64.tar.xz"
        nodejs_archive_url = f"https://nodejs.org/dist/{version}/{nodejs_archive_name}"
        nodejs_archive_path = f"{staging_dir}/{nodejs_archive_name}"

        # Download nodejs release tarball
        download_file(
            nodejs_archive_url, nodejs_archive_path, False, False, self._args.dry_run
        )

        # Extract node tarball
        Log.info(
            "extracting nodejs release archive",
            { "archive": nodejs_archive_path, "dst": staging_dir },
        )
        Archive.extract(nodejs_archive_path, staging_dir, self._args.dry_run)

        # Move to install directory
        Shell.mkdir(os.path.dirname(install_dir), True, True, self._args.dry_run)
        Shell.mv(
            os.path.join(staging_dir, f"node-{version}-linux-x64"),
            install_dir,
            True,
            self._args.dry_run,
        )

        nodejs_executables = ["corepack", "node", "npm", "npx"]

        Log.info(
            "creating nodejs executable symlinks", { "executables": nodejs_executables }
        )

        # TODO: We should make a Symlink.create() method that handles deleting existing links and whatnot
        for exe in nodejs_executables:
            symlink_src_path = os.path.join(install_dir, "bin", exe)
            symlink_dst_path = os.path.join("/usr/local/bin", exe)
            Shell.rm(symlink_dst_path, False, True, True, self._args.dry_run)
            Shell.ln(symlink_src_path, symlink_dst_path, True, self._args.dry_run)

    @staticmethod
    def _get_current_version() -> StringOrNone:
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

            version_str = stdout.strip()
            return Semver.parse(version_str)
        except FileNotFoundError as e:
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
            return cached_version["version"], Semver.parse(cached_version["version"])

        try:
            latest_release = Github.get_latest_release(NODEJS_GITHUB_ORG, NODEJS_GITHUB_REPO)
            latest_version = Semver.parse(latest_release)
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
