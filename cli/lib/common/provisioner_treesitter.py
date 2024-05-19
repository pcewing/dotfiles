#!/usr/bin/env python

import os
import re
import subprocess
from typing import Union

from .dir import Dir
from .github import Github
from .log import Log
from .provisioner import IComponentProvisioner, ProvisionerArgs
from .semver import Semver
from .shell import Shell

TREE_SITTER_GITHUB_ORG = "tree-sitter"
TREE_SITTER_GITHUB_REPO = "tree-sitter"


# TODO: Move this somewhere so that all provisioners can share it since we've
# duplicated this logic in several places
def prepare_install_dir(install_dir: str, create: bool, dry_run: bool) -> None:
    Log.info("deleting existing install directory if there is one")
    Shell.rm(install_dir, True, True, True, dry_run)

    if create:
        Log.info("creating install directory", [("path", install_dir)])
        Shell.mkdir(install_dir, True, True, dry_run)
    else:
        base_install_dir = os.path.dirname(install_dir)
        Log.info("creating base install directory", [("path", base_install_dir)])
        Shell.mkdir(base_install_dir, True, True, dry_run)


class TreeSitterProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        latest_version = TreeSitterProvisioner._get_latest_release()

        current_version = TreeSitterProvisioner._get_current_version()
        if current_version is None:
            Log.info(f"tree-sitter is not installed")
        elif current_version < latest_version:
            Log.info(
                f"tree-sitter {current_version} is installed but {latest_version} is available"
            )
        else:
            Log.info(
                f"tree-sitter {latest_version} is already installed, nothing to do"
            )
            return

        staging_dir = Dir.staging("tree-sitter", str(latest_version))
        install_dir = Dir.install("tree-sitter", str(latest_version))

        exe_name = "tree-sitter-linux-x64"
        exe_path_staging = os.path.join(staging_dir, exe_name)
        exe_path_install = os.path.join(install_dir, exe_name)

        zip_name = f"{exe_name}.gz"
        zip_path_staging = os.path.join(staging_dir, zip_name)

        symlink_path = "/usr/local/bin/tree-sitter"

        self._download_release_zip(str(latest_version), zip_path_staging)

        TreeSitterProvisioner._unzip_executable(zip_path_staging, self._args.dry_run)

        prepare_install_dir(install_dir, True, self._args.dry_run)

        Log.info("moving executable to installation directory")
        Shell.mv(exe_path_staging, exe_path_install, True, self._args.dry_run)

        Log.info("making file executable")
        Shell.chmod("+x", exe_path_install, True, self._args.dry_run)

        Log.info("deleting existing symlink if there is one")
        Shell.rm(symlink_path, False, True, True, self._args.dry_run)

        Log.info("creating symlink to executable in install directory")
        Shell.ln(exe_path_install, symlink_path, True, self._args.dry_run)

    def _download_release_zip(self, version: str, path: str) -> None:
        if os.path.isfile(path):
            Log.info("skipping download because file already exists", [("path", path)])
            return

        Log.info("downloading tree-sitter release archive")
        Github.download_release_artifact(
            TREE_SITTER_GITHUB_ORG,
            TREE_SITTER_GITHUB_REPO,
            version,
            os.path.basename(path),
            path,
            True,
            False,
            False,
            self._args.dry_run,
        )

    @staticmethod
    def _unzip_executable(zip_path: str, dry_run: bool) -> None:
        Log.info("unzipping zip file", [("path", zip_path)])
        if dry_run:
            Log.info("skipping apt update due to --dry-run")
        else:
            if subprocess.call(["gunzip", zip_path]) != 0:
                raise Exception("Failed to unzip tree-sitter executable")

    @staticmethod
    def _get_latest_release() -> Semver:
        releases = Github.get_releases(TREE_SITTER_GITHUB_ORG, TREE_SITTER_GITHUB_REPO)
        tags = [r["tag_name"] for r in releases]
        tags = filter(lambda t: "pre-release" not in t, tags)
        tags = [Semver.parse(t) for t in tags]
        tags = sorted(tags, reverse=True)
        return tags[0]

    @staticmethod
    def _get_current_version() -> Union[str, None]:
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
            m = re.match("tree-sitter ([0-9]\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError as e:
            return None
