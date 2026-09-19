#!/usr/bin/env python

import os

from dot.lib.common.archive import Archive
from dot.lib.common.dir import Dir
from dot.lib.common.log import Log
from dot.lib.common.shell import Shell
from dot.lib.common.util import download_file
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs

# wpr doesn't expose a version endpoint, so pin the release that the old shell
# provisioner and the former Nix derivation both used.
WPR_VERSION = "0.1.0"
WPR_ARCHIVE_NAME = f"wpr.{WPR_VERSION}.linux-amd64.tar.gz"
WPR_URL = (
    "https://s3-us-west-2.amazonaws.com/pcewing-wpr/releases/"
    f"{WPR_VERSION}/{WPR_ARCHIVE_NAME}"
)


class WprProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        install_dir = Dir.install("wpr", WPR_VERSION)
        exe_path = os.path.join(install_dir, "wpr")
        symlink_path = "/usr/local/bin/wpr"

        if os.path.isfile(exe_path) and not self._args.force:
            Log.info(f"wpr {WPR_VERSION} is already installed, nothing to do")
            return

        staging_dir = Dir.staging("wpr", WPR_VERSION)
        archive_path = os.path.join(staging_dir, WPR_ARCHIVE_NAME)

        download_file(WPR_URL, archive_path, False, True, self._args.dry_run)

        Log.info("extracting wpr release archive")
        Archive.extract(archive_path, staging_dir, self._args.dry_run)

        Log.info(
            "creating base install directory", {"path": os.path.dirname(install_dir)}
        )
        Shell.mkdir(os.path.dirname(install_dir), True, True, self._args.dry_run)

        Log.info("deleting existing install directory if there is one")
        Shell.rm(install_dir, True, True, True, self._args.dry_run)

        Log.info("moving temp directory to install location")
        Shell.mv(staging_dir, install_dir, True, self._args.dry_run)

        Log.info("making wpr executable")
        Shell.chmod("+x", os.path.join(install_dir, "wpr"), True, self._args.dry_run)

        Log.info("deleting existing symlink if there is one")
        Shell.rm(symlink_path, False, True, True, self._args.dry_run)

        Log.info("creating symlink to wpr executable")
        Shell.ln(
            os.path.join(install_dir, "wpr"),
            symlink_path,
            True,
            self._args.dry_run,
        )
