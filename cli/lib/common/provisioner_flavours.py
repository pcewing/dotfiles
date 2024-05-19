#!/usr/bin/env python

import os
import subprocess
from typing import Union

from .archive import Archive
from .dir import Dir
from .github import Github
from .log import Log
from .provisioner import IComponentProvisioner, ProvisionerArgs
from .semver import Semver
from .shell import Shell

FLAVOURS_GITHUB_ORG = "Misterio77"
FLAVOURS_GITHUB_REPO = "flavours"


class FlavoursProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        latest_version = Github.get_latest_release("Misterio77", "flavours")
        latest_version = Semver.parse(latest_version)

        current_version = FlavoursProvisioner._get_current_version()
        if current_version is None:
            Log.info(f"Flavours is not installed")
        elif current_version < latest_version:
            Log.info(
                f"Flavours {current_version} is installed but {latest_version} is available"
            )
        else:
            Log.info(f"Flavours {latest_version} is already installed, nothing to do")
            return

        tmp_dir = f"{Dir.home()}/Downloads/flavours/{latest_version}"
        archive_filename = f"flavours-{latest_version}-x86_64-linux.tar.gz"
        archive_path = os.path.join(tmp_dir, archive_filename)

        base_install_dir = "/opt/flavours"
        install_dir = f"/opt/flavours/{latest_version}"
        symlink_path = "/usr/local/bin/flavours"

        self._download_release_archive(latest_version, archive_path)

        Log.info("extracting flavours release archive")
        Archive.extract(archive_path, tmp_dir, self._args.dry_run)

        Log.info("deleting flavours release archive")
        Shell.rm(archive_path, False, False, False, self._args.dry_run)

        Log.info("creating base install directory", [("path", base_install_dir)])
        Shell.mkdir(base_install_dir, True, True, self._args.dry_run)

        Log.info("deleting existing install directory if there is one")
        Shell.rm(install_dir, True, True, True, self._args.dry_run)

        Log.info("moving temp directory to install location")
        Shell.mv(tmp_dir, install_dir, True, self._args.dry_run)

        Log.info("deleting existing symlink if there is one")
        Shell.rm(symlink_path, False, True, True, self._args.dry_run)

        Log.info("creating symlink to executable in install directory")
        Shell.ln(
            os.path.join(install_dir, "flavours"),
            symlink_path,
            True,
            self._args.dry_run,
        )

        self._flavours_update()

    def _download_release_archive(self, version: str, path: str) -> None:
        if os.path.isfile(path):
            Log.info("skipping download because file already exists", [("path", path)])
            return

        # Make sure the directory we are downloading to exists
        Shell.mkdir(os.path.dirname(path), True, False, self._args.dry_run)

        Log.info("downloading flavours release archive")
        Github.download_release_artifact(
            FLAVOURS_GITHUB_ORG,
            FLAVOURS_GITHUB_REPO,
            version,
            os.path.basename(path),
            path,
            True,
            False,
            False,
            self._args.dry_run,
        )

    def _flavours_update(self) -> None:
        Log.info("running flavours update")

        if self._args.dry_run:
            Log.info("skipping flavours update due to --dry-run")
            return

        p = subprocess.Popen(
            ["flavours", "update", "all"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        # The shell provision script piped both stdout and stderr to /dev/null
        # and didn't check exit code. Is that wise?
        exit_code = p.wait()
        if p.wait() != 0:
            Log.warn(
                "Flavours update returned non-zero exit code",
                [("exit_code", exit_code)],
            )

    @staticmethod
    def _get_current_version() -> Union[str, None]:
        try:
            p = subprocess.Popen(
                ["flavours", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("Flavours returned non-zero exit code")

            version_str = stdout.replace("flavours", "").strip()
            return Semver.parse(version_str)
        except FileNotFoundError as e:
            return None
