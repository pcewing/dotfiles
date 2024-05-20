#!/usr/bin/env python

import os

class OperatingSystem:
    def __init__(self, name: str):
        self._name = name

    def get_name(self) -> str:
        return self._name

    def is_windows(self) -> bool:
        return self._name == "windows"

    def is_linux(self) -> bool:
        return self._name == "linux"

    def is_wsl(self) -> bool:
        return os.getenv("WSL_DISTRO_NAME") is not None

    @staticmethod
    def get() -> "OperatingSystem":
        if os.name == "nt":
            return OperatingSystem("windows")
        elif os.name == "posix" and os.uname().sysname.lower() == "linux":
            return OperatingSystem("linux")
        else:
            raise Exception("Unsupported OS")
