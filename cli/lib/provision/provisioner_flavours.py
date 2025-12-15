#!/usr/bin/env python

import os
import subprocess
from typing import Tuple, Union

from lib.common.archive import Archive
from lib.common.dir import Dir
from lib.common.github import Github
from lib.common.log import Log
from lib.common.semver import Semver
from lib.common.shell import Shell
from lib.common.version_cache import VersionCache
from lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

FLAVOURS_GITHUB_ORG = "Misterio77"
FLAVOURS_GITHUB_REPO = "flavours"


class FlavoursProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        target_release, target_version = FlavoursProvisioner._get_target_version()

        current_version = FlavoursProvisioner._get_current_version()
        if current_version is None:
            Log.info(f"Flavours is not installed")
        elif current_version < target_version:
            Log.info(
                f"Flavours {current_version} is installed but {target_version} is available"
            )
        else:
            Log.info(f"Flavours {target_version} is already installed, nothing to do")
            return

        tmp_dir = f"{Dir.home()}/Downloads/flavours/{target_release}"
        archive_filename = f"flavours-{target_release}-x86_64-linux.tar.gz"
        archive_path = os.path.join(tmp_dir, archive_filename)

        base_install_dir = "/opt/flavours"
        install_dir = f"/opt/flavours/{target_release}"
        symlink_path = "/usr/local/bin/flavours"

        self._download_release_archive(target_release, archive_path)

        Log.info("extracting flavours release archive")
        Archive.extract(archive_path, tmp_dir, self._args.dry_run)

        Log.info("deleting flavours release archive")
        Shell.rm(archive_path, False, False, False, self._args.dry_run)

        Log.info("creating base install directory", {"path": base_install_dir})
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
            Log.info("skipping download because file already exists", {"path": path})
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
                {"exit_code": exit_code},
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

    @staticmethod
    def _get_target_version() -> Tuple[str, Semver]:
        # First check version cache to see if we have a cached version that is
        # new enough
        cached_version = VersionCache.get_version("flavours")
        if cached_version is not None:
            Log.info(
                "using cached flavours version",
                {
                    "version": cached_version["version"],
                    "last_attempt": cached_version.get("last_attempt"),
                },
            )
            return cached_version["version"], Semver.parse(cached_version["version"])

        try:
            latest_release = Github.get_latest_release(
                FLAVOURS_GITHUB_ORG, FLAVOURS_GITHUB_REPO
            )
            latest_version = Semver.parse(latest_release)
        except Exception as e:
            VersionCache.add_failed_attempt(
                "flavours",
                str(e),
                source=f"github:{FLAVOURS_GITHUB_ORG}/{FLAVOURS_GITHUB_REPO}",
            )
            raise

        VersionCache.update_version(
            "flavours",
            latest_release,
            f"github:{FLAVOURS_GITHUB_ORG}/{FLAVOURS_GITHUB_REPO}",
        )

        return latest_release, latest_version
