#!/usr/bin/env python

import subprocess
import json

from typing import List

from ..common.log import Log

APT_LIST_TIMEOUT_SECONDS = 30


class PackageListing:
    def __init__(self, name, repositories, version, version_epoch, arch, attrs):
        self.name = name
        self.repositories = repositories
        self.version = version
        self.version_epoch = version_epoch
        self.arch = arch
        self.attrs = attrs

    def __str__(self) -> str:
        # fmt: off
        return json.dumps({
            "name":             self.name,
            "repositories":     self.repositories,
            "version":          self.version,
            "version_epoch":    self.version_epoch,
            "arch":             self.arch,
            "attrs":            self.attrs,
        }, indent="    ")
        # fmt: on

    @staticmethod
    def parse(line: str) -> "PackageListing":
        # Expected line format:
        # zlib1g-dev/jammy-updates,jammy-security,now 1:1.2.11.dfsg-2ubuntu9.2 amd64 [installed,automatic]
        i = line.find("/")
        if i == -1:
            raise Exception(f"Encountered invalid line '{line}'")

        package_name = line[:i]

        # Expected remaining line format:
        # jammy-updates,jammy-security,now 1:1.2.11.dfsg-2ubuntu9.2 amd64 [installed,automatic]
        line = line[i + 1 :]
        i = line.find(" ")
        if i == -1:
            raise Exception(f"Encountered invalid line '{line}'")
        package_repositories = line[:i].split(",")

        # Expected remaining line format:
        # 1:1.2.11.dfsg-2ubuntu9.2 amd64 [installed,automatic]
        line = line[i + 1 :]
        i = line.find(" ")
        if i == -1:
            raise Exception(f"Encountered invalid line '{line}'")
        package_version = line[:i]

        # Handle versions that have an epoch prefix
        package_version_epoch = None
        i = package_version.find(":")
        if i > -1:
            package_version_epoch = package_version[:i]
            package_version = package_version[i+1:]

        # Expected remaining line format:
        # 1:1.2.11.dfsg-2ubuntu9.2 amd64 [installed,automatic]
        line = line[i + 1 :]
        i = line.find(" ")
        if i == -1:
            raise Exception(f"Encountered invalid line '{line}'")
        package_version = line[:i]

        # Expected remaining line format:
        # amd64 [installed,automatic]
        line = line[i + 1 :]
        i = line.find(" ")
        if i == -1:
            raise Exception(f"Encountered invalid line '{line}'")
        package_arch = line[:i]

        # Expected remaining line format:
        # [installed,automatic]
        line = line[i + 1 :]
        if line[0] != "[" and line[len(line) - 1] != "]":
            raise Exception(f"Encountered invalid line '{line}'")
        package_attrs = line[1 : len(line) - 1].split(",")

        return PackageListing(
            package_name,
            package_repositories,
            package_version,
            package_version_epoch,
            package_arch,
            package_attrs,
        )


class Apt:
    @staticmethod
    def update(dry_run: bool) -> None:
        Log.info("Updating APT repository")
        if dry_run:
            Log.info("Skipping apt update due to --dry-run")
        else:
            if subprocess.call(["sudo", "apt", "-y", "update"]) != 0:
                raise Exception("Apt update failed")

    @staticmethod
    def upgrade(dry_run: bool) -> None:
        Log.info("Upgrading APT packages")
        if dry_run:
            Log.info("Skipping apt upgrade due to --dry-run")
        else:
            if subprocess.call(["sudo", "apt", "-y", "upgrade"]) != 0:
                raise Exception("Apt upgrade failed")

    @staticmethod
    def install(packages: List[str], dry_run: bool) -> None:
        Log.info("Installing APT packages")
        if dry_run:
            Log.info("Skipping apt install due to --dry-run")
        else:
            if subprocess.call(["sudo", "apt", "-y", "install"] + packages) != 0:
                raise Exception("Apt install failed")

    @staticmethod
    def install_deb_files(deb_files: List[str], dry_run: bool) -> None:
        cmd = ["sudo", "dpkg", "-i"] + deb_files

        Log.info("installing packages", [("packages", "[ " + ", ".join(deb_files) + " ]")])
        if dry_run:
            Log.info("skipping install", [("reason", "dry run")])
        else:
            if subprocess.call(cmd) != 0:
                raise Exception("Failed to install packages")

    @staticmethod
    def get_installed_packages() -> List[PackageListing]:
        return Apt._list(["--installed"])

    @staticmethod
    def _list(args: List[str]) -> List[PackageListing]:
        p = subprocess.Popen(
            ["apt", "list"] + args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        stdout, stderr = p.communicate(timeout=APT_LIST_TIMEOUT_SECONDS)
        if p.returncode != 0:
            Log.info(stdout)
            Log.info(stderr)
            raise Exception(f"apt returned non-zero exit code {p.returncode}")

        package_listings = []
        for line in stdout.split("\n"):
            if line.strip() == "Listing...":
                continue
            elif line.strip() == "":
                continue
            package_listings.append(PackageListing.parse(line))
        return package_listings
