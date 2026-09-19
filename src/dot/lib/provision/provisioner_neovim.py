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

NEOVIM_GITHUB_ORG = "neovim"
NEOVIM_GITHUB_REPO = "neovim"
NEOVIM_ARCHIVE_NAME = "nvim-linux-x86_64.tar.gz"
NEOVIM_ARCHIVE_DIR = "nvim-linux-x86_64"


class NeovimProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        target_release, target_version = NeovimProvisioner._get_target_version()

        current_version = NeovimProvisioner._get_current_version()
        if current_version is None:
            Log.info("neovim is not installed")
        elif current_version < target_version:
            Log.info(
                f"neovim {current_version} is installed but {target_version} is available"
            )
        else:
            Log.info(f"neovim {target_version} is already installed, nothing to do")
            return

        staging_dir = Dir.staging("neovim", target_release)
        archive_path = os.path.join(staging_dir, NEOVIM_ARCHIVE_NAME)

        base_install_dir = "/opt/neovim"
        install_dir = os.path.join(base_install_dir, target_release)
        symlink_path = "/usr/local/bin/nvim"

        Log.info("downloading neovim release archive")
        Github.download_release_artifact(
            NEOVIM_GITHUB_ORG,
            NEOVIM_GITHUB_REPO,
            target_release,
            NEOVIM_ARCHIVE_NAME,
            archive_path,
            True,
            False,
            False,
            self._args.dry_run,
        )

        Log.info("extracting neovim release archive")
        Archive.extract(archive_path, staging_dir, self._args.dry_run)

        Log.info("creating base install directory", {"path": base_install_dir})
        Shell.mkdir(base_install_dir, True, True, self._args.dry_run)

        Log.info("deleting existing install directory if there is one")
        Shell.rm(install_dir, True, True, True, self._args.dry_run)

        Log.info("moving extracted neovim to install location")
        Shell.mv(
            os.path.join(staging_dir, NEOVIM_ARCHIVE_DIR),
            install_dir,
            True,
            self._args.dry_run,
        )

        Log.info("deleting existing symlink if there is one")
        Shell.rm(symlink_path, False, True, True, self._args.dry_run)

        Log.info("creating symlink to nvim executable")
        Shell.ln(
            os.path.join(install_dir, "bin", "nvim"),
            symlink_path,
            True,
            self._args.dry_run,
        )

    @staticmethod
    def _get_current_version() -> Optional[Semver]:
        try:
            p = subprocess.Popen(
                ["nvim", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                # `nvim --version` otherwise writes a .nvimlog in the cwd
                env={**os.environ, "NVIM_LOG_FILE": "/dev/null"},
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("Neovim returned non-zero exit code")
            m = re.match(r"NVIM (v[0-9]+\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError:
            return None

    @staticmethod
    def _get_target_version() -> Tuple[str, Semver]:
        cached_version = VersionCache.get_version("neovim")
        if cached_version is not None:
            Log.info(
                "using cached neovim version",
                {
                    "version": cached_version["version"],
                    "last_attempt": cached_version.get("last_attempt"),
                },
            )
            version = Semver.parse(cached_version["version"])
            if version is None:
                raise Exception(
                    f"Failed to parse cached neovim version {cached_version['version']}"
                )
            return cached_version["version"], version

        try:
            latest_release = Github.get_latest_release(
                NEOVIM_GITHUB_ORG, NEOVIM_GITHUB_REPO
            )
            latest_version = Semver.parse(latest_release)
            if latest_version is None:
                raise Exception(f"Failed to parse neovim version {latest_release}")
        except Exception as e:
            VersionCache.add_failed_attempt(
                "neovim",
                str(e),
                source=f"github:{NEOVIM_GITHUB_ORG}/{NEOVIM_GITHUB_REPO}",
            )
            raise

        VersionCache.update_version(
            "neovim",
            latest_release,
            f"github:{NEOVIM_GITHUB_ORG}/{NEOVIM_GITHUB_REPO}",
        )

        return latest_release, latest_version
