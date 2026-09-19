#!/usr/bin/env python

import os
import re
import subprocess
from typing import Optional, Tuple

from dot.lib.common.dir import Dir
from dot.lib.common.github import Github
from dot.lib.common.log import Log
from dot.lib.common.semver import Semver
from dot.lib.common.shell import Shell
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

TREE_SITTER_GITHUB_ORG = "tree-sitter"
TREE_SITTER_GITHUB_REPO = "tree-sitter"

# v0.26+ doesn't work on Ubuntu 22.04 due to glibc version issues, so pin a
# known-good release for now.
TREE_SITTER_VERSION = "v0.25.10"


class TreeSitterProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        target_release, target_version = TreeSitterProvisioner._get_target_version()

        current_version = TreeSitterProvisioner._get_current_version()
        if current_version is None:
            Log.info("tree-sitter is not installed")
        elif current_version < target_version:
            Log.info(
                f"tree-sitter {current_version} is installed but {target_version} is available"
            )
        else:
            Log.info(
                f"tree-sitter {target_version} is already installed, nothing to do"
            )
            return

        staging_dir = Dir.staging("tree-sitter", target_release)
        install_dir = Dir.install("tree-sitter", target_release)

        exe_name = "tree-sitter-linux-x64"
        exe_path_staging = os.path.join(staging_dir, exe_name)
        exe_path_install = os.path.join(install_dir, exe_name)

        gz_name = f"{exe_name}.gz"
        gz_path_staging = os.path.join(staging_dir, gz_name)

        symlink_path = "/usr/local/bin/tree-sitter"

        Github.download_release_artifact(
            TREE_SITTER_GITHUB_ORG,
            TREE_SITTER_GITHUB_REPO,
            target_release,
            gz_name,
            gz_path_staging,
            True,
            False,
            False,
            self._args.dry_run,
        )

        TreeSitterProvisioner._gunzip_executable(gz_path_staging, self._args.dry_run)

        Log.info("creating install directory", {"path": install_dir})
        Shell.mkdir(install_dir, True, True, self._args.dry_run)

        Log.info("moving executable to installation directory")
        Shell.mv(exe_path_staging, exe_path_install, True, self._args.dry_run)

        Log.info("making file executable")
        Shell.chmod("+x", exe_path_install, True, self._args.dry_run)

        Log.info("deleting existing symlink if there is one")
        Shell.rm(symlink_path, False, True, True, self._args.dry_run)

        Log.info("creating symlink to executable in install directory")
        Shell.ln(exe_path_install, symlink_path, True, self._args.dry_run)

    @staticmethod
    def _gunzip_executable(gz_path: str, dry_run: bool) -> None:
        Log.info("gunzipping file", {"path": gz_path})
        if dry_run:
            Log.info("skipping gunzip due to --dry-run")
        else:
            if subprocess.call(["gunzip", gz_path]) != 0:
                raise Exception("Failed to gunzip tree-sitter executable")

    @staticmethod
    def _get_current_version() -> Optional[Semver]:
        try:
            p = subprocess.Popen(
                ["tree-sitter", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("tree-sitter returned non-zero exit code")
            m = re.match(r"tree-sitter ([0-9]+\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError:
            return None

    @staticmethod
    def _get_target_version() -> Tuple[str, Semver]:
        Log.info(
            "using pinned tree-sitter version",
            {"version": TREE_SITTER_VERSION},
        )
        version = Semver.parse(TREE_SITTER_VERSION)
        if version is None:
            raise Exception(
                f"Failed to parse tree-sitter version {TREE_SITTER_VERSION}"
            )
        return TREE_SITTER_VERSION, version
