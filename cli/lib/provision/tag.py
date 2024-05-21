#!/usr/bin/env python

from lib.common.os import OperatingSystem


class Tag:
    def __init__(self, name: str) -> None:
        self.name = name


class Tags:
    x11 = Tag("x11")
    wsl = Tag("wsl")

    def __init__(self, tags: list[Tag]) -> None:
        self.tags = tags

    def has(self, tag: Tag) -> bool:
        return any(t.name == tag.name for t in self.tags)

    @staticmethod
    def default() -> "Tags":
        tags = []

        os = OperatingSystem.get()

        if os.is_wsl():
            tags.append(Tags.wsl)

        # TODO: Detect X11
        if not os.is_wsl():
            tags.append(Tags.x11)

        return Tags(tags)

    @staticmethod
    def parse(tag_names: str) -> "Tags":
        return Tags([Tag(tag_name) for tag_name in tag_names.split(",")])
