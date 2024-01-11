#!/usr/bin/env python

import os


LSB_RELEASE_FILE = "/etc/lsb-release"
CENTOS_RELEASE_FILE = "/etc/centos-release"

# This was moved from typing_extensions to typing in Python 3.11 but I'm still
# on 3.10
from typing_extensions import Self


class DistroInformation:
    _data = None

    def __init__(self, id, release, codename, description) -> None:
        self.id = id
        self.release = release
        self.codename = codename
        self.description = description

    def __str__(self) -> str:
        # fmt: off
        return json.dumps({
            "DISTRIB_ID": self.distrib_id,
            "DISTRIB_RELEASE": self.distrib_release,
            "DISTRIB_CODENAME": self.distrib_codename,
            "DISTRIB_DESCRIPTION": self.distrib_description,
        })
        # fmt: on

    @staticmethod
    def get() -> Self:
        if DistroInformation._data is None:
            DistroInformation._load_distro_info()
        return DistroInformation._data

    @staticmethod
    def _load_distro_info():
        if os.path.isfile(LSB_RELEASE_FILE):
            DistroInformation._load_lsb_release_file()
        elif os.path.isfile(CENTOS_RELEASE_FILE):
            raise Exception("CentOS is not supported")

    @staticmethod
    def _load_lsb_release_file():
        vars = {
            "DISTRIB_ID": None,
            "DISTRIB_RELEASE": None,
            "DISTRIB_CODENAME": None,
            "DISTRIB_DESCRIPTION": None,
        }

        with open("/etc/lsb-release", "r") as f:
            for line in f:
                (var, val) = line.strip().split("=")
                if var in vars:
                    vars[var] = val

        for var in vars:
            if vars[var] is None:
                raise Exception("Failed to construct DistroInformation")

        DistroInformation._data = DistroInformation(
            vars["DISTRIB_ID"],
            vars["DISTRIB_RELEASE"],
            vars["DISTRIB_CODENAME"],
            vars["DISTRIB_DESCRIPTION"],
        )
