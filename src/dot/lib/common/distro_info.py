#!/usr/bin/env python

import json
import os
from typing import Optional

LSB_RELEASE_FILE = "/etc/lsb-release"
CENTOS_RELEASE_FILE = "/etc/centos-release"


class DistroInformation:
    _data = None

    def __init__(self, id: str, release: str, codename: str, description: str) -> None:
        self.id = id
        self.release = release
        self.codename = codename
        self.description = description

    def __str__(self) -> str:
        # fmt: off
        return json.dumps({
            "DISTRIB_ID": self.id,
            "DISTRIB_RELEASE": self.release,
            "DISTRIB_CODENAME": self.codename,
            "DISTRIB_DESCRIPTION": self.description,
        })
        # fmt: on

    @staticmethod
    def get() -> Optional["DistroInformation"]:
        if DistroInformation._data is None:
            DistroInformation._load_distro_info()
        return DistroInformation._data

    @staticmethod
    def _load_distro_info() -> None:
        if os.path.isfile(LSB_RELEASE_FILE):
            DistroInformation._load_lsb_release_file()
        elif os.path.isfile(CENTOS_RELEASE_FILE):
            raise Exception("CentOS is not supported")

    @staticmethod
    def _load_lsb_release_file() -> None:
        required = set(
            [
                "DISTRIB_ID",
                "DISTRIB_RELEASE",
                "DISTRIB_CODENAME",
                "DISTRIB_DESCRIPTION",
            ]
        )

        # TODO: Use `/etc/os-release` instead which is a more common standard
        vars: dict[str, str] = {}
        with open("/etc/lsb-release", "r") as f:
            for line in f:
                (key, val) = line.strip().split("=")
                if key in required:
                    vars[key] = val

        if len(vars) != len(required):
            raise Exception("Failed to construct DistroInformation")

        DistroInformation._data = DistroInformation(
            vars["DISTRIB_ID"],
            vars["DISTRIB_RELEASE"],
            vars["DISTRIB_CODENAME"],
            vars["DISTRIB_DESCRIPTION"],
        )
