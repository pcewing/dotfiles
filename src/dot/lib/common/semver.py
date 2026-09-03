#!/usr/bin/env python

import re
from typing import Union


class Semver:
    def __init__(self, major, minor, patch):
        self.major = major
        self.minor = minor
        self.patch = patch

    def __str__(self):
        return f"v{self.major}.{self.minor}.{self.patch}"

    def __lt__(self, rhs):
        if self.major != rhs.major:
            return self.major < rhs.major
        elif self.minor != rhs.minor:
            return self.minor < rhs.minor
        else:
            return self.patch < rhs.patch

    def __le__(self, rhs):
        if self.major != rhs.major:
            return self.major < rhs.major
        elif self.minor != rhs.minor:
            return self.minor < rhs.minor
        elif self.patch != rhs.patch:
            return self.patch < rhs.patch
        else:
            return True

    def __gt__(self, rhs):
        if self.major != rhs.major:
            return self.major > rhs.major
        elif self.minor != rhs.minor:
            return self.minor > rhs.minor
        else:
            return self.patch > rhs.patch

    def __ge__(self, rhs):
        if self.major != rhs.major:
            return self.major > rhs.major
        elif self.minor != rhs.minor:
            return self.minor > rhs.minor
        elif self.patch != rhs.patch:
            return self.patch > rhs.patch
        else:
            return True

    def __eq__(self, rhs):
        return (
            self.major == rhs.major
            and self.minor == rhs.minor
            and self.patch == rhs.patch
        )

    def __ne__(self, rhs):
        return (
            self.major != rhs.major
            or self.minor != rhs.minor
            or self.patch != rhs.patch
        )

    @staticmethod
    def parse(version_str: str) -> Union["Semver", None]:
        m = re.match("v{0,1}([0-9]+)\.([0-9]+)(\.([0-9]+)){0,1}", version_str)
        if m is None:
            return None
        major = int(m.group(1))
        minor = int(m.group(2))
        patch = int(m.group(4)) if m.group(4) is not None else 0
        return Semver(major, minor, patch)
