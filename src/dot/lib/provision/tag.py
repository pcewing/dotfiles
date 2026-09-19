#!/usr/bin/env python

import os

from dot.lib.common.os import OperatingSystem


class Tag:
    def __init__(self, name: str) -> None:
        self.name = name


class Tags:
    x11 = Tag("x11")
    wsl = Tag("wsl")
    gaming = Tag("gaming")

    def __init__(self, tags: list[Tag]) -> None:
        self.tags = tags

    def has(self, tag: Tag) -> bool:
        return any(t.name == tag.name for t in self.tags)

    @staticmethod
    def default() -> "Tags":
        tags = []

        operating_system = OperatingSystem.get()

        if operating_system.is_wsl():
            tags.append(Tags.wsl)
        elif os.getenv("DISPLAY") or os.getenv("WAYLAND_DISPLAY"):
            tags.append(Tags.x11)

        return Tags(tags)

    @staticmethod
    def parse(tag_names: str) -> "Tags":
        names = [name.strip() for name in tag_names.split(",") if name.strip()]
        return Tags.from_names(names)

    @staticmethod
    def from_names(names: list[str]) -> "Tags":
        return Tags([Tag(name) for name in names])
