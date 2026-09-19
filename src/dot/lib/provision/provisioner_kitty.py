#!/usr/bin/env python

import os
import re
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

KITTY_GITHUB_ORG = "kovidgoyal"
KITTY_GITHUB_REPO = "kitty"


class KittyProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        target_release, target_version = KittyProvisioner._get_target_version()

        current_version = KittyProvisioner._get_current_version()
        if current_version is None:
            Log.info("kitty is not installed")
        elif current_version < target_version:
            Log.info(
                f"kitty {current_version} is installed but {target_version} is available"
            )
        else:
            Log.info(f"kitty {target_version} is already installed, nothing to do")
            return

        tmp_dir = Dir.staging("kitty", target_release)
        archive_filename = f"kitty-{target_release.replace('v', '')}-x86_64.txz"
        archive_path = os.path.join(tmp_dir, archive_filename)

        base_install_dir = "/opt/kitty"
        install_dir = os.path.join(base_install_dir, target_release)
        symlink_path_kitty = "/usr/local/bin/kitty"
        symlink_path_kitten = "/usr/local/bin/kitten"

        Log.info("downloading kitty release archive")
        Github.download_release_artifact(
            KITTY_GITHUB_ORG,
            KITTY_GITHUB_REPO,
            target_release,
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

        Log.info("creating base install directory", {"path": base_install_dir})
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
    def _get_current_version() -> Optional[Semver]:
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
            m = re.match(
                r"kitty ([0-9]+\.[0-9]+\.[0-9]+) created by Kovid Goyal", stdout
            )
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError:
            return None

    @staticmethod
    def _get_target_version() -> Tuple[str, Semver]:
        cached_version = VersionCache.get_version("kitty")
        if cached_version is not None:
            Log.info(
                "using cached kitty version",
                {
                    "version": cached_version["version"],
                    "last_attempt": cached_version.get("last_attempt"),
                },
            )
            version = Semver.parse(cached_version["version"])
            if version is None:
                raise Exception(
                    f"Failed to parse cached kitty version {cached_version['version']}"
                )
            return cached_version["version"], version

        try:
            latest_release = Github.get_latest_release(
                KITTY_GITHUB_ORG, KITTY_GITHUB_REPO
            )
            latest_version = Semver.parse(latest_release)
            if latest_version is None:
                raise Exception(f"Failed to parse kitty version {latest_release}")
        except Exception as e:
            VersionCache.add_failed_attempt(
                "kitty",
                str(e),
                source=f"github:{KITTY_GITHUB_ORG}/{KITTY_GITHUB_REPO}",
            )
            raise

        VersionCache.update_version(
            "kitty",
            latest_release,
            f"github:{KITTY_GITHUB_ORG}/{KITTY_GITHUB_REPO}",
        )

        return latest_release, latest_version
