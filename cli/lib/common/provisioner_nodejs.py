#!/usr/bin/env python

import subprocess
import os
import re
import urllib

from .distro_info import DistroInformation
from .provisioner import IComponentProvisioner, ProvisionerArgs
from .util import download_file, get_current_user, Util
from .dir import Dir
from .log import Log
from .apt import Apt
from .group import Group
from .github import Github
from .shell import Shell
from .semver import Semver

def _uninstall_nvm(dry_run: bool):
    nvm_dir = os.path.join(Dir.home(), ".nvm")
    Log.info( "removing existing nvm install", [("path", nvm_dir)])
    if dry_run:
        Log.info("skip removing nvm install script", [("reason", "dry run")])
        return
    Util.rmdir(nvm_dir)

def _run_nvm_install_script(path: str, dry_run: bool) -> None:
    Log.info( "running nvm install script", [("path", path)])
    if dry_run:
        Log.info("skip running nvm install script", [("reason", "dry run")])
        return

    env = os.environ.copy()
    env['PROFILE'] = "/dev/null"
    p = subprocess.Popen([path], env=env)
    _, _ = p.communicate()
    if p.returncode != 0:
        raise Exception('NVM install script returned non-zero')

def _install_nodejs(version: str, dry_run: bool):
    Log.info("installing nodejs", [("version", version)])
    if dry_run:
        Log.info("skip installing nodejs", [("reason", "dry run")])
        return
    p = subprocess.Popen(["bash", "-c", "nvm", "install", "20"])
    _, _ = p.communicate()
    if p.returncode != 0:
        raise Exception('NVM failed to install nodejs')

class NodeJSProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        org = "nodejs"
        repo = "node"

        # Get latest node release
        #https://github.com/nodejs/node/releases/tag/v22.2.0
        latest_nvm_release = Github.get_latest_release(org, repo)

        # Download node tarball
        #wget https://nodejs.org/dist/v20.13.1/node-v20.13.1-linux-x64.tar.xz

        # Extract node tarball
        # mkdir node
        # mv node-v20.13.1-linux-x64.tar.xz node/
        # cd node
        # tar -xJf ./node-v20.13.1-linux-x64.tar.xz 

        # Move to install directory


    def provision_old(self) -> None:

        org = "nvm-sh"
        repo = "nvm"

        latest_nvm_release = Github.get_latest_release(org, repo)
        Log.info("latest nvm release", [("release", latest_nvm_release)])

        tmp_dir = os.path.join(Dir.tmp(), "nodejs")

        #Util.rmdir(tmp_dir)

        script_name = "install.sh"
        script_path = os.path.join(tmp_dir, script_name)

        url = f"https://raw.githubusercontent.com/nvm-sh/nvm/{latest_nvm_release}/{script_name}"

        #download_file(
            #url,
            #script_path,
            #False,
            #False,
            #self._args.dry_run,
        #)

        Shell.chmod("+x", script_path, False, self._args.dry_run)

        _uninstall_nvm(self._args.dry_run)
        _run_nvm_install_script(script_path, self._args.dry_run)

            # TODO: Get this version dynamically
        _install_nodejs("20", self._args.dry_run)

