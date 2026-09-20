#!/usr/bin/env python

import json
import os
import shutil
import stat
from enum import Enum
from typing import List  # , Self

from dot.lib.common.dir import Dir
from dot.lib.common.log import Log
from dot.lib.common.os import OperatingSystem

# from typing_extensions import Self


def _is_link(path: str) -> bool:
    """Return True when path itself is a symlink or a Windows junction.

    os.path.isdir() follows links, so a link to a directory would otherwise be
    treated as a real directory and have its target's contents deleted.
    """
    if os.path.islink(path):
        return True
    if not os.path.lexists(path):
        return False
    attributes = getattr(os.lstat(path), "st_file_attributes", 0)
    return bool(attributes & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0))


def _chmod_tree(path: str, mode: int) -> None:
    """Apply mode to path and everything beneath it, without following links."""
    if os.path.isdir(path) and not _is_link(path):
        for root, dirs, files in os.walk(path):
            for name in dirs + files:
                entry = os.path.join(root, name)
                if not _is_link(entry):
                    os.chmod(entry, mode)
    os.chmod(path, mode)


class LinkType(Enum):
    FILE = 1
    DIRECTORY = 2

    @staticmethod
    def parse(s: str) -> "LinkType":
        # fmt: off
        strings = {
            "file":         LinkType.FILE,
            "f":            LinkType.FILE,
            "directory":    LinkType.DIRECTORY,
            "dir":          LinkType.DIRECTORY,
            "d":            LinkType.DIRECTORY,
        }
        # fmt: on
        if s.lower() in strings:
            return strings[s.lower()]
        else:
            raise Exception(f"Failed to parse link type {s}")


class Link:
    def __init__(self, src: str, dst: str, link_type: LinkType = LinkType.FILE) -> None:
        self.src = src
        self.dst = dst
        self.link_type = link_type

    def is_file(self) -> bool:
        return self.link_type == LinkType.FILE

    def is_dir(self) -> bool:
        return self.link_type == LinkType.DIRECTORY

    def create(self) -> None:
        if OperatingSystem.get().is_windows():
            self._create_windows()
        else:
            self._create_linux()

    def _create_linux(self) -> None:
        dst_dir = os.path.dirname(self.dst)

        if not os.path.exists(dst_dir):
            Log.info(f"Creating parent directory for symlink at path {self.dst}")
            os.makedirs(dst_dir, exist_ok=True)

        if not os.path.isdir(dst_dir):
            raise Exception(
                f"Parent directory path for symlink {self.dst} exists but is not a directory"
            )

        if os.path.lexists(self.dst):
            if os.path.islink(self.dst):
                Log.info(f"Deleting existing symlink at path {self.dst}")
                os.remove(self.dst)
            elif os.path.isdir(self.dst):
                Log.warn(
                    f"Deleting existing directory which is NOT a symlink at path {self.dst}"
                )
                shutil.rmtree(self.dst)
            else:
                Log.warn(
                    f"Deleting existing file which is NOT a symlink at path {self.dst}"
                )
                os.remove(self.dst)

        Log.info(f"Creating symlink", {"source": self.src, "target": self.dst})
        os.symlink(self.src, self.dst)

    def _create_windows(self) -> None:
        dst_dir = os.path.dirname(self.dst)

        if not os.path.exists(dst_dir):
            Log.info(f"Creating parent directory for copy at path {self.dst}")
            os.makedirs(dst_dir, exist_ok=True)

        if not os.path.isdir(dst_dir):
            raise Exception(
                f"Parent directory path for copy {self.dst} exists but is not a directory"
            )

        if os.path.lexists(self.dst):
            self._delete_windows()

        if self.is_dir():
            Log.info("Copying directory", {"source": self.src, "target": self.dst})
            shutil.copytree(self.src, self.dst)
        else:
            Log.info("Copying file", {"source": self.src, "target": self.dst})
            shutil.copyfile(self.src, self.dst)

        _chmod_tree(self.dst, stat.S_IREAD)

    def delete(self) -> None:
        if OperatingSystem.get().is_windows():
            self._delete_windows()
        else:
            self._delete_linux()

    def _delete_linux(self) -> None:
        if not os.path.islink(self.dst):
            if os.path.exists(self.dst):
                Log.warn(f"File at path {self.dst} is not a symbolic link, skipping")
            else:
                Log.info(f"Symlink at path {self.dst} does not exist, skipping")
            return

        Log.info(f"Removing symlink at path {self.dst}")
        os.remove(self.dst)

    def _delete_windows(self) -> None:
        if not os.path.lexists(self.dst):
            Log.info(f"File at path {self.dst} does not exist, skipping")
            return

        if _is_link(self.dst):
            Log.info(f"Removing link at path {self.dst}")
            os.remove(self.dst)
        elif os.path.isdir(self.dst):
            Log.info(f"Removing directory at path {self.dst}")
            _chmod_tree(self.dst, stat.S_IWRITE)
            shutil.rmtree(self.dst)
        else:
            Log.info(f"Removing file at path {self.dst}")
            os.chmod(self.dst, stat.S_IWRITE)
            os.remove(self.dst)


class Links:
    _links = None

    @staticmethod
    def get() -> List[Link]:
        if Links._links is None:
            Links._initialize_links()
        return Links._links

    @staticmethod
    def _load_links_json():
        with open(os.path.join(Dir.dot(), "links.json"), "r") as f:
            return json.loads(f.read())

    @staticmethod
    def _platform() -> str:
        os_ = OperatingSystem.get()
        if os_.is_windows():
            return "windows"
        if os_.is_linux():
            return "linux"
        return os_.get_name()

    @staticmethod
    def _initialize_link(link_json) -> Link:
        return Link(
            os.path.join(Dir.config(), link_json["src"]),
            os.path.expandvars(link_json["dst"].replace("~", Dir.home())),
            LinkType.parse(link_json.get("type", "file")),
        )

    @staticmethod
    def _initialize_links():
        platform = Links._platform()
        Links._links = [
            Links._initialize_link(link)
            for link in Links._load_links_json()
            if platform in link.get("platforms", ["linux"])
        ]
