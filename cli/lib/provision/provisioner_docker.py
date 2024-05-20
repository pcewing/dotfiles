#!/usr/bin/env python

import os
import re
import urllib

from lib.common.apt import Apt
from lib.common.dir import Dir
from lib.common.distro_info import DistroInformation
from lib.common.group import Group
from lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs
from lib.common.semver import Semver
from lib.common.shell import Shell
from lib.common.util import download_file, get_current_user


class DockerPackage:
    def __init__(self, url, name, full_name, version):
        self.url = url
        self.name = name
        self.full_name = full_name
        self.version = version
        self.semver = Semver.parse(version)


class DockerProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        self._args = args

    def provision(self) -> None:
        distro_info = DistroInformation.get()

        base_url = f"https://download.docker.com/linux/ubuntu/dists/{distro_info.codename}/pool/stable/amd64"

        # TODO: Work in progress detecting latest available package versions
        # and comparing against installed versions
        installed_packages = Apt.get_installed_packages()
        latest_packages = DockerProvisioner._get_latest_package_versions(
            base_url, distro_info
        )
        for p in latest_packages:
            found = False
            for i in installed_packages:
                if i.name != p.name:
                    continue
                found = True
                print(f"{p.name}: {p.version} vs. {i.version}")
            if not found:
                raise Exception(f"{p.name} not installed")
        return

        # TODO: Automatically choose latest version
        packages = [
            "containerd.io_1.6.9-1_amd64.deb",
            f"docker-ce_24.0.7-1~ubuntu.22.04~{distro_info.codename}_amd64.deb",
            f"docker-ce-cli_24.0.7-1~ubuntu.22.04~{distro_info.codename}_amd64.deb",
            f"docker-buildx-plugin_0.11.2-1~ubuntu.22.04~{distro_info.codename}_amd64.deb",
            f"docker-compose-plugin_2.6.0~ubuntu-{distro_info.codename}_amd64.deb",
        ]

        # TODO: Make this a common directory like Dir.tmp()
        tmp_dir = os.path.join(Dir.home(), ".tmp")
        Shell.mkdir(tmp_dir, True, False, self._args.dry_run)

        for package in packages:
            download_file(
                f"{base_url}/{package}",
                os.path.join(tmp_dir, package),
                False,
                False,
                self._args.dry_run,
            )

        Apt.install_deb_files(packages, self._args.dry_run)

        Group.add_user("docker", get_current_user().pw_name, self._args.dry_run)

    @staticmethod
    def _get_latest_package_versions(
        base_url: str, distro_info: DistroInformation
    ) -> list[DockerPackage]:
        version_regex_pattern = "[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+){0,1}"
        package_regex_patterns = [
            f".*((containerd\.io)_({version_regex_pattern})_amd64.deb).*",
            f".*((docker-ce)_({version_regex_pattern})~ubuntu.{distro_info.release}~{distro_info.codename}_amd64.deb).*",
            f".*((docker-ce-cli)_({version_regex_pattern})~ubuntu.{distro_info.release}~{distro_info.codename}_amd64.deb).*",
            f".*((docker-buildx-plugin)_({version_regex_pattern})~ubuntu.{distro_info.release}~{distro_info.codename}_amd64.deb).*",
            f".*((docker-compose-plugin)_({version_regex_pattern})~ubuntu-{distro_info.codename}_amd64.deb).*",
        ]

        def match(line):
            for pattern in package_regex_patterns:
                m = re.match(pattern, line)
                if m is not None:
                    return m
            return None

        response = urllib.request.urlopen(base_url).read().decode("utf-8")

        available_packages = {}
        for line in response.split("\n"):
            m = match(line)
            if m is None:
                continue

            full_name = m.group(1)
            name = m.group(2)
            version = m.group(3)
            url = f"{base_url}/{full_name}"

            available_package = DockerPackage(url, name, full_name, version)

            if available_package.name not in available_packages:
                available_packages[available_package.name] = []
            available_packages[name].append(available_package)

        latest_packages = []
        for package in available_packages:
            sorted_packages = sorted(
                available_packages[package], key=lambda p: p.semver, reverse=True
            )
            latest_packages.append(sorted_packages[0])
        return latest_packages
