#!/usr/bin/env python

import os
from typing import Optional, Tuple

from dot.lib.common.archive import Archive
from dot.lib.common.dir import Dir
from dot.lib.common.github import Github
from dot.lib.common.log import Log
from dot.lib.common.semver import Semver
from dot.lib.common.shell import Shell
from dot.lib.common.util import write_file
from dot.lib.common.version_cache import VersionCache
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs
from dot.lib.provision.tag import Tags

WIN32YANK_GITHUB_ORG = "equalsraf"
WIN32YANK_GITHUB_REPO = "win32yank"


class Win32YankProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        if not self._args.tags.has(Tags.wsl):
            Log.info(
                "skipping win32yank provisioner", {"reason": "wsl tag not present"}
            )
            return

        # There's an open issue where running win32yank.exe from the WSL file
        # system is very slow, so install it on the Windows C: drive instead:
        # https://github.com/equalsraf/win32yank/issues/22
        self._install_dir = "/mnt/c/bin/"

        target_release, target_version = Win32YankProvisioner._get_target_version()

        current_version = self._get_current_version()
        if current_version is None:
            Log.info("win32yank is not installed")
        elif current_version < target_version:
            Log.info(
                f"win32yank {current_version} is installed but {target_version} is available"
            )
        else:
            Log.info(f"win32yank {target_version} is already installed, nothing to do")
            return

        self._install(target_release)

    def _install(self, release: str) -> None:
        staging_dir = Dir.staging("win32yank", release)

        archive_name = "win32yank-x64.zip"
        archive_path = os.path.join(staging_dir, archive_name)

        Github.download_release_artifact(
            org=WIN32YANK_GITHUB_ORG,
            repo=WIN32YANK_GITHUB_REPO,
            release=release,
            file=archive_name,
            path=archive_path,
            create_dir=True,
            sudo=False,
            force=False,
            dry_run=self._args.dry_run,
        )

        Log.info("extracting win32yank release archive")
        Archive.extract(archive_path, staging_dir, self._args.dry_run)

        Log.info("creating win32yank install directory", {"path": self._install_dir})
        Shell.mkdir(
            path=self._install_dir,
            exist_ok=True,
            sudo=False,
            dry_run=self._args.dry_run,
        )

        Log.info("moving win32yank.exe to install location")
        Shell.mv(
            src=os.path.join(staging_dir, "win32yank.exe"),
            dst=os.path.join(self._install_dir, "win32yank.exe"),
            sudo=False,
            dry_run=self._args.dry_run,
        )

        Log.info("deleting win32yank staging directory")
        Shell.rm(
            path=staging_dir,
            recursive=True,
            force=True,
            sudo=False,
            dry_run=self._args.dry_run,
        )

        self._write_version_file(release)

    def _write_version_file(self, version: str) -> None:
        Log.info(
            "writing win32yank version file",
            {"path": self._version_file_path(), "version": version},
        )
        write_file(
            path=self._version_file_path(),
            content=str(version),
            sudo=False,
            dry_run=self._args.dry_run,
        )

    def _read_version_file(self) -> Optional[str]:
        if not os.path.isfile(self._version_file_path()):
            return None
        with open(self._version_file_path(), "r") as f:
            return f.read()

    def _version_file_path(self) -> str:
        return os.path.join(self._install_dir, "win32yank_version.txt")

    def _get_current_version(self) -> Optional[Semver]:
        version_str = self._read_version_file()
        if version_str is None:
            return None
        return Semver.parse(version_str)

    @staticmethod
    def _get_target_version() -> Tuple[str, Semver]:
        cached_version = VersionCache.get_version("win32yank")
        if cached_version is not None:
            Log.info(
                "using cached win32yank version",
                {
                    "version": cached_version["version"],
                    "last_attempt": cached_version.get("last_attempt"),
                },
            )
            version = Semver.parse(cached_version["version"])
            if version is None:
                raise Exception(
                    f"Failed to parse cached win32yank version {cached_version['version']}"
                )
            return cached_version["version"], version

        try:
            latest_release = Github.get_latest_release(
                WIN32YANK_GITHUB_ORG, WIN32YANK_GITHUB_REPO
            )
            latest_version = Semver.parse(latest_release)
            if latest_version is None:
                raise Exception(f"Failed to parse win32yank version {latest_release}")
        except Exception as e:
            VersionCache.add_failed_attempt(
                "win32yank",
                str(e),
                source=f"github:{WIN32YANK_GITHUB_ORG}/{WIN32YANK_GITHUB_REPO}",
            )
            raise

        VersionCache.update_version(
            "win32yank",
            latest_release,
            f"github:{WIN32YANK_GITHUB_ORG}/{WIN32YANK_GITHUB_REPO}",
        )

        return latest_release, latest_version
