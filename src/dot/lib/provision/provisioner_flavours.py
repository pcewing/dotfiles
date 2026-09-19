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
from dot.lib.common.version_cache import VersionCache
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

FLAVOURS_GITHUB_ORG = "Misterio77"
FLAVOURS_GITHUB_REPO = "flavours"


class FlavoursProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        target_release, target_version = FlavoursProvisioner._get_target_version()

        current_version = FlavoursProvisioner._get_current_version()
        if current_version is None:
            Log.info("flavours is not installed")
        elif current_version < target_version:
            Log.info(
                f"flavours {current_version} is installed but {target_version} is available"
            )
        else:
            Log.info(f"flavours {target_version} is already installed, nothing to do")
            return

        tmp_dir = Dir.staging("flavours", target_release)
        archive_filename = f"flavours-{target_release}-x86_64-linux.tar.gz"
        archive_path = os.path.join(tmp_dir, archive_filename)

        base_install_dir = "/opt/flavours"
        install_dir = os.path.join(base_install_dir, target_release)
        symlink_path = "/usr/local/bin/flavours"

        Log.info("downloading flavours release archive")
        Github.download_release_artifact(
            FLAVOURS_GITHUB_ORG,
            FLAVOURS_GITHUB_REPO,
            target_release,
            archive_filename,
            archive_path,
            True,
            False,
            False,
            self._args.dry_run,
        )

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
        exit_code = p.wait()
        if exit_code != 0:
            # The old shell provisioner ignored failures here, and flavours
            # update can be flaky on a first run, so just warn.
            Log.warn(
                "flavours update returned non-zero exit code",
                {"exit_code": exit_code},
            )

    @staticmethod
    def _get_current_version() -> Optional[Semver]:
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
        except FileNotFoundError:
            return None

    @staticmethod
    def _get_target_version() -> Tuple[str, Semver]:
        cached_version = VersionCache.get_version("flavours")
        if cached_version is not None:
            Log.info(
                "using cached flavours version",
                {
                    "version": cached_version["version"],
                    "last_attempt": cached_version.get("last_attempt"),
                },
            )
            version = Semver.parse(cached_version["version"])
            if version is None:
                raise Exception(
                    f"Failed to parse cached flavours version {cached_version['version']}"
                )
            return cached_version["version"], version

        try:
            latest_release = Github.get_latest_release(
                FLAVOURS_GITHUB_ORG, FLAVOURS_GITHUB_REPO
            )
            latest_version = Semver.parse(latest_release)
            if latest_version is None:
                raise Exception(f"Failed to parse flavours version {latest_release}")
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
