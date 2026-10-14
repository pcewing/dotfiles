#!/usr/bin/env python

import os
import re
import subprocess

from dot.lib.common.archive import Archive
from dot.lib.common.dir import Dir
from dot.lib.common.github import Github
from dot.lib.common.log import Log
from dot.lib.common.semver import Semver
from dot.lib.common.shell import Shell
from dot.lib.common.version_cache import VersionCache
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

STYLUA_GITHUB_ORG = "JohnnyMorganz"
STYLUA_GITHUB_REPO = "StyLua"
STYLUA_ARCHIVE_NAME = "stylua-linux-x86_64.zip"


class StyluaProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        target_release, target_version = StyluaProvisioner._get_target_version()

        current_version = StyluaProvisioner._get_current_version()
        if current_version is None:
            Log.info("stylua is not installed")
        elif current_version < target_version:
            Log.info(
                f"stylua {current_version} is installed but {target_version} is available"
            )
        else:
            Log.info(f"stylua {target_version} is already installed, nothing to do")
            return

        staging_dir = Dir.staging("stylua", target_release)
        archive_path = os.path.join(staging_dir, STYLUA_ARCHIVE_NAME)

        install_dir = Dir.install("stylua", target_release)
        symlink_path = "/usr/local/bin/stylua"

        Log.info("downloading stylua release archive")
        Github.download_release_artifact(
            STYLUA_GITHUB_ORG,
            STYLUA_GITHUB_REPO,
            target_release,
            STYLUA_ARCHIVE_NAME,
            archive_path,
            True,
            False,
            False,
            self._args.dry_run,
        )

        Log.info("extracting stylua release archive")
        Archive.extract(archive_path, staging_dir, self._args.dry_run)

        Log.info("deleting stylua release archive")
        Shell.rm(archive_path, False, False, False, self._args.dry_run)

        Log.info(
            "creating base install directory",
            {"path": os.path.dirname(install_dir)},
        )
        Shell.mkdir(os.path.dirname(install_dir), True, True, self._args.dry_run)

        Log.info("deleting existing install directory if there is one")
        Shell.rm(install_dir, True, True, True, self._args.dry_run)

        Log.info("moving temp directory to install location")
        Shell.mv(staging_dir, install_dir, True, self._args.dry_run)

        exe_path = os.path.join(install_dir, "stylua")
        Shell.chmod("+x", exe_path, True, self._args.dry_run)

        Log.info("deleting existing symlink if there is one")
        Shell.rm(symlink_path, False, True, True, self._args.dry_run)

        Log.info("creating symlink to executable in install directory")
        Shell.ln(exe_path, symlink_path, True, self._args.dry_run)

    @staticmethod
    def _get_current_version() -> Semver | None:
        try:
            p = subprocess.Popen(
                ["stylua", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("stylua returned non-zero exit code")
            m = re.match(r"stylua ([0-9]+\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError:
            return None

    @staticmethod
    def _get_target_version() -> tuple[str, Semver]:
        cached_version = VersionCache.get_version("stylua")
        if cached_version is not None:
            Log.info(
                "using cached stylua version",
                {
                    "version": cached_version["version"],
                    "last_attempt": cached_version.get("last_attempt"),
                },
            )
            version = Semver.parse(cached_version["version"])
            if version is None:
                raise Exception(
                    f"Failed to parse cached stylua version {cached_version['version']}"
                )
            return cached_version["version"], version

        try:
            latest_release = Github.get_latest_release(
                STYLUA_GITHUB_ORG, STYLUA_GITHUB_REPO
            )
            latest_version = Semver.parse(latest_release)
            if latest_version is None:
                raise Exception(f"Failed to parse stylua version {latest_release}")
        except Exception as e:
            VersionCache.add_failed_attempt(
                "stylua",
                str(e),
                source=f"github:{STYLUA_GITHUB_ORG}/{STYLUA_GITHUB_REPO}",
            )
            raise

        VersionCache.update_version(
            "stylua",
            latest_release,
            f"github:{STYLUA_GITHUB_ORG}/{STYLUA_GITHUB_REPO}",
        )

        return latest_release, latest_version
