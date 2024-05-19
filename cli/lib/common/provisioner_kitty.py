#!/usr/bin/env python

import os
import re
import subprocess
from typing import Union

from .archive import Archive
from .dir import Dir
from .github import Github
from .log import Log
from .provisioner import IComponentProvisioner, ProvisionerArgs
from .semver import Semver
from .shell import Shell

KITTY_GITHUB_ORG = "kovidgoyal"
KITTY_GITHUB_REPO = "kitty"


class KittyProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        Log.info("foo")
        return

        latest_release = Github.get_latest_release(KITTY_GITHUB_ORG, KITTY_GITHUB_REPO)
        latest_version = Semver.parse(latest_release)

        Log.info("foo")
        return

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
        archive_filename = f"kitty-{latest_release.replace('v', '')}-x86_64.txz"
        archive_path = os.path.join(tmp_dir, archive_filename)

        base_install_dir = "/opt/kitty"
        install_dir = f"/opt/kitty/{latest_version}"
        symlink_path_kitty = "/usr/local/bin/kitty"
        symlink_path_kitten = "/usr/local/bin/kitten"

        Log.info("downloading kitty release archive")
        Github.download_release_artifact(
            KITTY_GITHUB_ORG,
            KITTY_GITHUB_REPO,
            latest_release,
            archive_filename,
            archive_path,
            True,
            False,
            False,
            self._args.dry_run,
        )

        Log.info("extracting kitty release archive")
        Archive.extract(archive_path, tmp_dir, self._args.dry_run)

        Log.info("deleting kitty release archive")
        Shell.rm(archive_path, False, False, False, self._args.dry_run)

        Log.info("creating base install directory", [("path", base_install_dir)])
        Shell.mkdir(base_install_dir, True, True, self._args.dry_run)

        Log.info("deleting existing install directory if there is one")
        Shell.rm(install_dir, True, True, True, self._args.dry_run)

        Log.info("moving temp directory to install location")
        Shell.mv(tmp_dir, install_dir, True, self._args.dry_run)

        Log.info("deleting existing symlinks")
        Shell.rm(symlink_path_kitty, False, True, True, self._args.dry_run)
        Shell.rm(symlink_path_kitten, False, True, True, self._args.dry_run)

        Log.info("creating symlinks to executables in install directory")
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
