#!/usr/bin/env python

import os
from typing import Union

from lib.common.archive import Archive
from lib.common.dir import Dir
from lib.common.github import Github
from lib.common.log import Log
from lib.common.semver import Semver
from lib.common.shell import Shell
from lib.common.util import write_file
from lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs
from lib.provision.tag import Tags

WIN32YANK_GITHUB_ORG = "equalsraf"
WIN32YANK_GITHUB_REPO = "win32yank"


class Win32YankProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        if not self._args.tags.has(Tags.wsl):
            Log.info(
                "skipping win32yank provisioner", [("reason", "wsl tag not present")]
            )
            return

        # There's an open issue as of implementing this on 2024-05-20 where
        # running win32yank.exe from path within the WSL file system is very slow:
        # https://github.com/equalsraf/win32yank/issues/22
        # To avoid that, make sure we install this on the Windows C: drive. Set
        # this before calling _get_current_version() since we need it to
        # construct the path to the version file.
        self._install_dir = f"/mnt/c/bin/"

        latest_version = Github.get_latest_release(
            WIN32YANK_GITHUB_ORG, WIN32YANK_GITHUB_REPO
        )
        latest_version = Semver.parse(latest_version)

        # TODO: Gross but theres' no way to get the version from the
        # executable. It doesn't have a `--version` flag and the
        # ProductInfo.VersionInfo metadata on the exe isn't populated.
        # As a hack, just write the version installed to a text file next to
        # the exe called win32yank_version.txt and check that.

        current_version = self._get_current_version()
        if current_version is None:
            Log.info(f"Win32Yank is not installed")
        elif current_version < latest_version:
            Log.info(
                f"Win32Yank {current_version} is installed but {latest_version} is available"
            )
        else:
            Log.info(f"Win32Yank {latest_version} is already installed, nothing to do")
            return

        self._install(latest_version)

    def _install(self, version: str) -> None:
        self._staging_dir = Dir.staging("win32yank", str(version))

        self._archive_name = f"win32yank-x64.zip"
        self._archive_url = f"https://github.com/equalsraf/win32yank/releases/download/${version}/{self._archive_name}"
        self._archive_path = f"{self._staging_dir}/{self._archive_name}"

        Github.download_release_artifact(
            org=WIN32YANK_GITHUB_ORG,
            repo=WIN32YANK_GITHUB_REPO,
            release=version,
            file=self._archive_name,
            path=self._archive_path,
            create_dir=True,
            sudo=False,
            force=False,
            dry_run=self._args.dry_run,
        )

        Log.info("extracting win32yank release archive")
        Archive.extract(self._archive_path, self._staging_dir, self._args.dry_run)

        Log.info("creating win32yank install directory", {"path": self._install_dir})
        Shell.mkdir(
            path=self._install_dir,
            exist_ok=True,
            sudo=False,
            dry_run=self._args.dry_run,
        )

        Log.info("moving win32yank.exe to install location")
        Shell.mv(
            src=os.path.join(self._staging_dir, "win32yank.exe"),
            dst=os.path.join(self._install_dir, "win32yank.exe"),
            sudo=False,
            dry_run=self._args.dry_run,
        )

        Log.info("deleting win32yank staging directory")
        Shell.rm(
            path=self._staging_dir,
            recursive=True,
            force=True,
            sudo=False,
            dry_run=self._args.dry_run,
        )

        self._write_version_file(version)

    def _write_version_file(self, version: str) -> None:
        Log.info(
            "writing version file",
            [("path", self._version_file_path()), ("version", version)],
        )
        write_file(
            path=self._version_file_path(),
            content=str(version),
            sudo=False,
            dry_run=self._args.dry_run,
        )

    def _read_version_file(self) -> Union[str, None]:
        Log.info("reading version file", {"path": self._version_file_path()})
        if not os.path.isfile(self._version_file_path()):
            return None
        with open(self._version_file_path(), "r") as f:
            return f.read()

    def _version_file_path(self) -> str:
        return os.path.join(self._install_dir, "win32yank_version.txt")

    def _get_current_version(self) -> Union[str, None]:
        version_str = self._read_version_file()
        if version_str is None:
            return None
        return Semver.parse(version_str)
