#!/usr/bin/env python

import os
import re
import subprocess
from typing import Union

from lib.common.alternatives import Alternatives
from lib.common.dir import Dir
from lib.common.github import Github
from lib.common.log import Log
from lib.common.pip import Pip
from lib.common.semver import Semver
from lib.common.shell import Shell
from lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

NEOVIM_GITHUB_ORG = "neovim"
NEOVIM_GITHUB_REPO = "neovim"


class NeovimProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        latest_version = Github.get_latest_release(
            NEOVIM_GITHUB_ORG, NEOVIM_GITHUB_REPO
        )
        latest_version = Semver.parse(latest_version)

        current_version = NeovimProvisioner._get_current_version()
        if current_version is None:
            Log.info(f"Neovim is not installed")
        elif current_version < latest_version:
            Log.info(
                f"Neovim {current_version} is installed but {latest_version} is available"
            )
        else:
            Log.info(f"Neovim {latest_version} is already installed, nothing to do")
            return

        tmp_dir = f"{Dir.home()}/Downloads/neovim/{latest_version}"
        appimage_filename = "nvim.appimage"
        appimage_path = os.path.join(tmp_dir, appimage_filename)

        base_install_dir = "/opt/neovim"
        install_dir = f"/opt/neovim/{latest_version}"
        install_path = os.path.join(install_dir, appimage_filename)
        symlink_path = "/usr/local/bin/nvim"

        self._download_release_appimage(latest_version, appimage_path)

        Log.info("deleting existing install directory if there is one")
        Shell.rm(install_dir, True, True, True, self._args.dry_run)

        Log.info("creating install directory", [("path", install_dir)])
        Shell.mkdir(install_dir, True, True, self._args.dry_run)

        Log.info("moving appimage to install location")
        Shell.mv(appimage_path, install_path, True, self._args.dry_run)

        Log.info("making appimage file executable")
        Shell.chmod("+x", install_path, False, self._args.dry_run)

        Log.info("deleting existing symlink")
        Shell.rm(symlink_path, False, True, True, self._args.dry_run)

        Log.info("creating symlinks to executables in install directory")
        Shell.ln(install_path, symlink_path, True, self._args.dry_run)

        Log.info("installing pynvim python modules")
        Pip.install(["pynvim"], True, True, self._args.dry_run)

        Log.info("updating alternatives to use nvim")
        Alternatives.install(
            "/usr/bin/vi", "vi", symlink_path, 60, True, self._args.dry_run
        )
        Alternatives.set("vi", symlink_path, True, self._args.dry_run)
        Alternatives.install(
            "/usr/bin/vim", "vim", symlink_path, 60, True, self._args.dry_run
        )
        Alternatives.set("vim", symlink_path, True, self._args.dry_run)
        Alternatives.install(
            "/usr/bin/editor", "editor", symlink_path, 60, True, self._args.dry_run
        )
        Alternatives.set("editor", symlink_path, True, self._args.dry_run)

    def _download_release_appimage(self, version: str, path: str) -> None:
        if os.path.isfile(path):
            Log.info("skipping download because file already exists", [("path", path)])
            return

        # Make sure the directory we are downloading to exists
        Shell.mkdir(os.path.dirname(path), True, False, self._args.dry_run)

        Log.info("downloading neovim release appimage")
        Github.download_release_artifact(
            NEOVIM_GITHUB_ORG,
            NEOVIM_GITHUB_REPO,
            version,
            os.path.basename(path),
            path,
            True,
            False,
            False,
            self._args.dry_run,
        )

    @staticmethod
    def _get_current_version() -> Union[str, None]:
        try:
            p = subprocess.Popen(
                ["nvim", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("Neovim returned non-zero exit code")
            m = re.match("NVIM (v[0-9]+\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError as e:
            return None
