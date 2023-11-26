#!/usr/bin/env python

import os
import subprocess
import urllib.request


def download_file(url, dst):
    urllib.request.urlretrieve(url, dst)


def mkdir_p(path):
    os.makedirs(path, exist_ok=True)


class DistroInformation:
    def __init__(self):
        self.distrib_id = None
        self.distrib_release = None
        self.distrib_codename = None
        self.distrib_description = None

        with open("/etc/lsb-release", "r") as f:
            for line in f:
                (var, val) = line.strip().split("=")
                if var == "DISTRIB_ID":
                    self.distrib_id = val
                elif var == "DISTRIB_RELEASE":
                    self.distrib_release = val
                elif var == "DISTRIB_CODENAME":
                    self.distrib_codename = val
                elif var == "DISTRIB_DESCRIPTION":
                    self.distrib_description = val

        if (
            self.distrib_id is None
            or self.distrib_release is None
            or self.distrib_codename is None
            or self.distrib_description is None
        ):
            raise Exception("Failed to construct DistroInformation")

    def __str__(self):
        return f"DISTRIB_ID = {self.distrib_id}, DISTRIB_RELEASE = {self.distrib_release}, DISTRIB_CODENAME = {self.distrib_codename}, DISTRIB_DESCRIPTION = {self.distrib_description}"


def install_docker():
    distro_info = DistroInformation()
    print(distro_info)

    base_url = f"https://download.docker.com/linux/ubuntu/dists/{distro_info.distrib_codename}/pool/stable/amd64"
    print(base_url)

    # TODO: Automatically choose latest version
    packages = [
        "containerd.io_1.6.9-1_amd64.deb",
        "docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb",
        "docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb",
        "docker-buildx-plugin_0.11.2-1~ubuntu.22.04~jammy_amd64.deb",
        "docker-compose-plugin_2.6.0~ubuntu-jammy_amd64.deb",
    ]

    tmp_dir = os.path.join(os.getenv("HOME"), ".tmp")
    mkdir_p(tmp_dir)

    for package in packages:
        print(f"Downloading {package}")
        download_file(f"{base_url}/{package}", os.path.join(tmp_dir, package))

    cmd = ["sudo", "dpkg", "-i"] + [os.path.join(tmp_dir, pkg) for pkg in packages]

    print("Installing packages:\n{}\n".format(" ".join(cmd)))
    subprocess.call(cmd)


def main():
    install_docker()


if __name__ == "__main__":
    main()
