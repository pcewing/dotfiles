#!/usr/bin/env python

import json
import os
from typing import Optional

OS_RELEASE_FILE = "/etc/os-release"
LSB_RELEASE_FILE = "/etc/lsb-release"
CENTOS_RELEASE_FILE = "/etc/centos-release"


def _parse_kv_file(path: str) -> dict[str, str]:
    values: dict[str, str] = {}
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            value = value.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
                value = value[1:-1]
            values[key.strip()] = value
    return values


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
            "id":          self.id,
            "release":     self.release,
            "codename":    self.codename,
            "description": self.description,
        })
        # fmt: on

    @staticmethod
    def get() -> Optional["DistroInformation"]:
        if DistroInformation._data is None:
            DistroInformation._load_distro_info()
        return DistroInformation._data

    @staticmethod
    def _load_distro_info() -> None:
        if os.path.isfile(OS_RELEASE_FILE):
            DistroInformation._load_os_release_file()
        elif os.path.isfile(LSB_RELEASE_FILE):
            DistroInformation._load_lsb_release_file()
        elif os.path.isfile(CENTOS_RELEASE_FILE):
            raise Exception("CentOS is not supported")

    @staticmethod
    def _load_os_release_file() -> None:
        vars = _parse_kv_file(OS_RELEASE_FILE)

        # VERSION_CODENAME is the standard key; Ubuntu also sets
        # UBUNTU_CODENAME and some releases only populate that one.
        codename = vars.get("VERSION_CODENAME") or vars.get("UBUNTU_CODENAME") or ""

        DistroInformation._data = DistroInformation(
            vars.get("ID", ""),
            vars.get("VERSION_ID", ""),
            codename,
            vars.get("PRETTY_NAME", ""),
        )

    @staticmethod
    def _load_lsb_release_file() -> None:
        required = [
            "DISTRIB_ID",
            "DISTRIB_RELEASE",
            "DISTRIB_CODENAME",
            "DISTRIB_DESCRIPTION",
        ]

        vars = _parse_kv_file(LSB_RELEASE_FILE)

        if any(key not in vars for key in required):
            raise Exception("Failed to construct DistroInformation")

        DistroInformation._data = DistroInformation(
            vars["DISTRIB_ID"],
            vars["DISTRIB_RELEASE"],
            vars["DISTRIB_CODENAME"],
            vars["DISTRIB_DESCRIPTION"],
        )
