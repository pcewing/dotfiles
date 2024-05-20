#!/usr/bin/env python

import os
import re
import subprocess
from typing import Tuple, Union

from lib.common.apt import Apt
from lib.common.git import Git
from lib.common.github import Github
from lib.common.log import Log
from lib.common.provisioner import IComponentProvisioner, ProvisionerArgs
from lib.common.semver import Semver
from lib.common.shell import Shell
from lib.provision.tag import Tags
from lib.provision.symlink import Symlink

I3_GITHUB_ORG = "i3"
I3_GITHUB_REPO = "i3"


# TODO: Move this somewhere so that all provisioners can share it since we've
# duplicated this logic in several places.
def _i3_prepare_install_dir(install_dir: str, create: bool, dry_run: bool) -> None:
    Log.info("deleting existing install directory if there is one")
    Shell.rm(install_dir, True, True, True, dry_run)

    if create:
        Log.info("creating install directory", [("path", install_dir)])
        Shell.mkdir(install_dir, True, True, dry_run)
    else:
        base_install_dir = os.path.dirname(install_dir)
        Log.info("creating base install directory", [("path", base_install_dir)])
        Shell.mkdir(base_install_dir, True, True, dry_run)


def _i3_bootstrap(dry_run: bool):
    Log.info("bootstrapping i3")
    if dry_run:
        Log.info("skipping i3 bootstrap", [("reason", "dry run")])
        return
    if subprocess.call(["meson", ".."]) != 0:
        raise Exception("meson returned non-zero exit code")


def _i3_build(dry_run: bool):
    Log.info("building i3")
    if dry_run:
        Log.info("skipping i3 build", [("reason", "dry run")])
        return
    if subprocess.call(["ninja"]) != 0:
        raise Exception("ninja returned non-zero exit code")


class I3Provisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__()
        self._args = args

    def provision(self) -> None:
        if not self._args.tags.has(Tags.x11):
            Log.info("skipping i3 provisioner", [("reason", "x11 tag not present")])
            return

        latest_tag_name, latest_tag_version = I3Provisioner._get_latest_tag()
        current_version = I3Provisioner._get_current_version()
        print(current_version)
        if current_version is None:
            Log.info(f"i3 is not installed")
        elif current_version < latest_tag_version:
            Log.info(
                f"i3 {current_version} is installed but {latest_tag_version} is available"
            )
        else:
            Log.info(f"i3 {latest_tag_version} is already installed, nothing to do")
            return

        # TODO: i3-gaps was merged into i3 as of release 4.22 but the version
        # in Apt in Ubuntu 22.04 is still 4.20 so build it from source for now.
        # Once we move to 24.04 we can probably just install the apt package
        # and remove this whole provisioner.

        # Install pre-requisite packages needed to compile i3 from source
        # TODO: I'm not sure if this is still accurate since the merge of
        # i3-gaps into i3. For example, i3 builds with meson/ninja now and not
        # automake so that is almost certainly not necessary. Since all of this
        # will hopefully be deleted soon when we can just install from apt it's
        # not worth the effort to clean up.
        Apt.install(
            [
                "libxcb1-dev",
                "libxcb-keysyms1-dev",
                "libpango1.0-dev",
                "libxcb-util0-dev",
                "libxcb-icccm4-dev",
                "libyajl-dev",
                "libstartup-notification0-dev",
                "libxcb-randr0-dev",
                "libev-dev",
                "libxcb-cursor-dev",
                "libxcb-xinerama0-dev",
                "libxcb-xkb-dev",
                "libxkbcommon-dev",
                "libxkbcommon-x11-dev",
                "autoconf",
                "libxcb-xrm0",
                "libxcb-xrm-dev",
                "libxcb-shape0",
                "libxcb-shape0-dev",
                "automake",
            ],
            self._args.dry_run,
        )

        url = f"https://www.github.com/{I3_GITHUB_ORG}/{I3_GITHUB_REPO}"
        staging_dir = f"/home/pewing/.tmp/i3/{latest_tag_name}"
        build_dir = os.path.join(staging_dir, "build")
        cwd = os.getcwd()

        Shell.rm(staging_dir, True, True, False, self._args.dry_run)
        repo = Git.clone(url, staging_dir, self._args.dry_run)
        repo.checkout(latest_tag_name, self._args.dry_run)
        Shell.mkdir(build_dir, True, False, self._args.dry_run)
        Shell.cd(build_dir, self._args.dry_run)
        _i3_bootstrap(self._args.dry_run)
        _i3_build(self._args.dry_run)
        Shell.cd(cwd, self._args.dry_run)

        install_dir = os.path.join("/opt/i3", latest_tag_name)

        _i3_prepare_install_dir(install_dir, False, self._args.dry_run)
        Shell.mv(staging_dir, install_dir, True, self._args.dry_run)

        executables = [
            "build/i3",
            "build/i3-config-wizard",
            "build/i3-dump-log",
            "build/i3-input",
            "build/i3-msg",
            "build/i3-nagbar",
            "build/i3bar",
            "i3-dmenu-desktop",
            "i3-save-tree",
            "i3-sensible-editor",
            "i3-sensible-pager",
            "i3-sensible-terminal",
        ]

        Log.info("setting up i3wm symlinks")
        for exe in executables:
            source = os.path.join(install_dir, exe)
            target = os.path.join("/usr/local/bin", os.path.basename(source))
            Symlink.create(
                source=source,
                target=target,
                sudo=True,
                dry_run=self._args.dry_run,
            )

    @staticmethod
    def _get_latest_tag() -> Tuple[str, Semver]:
        tags = Github.get_tags(I3_GITHUB_ORG, I3_GITHUB_REPO)
        semver_tags = {}
        for tag in tags:
            tag_name = tag["name"]
            m = re.match("[0-9]+\.[0-9]+(\.[0-9]){0,1}", tag_name)
            if m is not None:
                semver_tags[tag_name] = Semver.parse(tag_name)
        return sorted(semver_tags.items(), reverse=True)[0]

    @staticmethod
    def _get_current_version() -> Union[str, None]:
        try:
            p = subprocess.Popen(
                ["i3", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            stdout, _ = p.communicate()
            if p.returncode != 0:
                raise Exception("i3 returned non-zero exit code")
            m = re.match("i3 version ([0-9]+\.[0-9]+\.[0-9]+)", stdout)
            if m is None:
                return None
            return Semver.parse(m.group(1))
        except FileNotFoundError as e:
            return None
