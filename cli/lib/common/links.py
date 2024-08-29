#!/usr/bin/env python

import json
import os
from enum import Enum
from typing import List  # , Self

from lib.common.dir import Dir
from lib.common.log import Log

# from typing_extensions import Self


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
        dst_dir = os.path.dirname(self.dst)

        if not os.path.exists(dst_dir):
            Log.info(f"Creating parent directory for symlink at path {self.dst}")
            os.makedirs(dst_dir, exist_ok=True)

        if not os.path.isdir(dst_dir):
            raise Exception(
                f"Parent directory path for symlink {self.dst} exists but is not a directory"
            )

        if os.path.exists(self.dst):
            if os.path.islink(self.dst):
                Log.info(f"Deleting existing symlink at path {self.dst}")
            else:
                Log.warn(
                    f"Deleting existing file which is NOT a symlink at path {self.dst}"
                )
            os.remove(self.dst)

        Log.info(f"Creating symlink", {"source": self.src, "target": self.dst})
        os.symlink(self.src, self.dst)

    def delete(self) -> None:
        if not os.path.islink(self.dst):
            if os.path.exists(self.dst):
                Log.warn(f"File at path {self.dst} is not a symbolic link, skipping")
            else:
                Log.info(f"Symlink at path {self.dst} does not exist, skipping")
            return

        Log.info(f"Removing symlink at path {self.dst}")
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
    def _initialize_link(link_json) -> Link:
        return Link(
            os.path.join(Dir.config(), link_json["src"]),
            os.path.expandvars(link_json["dst"].replace("~", Dir.home())),
            LinkType.parse(link_json.get("type", "file")),
        )

    @staticmethod
    def _initialize_links():
        Links._links = [
            Links._initialize_link(link) for link in Links._load_links_json()
        ]
