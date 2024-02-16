#!/usr/bin/env python

import os
import subprocess
import re
from typing import Union

from ..common.archive import Archive
from ..common.github import Github
from ..common.log import Log
from ..common.provisioner import IComponentProvisioner, ProvisionerArgs
from ..common.semver import Semver
from ..common.shell import Shell
from ..common.dir import Dir

KITTY_GITHUB_ORG = "kovidgoyal"
KITTY_GITHUB_REPO = "kitty"

class KittyProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        latest_version = Github.get_latest_release(KITTY_GITHUB_ORG, KITTY_GITHUB_REPO)
        latest_version = Semver.parse(latest_version)

        current_version = KittyProvisioner._get_current_version()
        if current_version is None:
            Log.info(f"Kitty is not installed")
        elif current_version < latest_version:
            Log.info(
                f"Kitty {current_version} is installed but {latest_version} is available"
            )
        else:
            Log.info(f"Kitty {latest_version} is already installed, nothing to do")
            return

        tmp_dir = f"{Dir.home()}/Downloads/kitty/{latest_version}"
        archive_filename = f"kitty-{latest_version.__str__().replace('v', '')}-x86_64.txz"
        archive_path = os.path.join(tmp_dir, archive_filename)

        base_install_dir = "/opt/kitty"
        install_dir = f"/opt/kitty/{latest_version}"
        symlink_path_kitty = "/usr/local/bin/kitty"
        symlink_path_kitten = "/usr/local/bin/kitten"

        self._download_release_archive(latest_version, archive_path)

        Log.info("Extracting kitty release archive")
        Archive.extract(archive_path, tmp_dir, self._args.dry_run)

        Log.info("Deleting kitty release archive")
        Shell.rm(archive_path, False, False, False, self._args.dry_run)

        Log.info("Creating base install directory", [("path", base_install_dir)])
        Shell.mkdir(base_install_dir, True, True, self._args.dry_run)

        Log.info("Deleting existing install directory if there is one")
        Shell.rm(install_dir, True, True, True, self._args.dry_run)

        Log.info("Moving temp directory to install location")
        Shell.mv(tmp_dir, install_dir, True, self._args.dry_run)

        Log.info("Deleting existing symlinks")
        Shell.rm(symlink_path_kitty, False, True, True, self._args.dry_run)
        Shell.rm(symlink_path_kitten, False, True, True, self._args.dry_run)

        Log.info("Creating symlinks to executables in install directory")
        Shell.ln(
            os.path.join(install_dir, "bin/kitty"),
            symlink_path_kitty,
            True,
            self._args.dry_run,
        )
        Shell.ln(
            os.path.join(install_dir, "bin/kitten"),
            symlink_path_kitten,
            True,
            self._args.dry_run,
        )

    def _download_release_archive(self, version: str, path: str) -> None:
        if os.path.isfile(path):
            Log.info("Skipping download because file already exists", [("path", path)])
            return

        # Make sure the directory we are downloading to exists
        Shell.mkdir(os.path.dirname(path), True, False, self._args.dry_run)

        Log.info("Downloading kitty release archive")
        Github.download_release_artifact(
            KITTY_GITHUB_ORG,
            KITTY_GITHUB_REPO,
            version,
            os.path.basename(path),
            path,
            self._args.dry_run,
        )

    @staticmethod
    def _get_current_version() -> Union[str, None]:
        try:
            p = subprocess.Popen(
                ["kitty", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("Kitty returned non-zero exit code")
            m = re.match("kitty ([0-9]+.[0-9]+.[0-9]+) created by Kovid Goyal", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError as e:
            return None
